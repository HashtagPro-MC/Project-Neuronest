import Foundation
import CoreBluetooth
import Combine

@MainActor
final class BLESerialManager: NSObject, ObservableObject {
    // MARK: - Published
    @Published var status: String = "Idle"
    @Published var isConnected: Bool = false
    @Published var log: String = ""
    @Published var isScanning: Bool = false

    // MARK: - CoreBluetooth
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?

    // Your Service UUID
    private let serviceUUID = CBUUID(string: "6F1A9B40-8C4E-4E48-9B2C-5D5D3B6F0A10")

    // Chars discovered
    private var notifyChar: CBCharacteristic?
    private var writeChar: CBCharacteristic?

    // Buffer (optional line parsing)
    private var buffer = Data()

    // Optional: match by device name (edit to your ESP32 local name)
    private let preferredNameKeywords: [String] = ["ESP32", "Neuronest"]

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public API

    func startScan() {
        guard central.state == .poweredOn else {
            status = "Bluetooth not ready"
            return
        }
        isScanning = true
        status = "Scanning..."
        log = ""
        notifyChar = nil
        writeChar = nil
        buffer.removeAll(keepingCapacity: true)

        // ✅ IMPORTANT FIX:
        // Scan for ALL peripherals (nil). Some ESP32 setups do NOT advertise the service UUID.
        central.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }

    func disconnect() {
        if let p = peripheral {
            central.cancelPeripheralConnection(p)
        }
        isScanning = false
    }

    /// Phone -> ESP write (optional)
    func send(_ text: String) {
        guard let p = peripheral, let w = writeChar else {
            append("⚠️ No write characteristic")
            return
        }
        let data = Data(text.utf8)

        // Choose write type based on supported properties
        let type: CBCharacteristicWriteType = w.properties.contains(.write) ? .withResponse : .withoutResponse
        p.writeValue(data, for: w, type: type)
        append("➡️ \(text.trimmingCharacters(in: .newlines))")
    }

    // MARK: - Logging

    private func append(_ line: String) {
        log += (log.isEmpty ? "" : "\n") + line
    }

    // ✅ IMPORTANT FIX:
    // Print incoming data immediately (even if no newline)
    private func handleIncoming(_ data: Data) {
        if let s = String(data: data, encoding: .utf8) {
            append("⬅️ \(s)")
        } else {
            append("⬅️ (binary \(data.count) bytes)")
        }

        // Optional: keep newline parsing too (useful if ESP sends \n)
        buffer.append(data)
        while let range = buffer.firstRange(of: Data([0x0A])) { // \n
            let lineData = buffer.subdata(in: buffer.startIndex..<range.startIndex)
            buffer.removeSubrange(buffer.startIndex..<range.endIndex)

            if let line = String(data: lineData, encoding: .utf8) {
                append("⬅️ [line] \(line)")
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate, CBPeripheralDelegate
extension BLESerialManager: CBCentralManagerDelegate, CBPeripheralDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        status = (central.state == .poweredOn) ? "Bluetooth ready" : "Bluetooth not available"
        if central.state != .poweredOn {
            isScanning = false
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        // Names can be in peripheral.name or advertisement local name
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = peripheral.name ?? advName ?? "Unknown"
        append("👀 Found: \(name) RSSI:\(RSSI)")

        // ✅ Filter to your device to avoid connecting to random BLE stuff
        let matches = preferredNameKeywords.contains(where: { name.localizedCaseInsensitiveContains($0) })
        guard matches else { return }

        // Connect immediately
        self.peripheral = peripheral
        status = "Connecting..."
        central.stopScan()
        isScanning = false
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        isConnected = true
        status = "Connected. Discovering services..."
        peripheral.delegate = self

        // We can discover all services, then filter
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        isScanning = false
        status = "Connect failed: \(error?.localizedDescription ?? "unknown")"
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        notifyChar = nil
        writeChar = nil
        self.peripheral = nil
        isScanning = false
        status = "Disconnected"
        if let error {
            append("⚠️ Disconnected error: \(error.localizedDescription)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            status = "Service error: \(error.localizedDescription)"
            return
        }
        guard let services = peripheral.services else {
            status = "No services"
            return
        }

        // Find your service, otherwise still allow discovering chars on all services (debug)
        if let target = services.first(where: { $0.uuid == serviceUUID }) {
            status = "Discovering characteristics..."
            peripheral.discoverCharacteristics(nil, for: target)
        } else {
            status = "Service not found (debug: listing all services)"
            for s in services {
                append("🧩 Service: \(s.uuid.uuidString)")
                peripheral.discoverCharacteristics(nil, for: s)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error {
            status = "Char error: \(error.localizedDescription)"
            return
        }
        guard let chars = service.characteristics else { return }

        append("🧷 Chars for service \(service.uuid.uuidString):")
        for c in chars {
            append("   • \(c.uuid.uuidString) props=\(c.properties)")
        }

        // Pick notify + write chars
        for c in chars {
            if notifyChar == nil, (c.properties.contains(.notify) || c.properties.contains(.indicate)) {
                notifyChar = c
                peripheral.setNotifyValue(true, for: c)
                status = "Subscribing (notify)..."
            }
            if writeChar == nil, (c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse)) {
                writeChar = c
            }
        }

        if notifyChar == nil {
            status = "No notify characteristic found ❌"
        } else if writeChar == nil {
            // It's okay if you only need receive
            append("ℹ️ No write characteristic (receive-only)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error {
            status = "Notify failed: \(error.localizedDescription)"
            return
        }
        append("🔔 Notify ON for \(characteristic.uuid.uuidString)")
        status = "Subscribed (notify) ✅"
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error {
            append("❌ Update error: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else { return }
        handleIncoming(data)
    }
}
