import SwiftUI

public struct MenuBarView: View {
    @EnvironmentObject var ttlManager: TTLManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.openWindow) var openWindow

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("TTL Yöneticisi", systemImage: "bolt.shield.fill")
                    .font(.system(size: 13, weight: .bold))

                Spacer()

                Text("TTL: \(ttlManager.currentTTL)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(ttlManager.currentTTL == 65 ? .green : .orange)
            }

            Divider()

            // Quick Status
            HStack(spacing: 8) {
                Image(systemName: networkMonitor.connectionType.systemIcon)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(networkMonitor.connectionType.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                    Text(networkMonitor.localIP != "-" ? "IP: \(networkMonitor.localIP)" : "Bağlantı Yok")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Action Button
            Button(action: {
                ttlManager.setTTL(to: 65)
            }) {
                HStack {
                    if ttlManager.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: ttlManager.currentTTL == 65 ? "checkmark.circle.fill" : "bolt.fill")
                    }
                    Text(ttlManager.currentTTL == 65 ? "TTL 65 Aktif" : "TTL'yi 65 Yap")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(ttlManager.currentTTL == 65 ? .green : .blue)
            .disabled(ttlManager.isLoading)

            Divider()

            // Window & Quit Actions
            HStack {
                Button("Pencereyi Göster") {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows where window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .font(.system(size: 11))

                Spacer()

                Button("Çıkış") {
                    NSApp.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(.red)
            }
        }
        .padding(12)
        .frame(width: 250)
    }
}
