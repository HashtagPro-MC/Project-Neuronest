#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <MAX30105.h>
#include "heartRate.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ====== Pin configuration ======
static const int kMotorPin = 25; // Coin motor driver pin (use transistor + diode)

// ====== MAX30102 configuration ======
MAX30105 g_max30102;

// ====== MPU6050 configuration ======
Adafruit_MPU6050 g_mpu;

// ====== BLE configuration ======
static const char* kBleDeviceName = "Neuronest-ESP32";
static const char* kServiceUuid = "6f2f3c2a-1f3c-4f4f-9b2b-9f5e55c9c0a1";
static const char* kDataCharUuid = "b6f2c1e3-1d72-4f1b-9f5f-3f7b7f1c9b21";

BLECharacteristic* g_dataCharacteristic = nullptr;

// ====== Focus logic configuration ======
static const float kMotionThresholdG = 0.08f; // Lower means stricter stillness
static const float kMinBpm = 55.0f;
static const float kMaxBpm = 110.0f;
static const float kFocusScoreThreshold = 0.6f; // 0.0~1.0

// ====== Sample tracking ======
static const uint32_t kSampleIntervalMs = 50;
static const uint32_t kPublishIntervalMs = 1000;
static const uint8_t kMotionWindow = 20;

float g_motionWindow[kMotionWindow];
uint8_t g_motionIndex = 0;

float g_bpm = 0.0f;
float g_beatAvg = 0.0f;
uint32_t g_lastBeat = 0;

uint32_t g_lastSampleMs = 0;
uint32_t g_lastPublishMs = 0;

void setupMax30102() {
  if (!g_max30102.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring.");
    while (true) {
      delay(500);
    }
  }

  g_max30102.setup();
  g_max30102.setPulseAmplitudeRed(0x1F); // Red LED
  g_max30102.setPulseAmplitudeIR(0x1F);  // IR LED
  g_max30102.setPulseAmplitudeGreen(0);  // No green
}

void setupMpu6050() {
  if (!g_mpu.begin()) {
    Serial.println("MPU6050 not found. Check wiring.");
    while (true) {
      delay(500);
    }
  }
  g_mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  g_mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  g_mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
}

void setupBle() {
  BLEDevice::init(kBleDeviceName);
  BLEServer* server = BLEDevice::createServer();
  BLEService* service = server->createService(kServiceUuid);

  g_dataCharacteristic = service->createCharacteristic(
      kDataCharUuid,
      BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  g_dataCharacteristic->addDescriptor(new BLE2902());

  service->start();
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(kServiceUuid);
  advertising->setScanResponse(false);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
}

float computeMotionG() {
  sensors_event_t accel;
  sensors_event_t gyro;
  sensors_event_t temp;
  g_mpu.getEvent(&accel, &gyro, &temp);

  float ax = accel.acceleration.x / 9.80665f;
  float ay = accel.acceleration.y / 9.80665f;
  float az = accel.acceleration.z / 9.80665f;
  float magnitude = sqrtf(ax * ax + ay * ay + az * az);
  float motion = fabsf(magnitude - 1.0f); // remove gravity
  return motion;
}

void updateMotionWindow(float motionG) {
  g_motionWindow[g_motionIndex] = motionG;
  g_motionIndex = (g_motionIndex + 1) % kMotionWindow;
}

float averageMotion() {
  float sum = 0.0f;
  for (uint8_t i = 0; i < kMotionWindow; i++) {
    sum += g_motionWindow[i];
  }
  return sum / static_cast<float>(kMotionWindow);
}

void updateHeartRate() {
  long irValue = g_max30102.getIR();
  if (checkForBeat(irValue)) {
    uint32_t delta = millis() - g_lastBeat;
    g_lastBeat = millis();
    if (delta > 0) {
      g_bpm = 60.0f / (delta / 1000.0f);
      if (g_bpm < 255 && g_bpm > 20) {
        g_beatAvg = 0.9f * g_beatAvg + 0.1f * g_bpm;
      }
    }
  }
}

float computeFocusScore(float motionAvg, float bpmAvg) {
  float motionScore = 1.0f - min(motionAvg / kMotionThresholdG, 1.0f);
  float bpmScore = 0.0f;
  if (bpmAvg >= kMinBpm && bpmAvg <= kMaxBpm) {
    float center = (kMinBpm + kMaxBpm) * 0.5f;
    float span = (kMaxBpm - kMinBpm) * 0.5f;
    bpmScore = 1.0f - min(fabsf(bpmAvg - center) / span, 1.0f);
  }
  return 0.6f * motionScore + 0.4f * bpmScore;
}

void setMotor(bool on) {
  digitalWrite(kMotorPin, on ? HIGH : LOW);
}

void publishBle(float motionAvg, float bpmAvg, float focusScore, bool focused) {
  if (!g_dataCharacteristic) {
    return;
  }

  char payload[200];
  snprintf(payload, sizeof(payload),
           "{\"motion_g\":%.4f,\"bpm\":%.2f,\"focus_score\":%.2f,\"focused\":%s}",
           motionAvg, bpmAvg, focusScore, focused ? "true" : "false");
  g_dataCharacteristic->setValue(reinterpret_cast<uint8_t*>(payload), strlen(payload));
  g_dataCharacteristic->notify();
}

void setup() {
  Serial.begin(115200);
  pinMode(kMotorPin, OUTPUT);
  setMotor(false);

  Wire.begin();
  setupMax30102();
  setupMpu6050();
  setupBle();

  for (uint8_t i = 0; i < kMotionWindow; i++) {
    g_motionWindow[i] = 0.0f;
  }
}

void loop() {
  uint32_t now = millis();
  if (now - g_lastSampleMs >= kSampleIntervalMs) {
    g_lastSampleMs = now;

    updateHeartRate();
    float motion = computeMotionG();
    updateMotionWindow(motion);
  }

  if (now - g_lastPublishMs >= kPublishIntervalMs) {
    g_lastPublishMs = now;

    float motionAvg = averageMotion();
    float bpmAvg = g_beatAvg;
    float focusScore = computeFocusScore(motionAvg, bpmAvg);
    bool focused = focusScore >= kFocusScoreThreshold;

    setMotor(!focused);
    publishBle(motionAvg, bpmAvg, focusScore, focused);

    Serial.printf("motion=%.4f bpm=%.2f score=%.2f focused=%d\n",
                  motionAvg, bpmAvg, focusScore, focused ? 1 : 0);
  }
}
