import SwiftUI
import Combine
struct BLESerialView: View {
    @StateObject private var ble = BLESerialManager()
    @State private var message: String = ""

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 14) {
                // Status
                HStack {
                    Text("Status:")
                        .font(.headline)
                    Text(ble.status)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                // Controls
                HStack(spacing: 10) {
                    Button {
                        ble.startScan()
                    } label: {
                        Label("Scan", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(ble.isScanning)

                    Button {
                        ble.disconnect()
                    } label: {
                        Label("Disconnect", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!ble.isConnected)

                    Spacer()
                }

                // Send box
                HStack(spacing: 10) {
                    TextField("Type to send…", text: $message)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06)))

                    Button {
                        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        ble.send(trimmed + "\n")   // newline 기반 (ESP32가 println이면 딱 좋음)
                        message = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!ble.isConnected)
                }

                // Log
                ScrollView {
                    Text(ble.log)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06)))
                }

                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("ESP32 Serial")
        .navigationBarTitleDisplayMode(.inline)
    }
}
