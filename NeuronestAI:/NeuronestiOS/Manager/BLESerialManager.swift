import Foundation
import CoreBluetooth
import Combine

@MainActor
final class BLESerialManager: NSObject, ObservableObject {
    @Published var status: String = "Idle"
    @Published var isConnected: Bool = false
    @Published var log: String = ""
    @Published var isScanning: Bool = false

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?

    // 너가 준 Service UUID
    private let serviceUUID = CBUUID(string: "6F1A9B40-8C4E-4E48-9B2C-5D5D3B6F0A10")
    
    
    //6F1A9B40-8C4E-4E48-9B2C-5D5D3B6F0A10
    //6F1A9B40-8C4E-4D48-9B2C-5D5D3B6F0A10

    // 우리가 “자동으로” 찾아 잡을 값
    private var notifyChar: CBCharacteristic?
    private var writeChar: CBCharacteristic?

    // newline 파싱용(ESP가 \n으로 보내면 편함)
    private var buffer = Data()

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            status = "Bluetooth not ready"
            return
        }
        isScanning = true
        status = "Scanning..."
        log = ""
        central.scanForPeripherals(withServices: [serviceUUID], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }

    func disconnect() {
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        isScanning = false
    }

    /// (선택) 폰 -> ESP로 보내기
    func send(_ text: String) {
        guard let p = peripheral, let w = writeChar else {
            append("⚠️ No write characteristic")
            return
        }
        let data = Data(text.utf8)
        // 대부분 .withResponse 또는 .withoutResponse 중 하나만 가능
        let type: CBCharacteristicWriteType = w.properties.contains(.write) ? .withResponse : .withoutResponse
        p.writeValue(data, for: w, type: type)
        append("➡️ \(text)")
    }

    private func append(_ line: String) {
        log += (log.isEmpty ? "" : "\n") + line
    }

    private func handleIncoming(_ data: Data) {
        buffer.append(data)

        // newline(\n) 기준으로 줄 단위 처리
        while let range = buffer.firstRange(of: Data([0x0A])) { // \n
            let lineData = buffer.subdata(in: buffer.startIndex..<range.startIndex)
            buffer.removeSubrange(buffer.startIndex..<range.endIndex)

            if let line = String(data: lineData, encoding: .utf8) {
                append("⬅️ \(line)")
            } else {
                append("⬅️ (binary \(lineData.count) bytes)")
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
        // 첫 발견 즉시 연결
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
        peripheral.discoverServices([serviceUUID])
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
        isScanning = false
        status = "Disconnected"
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error { status = "Service error: \(error.localizedDescription)"; return }
        guard let services = peripheral.services else { return }

        for s in services where s.uuid == serviceUUID {
            status = "Discovering characteristics..."
            peripheral.discoverCharacteristics(nil, for: s) // nil = 전부 찾기
            return
        }
        status = "Service not found"
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error { status = "Char error: \(error.localizedDescription)"; return }
        guard let chars = service.characteristics else { return }

        // ⭐ 핵심: notify 가능한 char를 찾아서 구독
        for c in chars {
            if c.properties.contains(.notify) || c.properties.contains(.indicate) {
                notifyChar = c
                peripheral.setNotifyValue(true, for: c)
                status = "Subscribed (notify) ✅"
            }
            if c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse) {
                writeChar = c
            }
        }

        if notifyChar == nil {
            status = "No notify characteristic found ❌"
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
