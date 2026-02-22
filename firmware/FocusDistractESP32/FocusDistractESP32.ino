#include <Wire.h>
#include <math.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <MAX30105.h>
#include "heartRate.h"

#ifdef ESP32
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#endif

// ======================================================
// Hardware Pins
// ======================================================
static const int MOTOR_PIN = 25; // PWM-capable pin

// ======================================================
// Sensors
// ======================================================
MAX30105 max30102;
Adafruit_MPU6050 mpu;

// ======================================================
// Timing
// ======================================================
const uint32_t SAMPLE_INTERVAL_MS = 40;          // 25Hz
const uint32_t WINDOW_SIZE = 75;                 // 3 sec / 40ms
const uint32_t BASELINE_TIME_MS = 120000;        // 2 min
const uint32_t MOTOR_COOLDOWN_MS = 8000;         // avoid continuous vibration
const uint8_t DISTRACTED_STREAK_THRESHOLD = 2;   // debounce windows

uint32_t startTimeMs = 0;
uint32_t lastSampleMs = 0;
uint32_t lastMotorMs = 0;

// ======================================================
// Buffers
// ======================================================
float motionBuffer[WINDOW_SIZE];
float bpmBuffer[WINDOW_SIZE];
float jerkBuffer[WINDOW_SIZE];
uint16_t bufferIndex = 0;

// ======================================================
// HR Tracking
// ======================================================
float beatAvg = 72.0f; // safer initial fallback
uint32_t lastBeatMs = 0;
const uint8_t RR_SIZE = 10;
float rrIntervals[RR_SIZE];
uint8_t rrIndex = 0;
uint8_t rrCount = 0;

// ======================================================
// Baseline tracking (online update)
// ======================================================
uint16_t baselineWindows = 0;
float base_motion_mean = 0.0f;
float base_motion_var = 1.0f;
float base_bpm_mean = 0.0f;
float base_bpm_var = 1.0f;
float base_rmssd_mean = 0.0f;
float base_rmssd_var = 1.0f;
float base_jerk_mean = 0.0f;
float base_jerk_var = 1.0f;

// ======================================================
// State
// ======================================================
enum FocusState : uint8_t {
  STATE_FOCUSED = 0,
  STATE_DISTRACTED = 1,
  STATE_NO_FINGER = 2
};

FocusState currentState = STATE_FOCUSED;
uint8_t distractedStreak = 0;

// ======================================================
// BLE
// ======================================================
#ifdef ESP32
BLECharacteristic* txCharacteristic = nullptr;
bool bleConnected = false;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    (void)pServer;
    bleConnected = true;
  }
  void onDisconnect(BLEServer* pServer) override {
    (void)pServer;
    bleConnected = false;
    BLEDevice::startAdvertising();
  }
};
#endif

// ======================================================
// Utility
// ======================================================
float computeMean(const float* arr, int size) {
  if (size <= 0) return 0.0f;
  float sum = 0.0f;
  for (int i = 0; i < size; i++) sum += arr[i];
  return sum / size;
}

float computeVariance(const float* arr, int size, float mean) {
  if (size <= 0) return 0.0f;
  float sum = 0.0f;
  for (int i = 0; i < size; i++) {
    float d = arr[i] - mean;
    sum += d * d;
  }
  return sum / size;
}

float computeRMSSD() {
  if (rrCount < 3) return 0.0f;

  float sumSq = 0.0f;
  int count = 0;
  for (uint8_t i = 1; i < rrCount; i++) {
    float diff = rrIntervals[i] - rrIntervals[i - 1];
    sumSq += diff * diff;
    count++;
  }
  if (count == 0) return 0.0f;
  return sqrtf(sumSq / count);
}

float safeStdFromVar(float variance) {
  if (variance < 1e-6f) return 1e-3f;
  return sqrtf(variance);
}

float computeZ(float value, float mean, float variance) {
  float stddev = safeStdFromVar(variance);
  return (value - mean) / stddev;
}

void updateOnlineMeanVar(float x, float& mean, float& var, uint16_t n) {
  if (n == 1) {
    mean = x;
    var = 1e-3f;
    return;
  }

  float prevMean = mean;
  mean = prevMean + (x - prevMean) / n;
  float prevVar = var;
  var = ((n - 2) * prevVar + (x - prevMean) * (x - mean)) / (n - 1);
  if (var < 1e-6f) var = 1e-6f;
}

void vibratePattern() {
  uint32_t now = millis();
  if (now - lastMotorMs < MOTOR_COOLDOWN_MS) return;

  lastMotorMs = now;

  analogWrite(MOTOR_PIN, 200);
  delay(150);
  analogWrite(MOTOR_PIN, 0);
  delay(100);
  analogWrite(MOTOR_PIN, 200);
  delay(150);
  analogWrite(MOTOR_PIN, 0);
}

void sendPayload(FocusState state,
                 float distractScore,
                 float motionZ,
                 float bpmZ,
                 float rmssdZ,
                 float jerkZ) {
  char payload[180];
  snprintf(payload, sizeof(payload),
           "{\"ts\":%lu,\"state\":%u,\"score\":%.3f,\"motion_z\":%.3f,\"bpm_z\":%.3f,\"rmssd_z\":%.3f,\"jerk_z\":%.3f}",
           millis(),
           static_cast<unsigned>(state),
           distractScore,
           motionZ,
           bpmZ,
           rmssdZ,
           jerkZ);

  Serial.println(payload);

#ifdef ESP32
  if (bleConnected && txCharacteristic != nullptr) {
    txCharacteristic->setValue((uint8_t*)payload, strlen(payload));
    txCharacteristic->notify();
  }
#endif
}

