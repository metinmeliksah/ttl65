import SwiftUI
import AppKit

@main
struct TTLChangerApp: App {
    @StateObject private var ttlManager = TTLManager()
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        // Ensure app behaves like a standard regular macOS GUI app with Dock icon
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        // Main Application Window
        WindowGroup("TTL 65 Yöneticisi") {
            ContentView()
                .environmentObject(ttlManager)
                .environmentObject(networkMonitor)
                .onAppear {
                    setupNetworkCallback()
                }
        }
        .windowResizability(.contentSize)

        // Menu Bar Extra Item
        MenuBarExtra {
            MenuBarView()
                .environmentObject(ttlManager)
                .environmentObject(networkMonitor)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: ttlManager.currentTTL == 65 ? "bolt.shield.fill" : "network")
                Text("TTL \(ttlManager.currentTTL)")
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func setupNetworkCallback() {
        networkMonitor.onConnected = { [weak ttlManager] in
            guard let manager = ttlManager else { return }
            if manager.autoSetOnNetworkChange && manager.currentTTL != 65 {
                manager.setTTL(to: 65, reason: "Ağa bağlanıldı, otomatik TTL 65 yapıldı.")
            }
        }
    }
}