void setupBLE() {
#ifdef ESP32
  BLEDevice::init("Neuronest-ESP32");
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService* service = server->createService("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  txCharacteristic = service->createCharacteristic(
      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E",
      BLECharacteristic::PROPERTY_NOTIFY);
  txCharacteristic->addDescriptor(new BLE2902());

  service->start();
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(service->getUUID());
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
#endif
}

// ======================================================
// Setup
// ======================================================
void setup() {
  Serial.begin(115200);
  delay(300);

  pinMode(MOTOR_PIN, OUTPUT);
  analogWrite(MOTOR_PIN, 0);

  Wire.begin();

  if (!max30102.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("ERROR: MAX30102 init failed. Check wiring/power.");
    while (true) delay(1000);
  }
  max30102.setup();
  max30102.setPulseAmplitudeRed(0x0A);
  max30102.setPulseAmplitudeGreen(0x00);

  if (!mpu.begin()) {
    Serial.println("ERROR: MPU6050 init failed. Check wiring/power.");
    while (true) delay(1000);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);

  setupBLE();

  startTimeMs = millis();
  lastSampleMs = startTimeMs;

  Serial.println("Neuronest Focus/Distraction classifier started.");
  Serial.println("JSON payload stream begins after baseline period.");
}

// ======================================================
// Loop
// ======================================================
void loop() {
  uint32_t now = millis();
  if (now - lastSampleMs < SAMPLE_INTERVAL_MS) return;
  lastSampleMs = now;

  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);

  float ax = accel.acceleration.x / 9.80665f;
  float ay = accel.acceleration.y / 9.80665f;
  float az = accel.acceleration.z / 9.80665f;
  float mag = sqrtf(ax * ax + ay * ay + az * az);

  static float lastMag = 1.0f;
  float motion = fabsf(mag - 1.0f);
  float jerk = fabsf(mag - lastMag);
  lastMag = mag;

  long irValue = max30102.getIR();
  bool fingerPresent = (irValue > 50000);

  if (fingerPresent && checkForBeat(irValue)) {
    uint32_t beatNow = millis();
    uint32_t delta = beatNow - lastBeatMs;
    lastBeatMs = beatNow;

    if (delta > 300 && delta < 2000) {
      float bpm = 60.0f / (delta / 1000.0f);
      beatAvg = 0.9f * beatAvg + 0.1f * bpm;

      if (rrCount < RR_SIZE) {
        rrIntervals[rrCount++] = delta / 1000.0f;
      } else {
        for (uint8_t i = 1; i < RR_SIZE; i++) rrIntervals[i - 1] = rrIntervals[i];
        rrIntervals[RR_SIZE - 1] = delta / 1000.0f;
      }
      rrIndex = (rrIndex + 1) % RR_SIZE;
    }
  }

  motionBuffer[bufferIndex] = motion;
  bpmBuffer[bufferIndex] = beatAvg;
  jerkBuffer[bufferIndex] = jerk;
  bufferIndex++;

  if (bufferIndex < WINDOW_SIZE) return;

  float motionMean = computeMean(motionBuffer, WINDOW_SIZE);
  float motionVar = computeVariance(motionBuffer, WINDOW_SIZE, motionMean);
  float bpmMean = computeMean(bpmBuffer, WINDOW_SIZE);
  float bpmVar = computeVariance(bpmBuffer, WINDOW_SIZE, bpmMean);
  float rmssd = computeRMSSD();
  float jerkMean = computeMean(jerkBuffer, WINDOW_SIZE);

  bufferIndex = 0;

  if (now - startTimeMs < BASELINE_TIME_MS) {
    baselineWindows++;
    updateOnlineMeanVar(motionMean, base_motion_mean, base_motion_var, baselineWindows);
    updateOnlineMeanVar(bpmMean, base_bpm_mean, base_bpm_var, baselineWindows);
    updateOnlineMeanVar(rmssd, base_rmssd_mean, base_rmssd_var, baselineWindows);
    updateOnlineMeanVar(jerkMean, base_jerk_mean, base_jerk_var, baselineWindows);

    sendPayload(STATE_FOCUSED, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
    return;
  }

  if (!fingerPresent) {
    currentState = STATE_NO_FINGER;
    distractedStreak = 0;
    sendPayload(currentState, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
    return;
  }

  float motionZ = computeZ(motionMean, base_motion_mean, base_motion_var);
  float bpmZ = computeZ(bpmMean, base_bpm_mean, base_bpm_var);
  float rmssdZ = computeZ(rmssd, base_rmssd_mean, base_rmssd_var);
  float jerkZ = computeZ(jerkMean, base_jerk_mean, base_jerk_var);

  // Rule-based distract score (initial MVP)
  float distractScore = 0.0f;
  distractScore += 0.40f * fmaxf(0.0f, motionZ);
  distractScore += 0.30f * fmaxf(0.0f, jerkZ);
  distractScore += 0.20f * fmaxf(0.0f, bpmZ);
  distractScore += 0.10f * fmaxf(0.0f, -rmssdZ);

  bool distractedWindow = (distractScore > 0.9f) || ((motionZ > 1.2f) && (jerkZ > 1.0f));

  if (distractedWindow) {
    if (distractedStreak < 255) distractedStreak++;
  } else {
    distractedStreak = 0;
  }

  if (distractedStreak >= DISTRACTED_STREAK_THRESHOLD) {
    currentState = STATE_DISTRACTED;
    vibratePattern();
  } else {
    currentState = STATE_FOCUSED;
  }

  sendPayload(currentState, distractScore, motionZ, bpmZ, rmssdZ, jerkZ);
}
