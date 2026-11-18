import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var ttlManager: TTLManager
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @State private var showingInfoAlert = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header
                headerView

                // MARK: - TTL Hero Card
                ttlHeroCard

                // MARK: - Network Status Card
                networkStatusCard

                // MARK: - Automation & Settings Card
                automationCard

                // MARK: - Status Toast / Footer
                if !ttlManager.statusMessage.isEmpty {
                    statusToastView
                }

                // MARK: - Footer Brand Logo
                footerLogoView
            }
            .padding(24)
        }
        .frame(minWidth: 440, idealWidth: 460, maxWidth: 520, minHeight: 660, idealHeight: 720)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(isPresented: $showingInfoAlert) {
            Alert(
                title: Text("TTL (Time to Live) Nedir?"),
                message: Text("TTL (Time to Live), RFC 791 IPv4 standardında bir ağ paketinin yönlendiriciler ve erişim noktaları üzerinden geçebileceği maksimum atlama (hop) sayısını belirleyen sistem parametresidir.\n\nmacOS varsayılan olarak giden paketler için TTL değerini 64 kullanır. Paket bir aracı cihaz veya yönlendiriciden geçerken TTL değeri 1 azalır.\n\nBu araç, yerel ağ ve çoklu atlama (tethering/köprü) yapılandırmalarında macOS çekirdek TTL parametresini (net.inet.ip.ttl) kolayca 65 olarak ayarlamanızı veya varsayılan 64 değerine döndürmenizi sağlar."),
                dismissButton: .default(Text("Anladım"))
            )
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("TTL 65")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Yöneticisi")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Text("IPv4 TTL Ağ Parametre Yöneticisi")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                showingInfoAlert = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("TTL 65 hakkında detaylı bilgi")

            Button(action: {
                ttlManager.refreshTTL()
                networkMonitor.refreshNetworkDetails()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Yenile")
        }
    }

    // MARK: - TTL Hero Card
    private var ttlHeroCard: some View {
        VStack(spacing: 16) {
            // Status Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(ttlManager.currentTTL == 65 ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(ttlManager.currentTTL == 65 ? "Özel TTL Profili Aktif" : "Standart macOS Değeri")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ttlManager.currentTTL == 65 ? .green : .orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill((ttlManager.currentTTL == 65 ? Color.green : Color.orange).opacity(0.12))
            )

            // Giant TTL Number
            VStack(spacing: 2) {
                Text("\(ttlManager.currentTTL)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(ttlManager.currentTTL == 65 ? .green : .primary)
                    .contentTransition(.numericText())

                Text("Mevcut Ağ TTL Değeri")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Big Primary Action Button
            Button(action: {
                ttlManager.setTTL(to: 65)
            }) {
                HStack(spacing: 8) {
                    if ttlManager.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .colorInvert()
                    } else {
                        Image(systemName: ttlManager.currentTTL == 65 ? "checkmark.circle.fill" : "bolt.fill")
                            .font(.system(size: 16, weight: .bold))
                    }

                    Text(ttlManager.currentTTL == 65 ? "TTL Zaten 65 (Tekrar Uygula)" : "TTL'yi 65 Yap")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: ttlManager.currentTTL == 65
                                    ? [Color.green.opacity(0.9), Color.green]
                                    : [Color.blue, Color(red: 0.1, green: 0.35, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
                .shadow(
                    color: (ttlManager.currentTTL == 65 ? Color.green : Color.blue).opacity(0.25),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(.plain)
            .disabled(ttlManager.isLoading)

            // Secondary Buttons
            HStack(spacing: 12) {
                Button(action: {
                    ttlManager.setTTL(to: 64)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Varsayılana Dön (64)")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(ttlManager.isLoading || ttlManager.currentTTL == 64)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            (ttlManager.currentTTL == 65 ? Color.green : Color.gray).opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Network Status Card
    private var networkStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Mevcut Ağ Bağlantısı", systemImage: "network")
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(networkMonitor.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)

                    Text(networkMonitor.isConnected ? "Bağlı" : "Bağlantı Yok")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(networkMonitor.isConnected ? .green : .red)
                }
            }

            Divider()

            // Hotspot Alert Banner if applicable
            if networkMonitor.isHotspot {
                HStack(spacing: 10) {
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kişisel Erişim Noktası (Hotspot) Algılandı")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)

                        Text(ttlManager.currentTTL == 65
                             ? "Çoklu atlama ağı için özel TTL değeri (65) aktif."
                             : "Aracı ağ geçidi algılandı. İsterseniz TTL değerini 65 yapabilirsiniz.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
            }

            // Network Details Grid
            VStack(spacing: 10) {
                NetworkDetailRow(title: "Bağlantı Tipi", value: networkMonitor.connectionType.rawValue, icon: networkMonitor.connectionType.systemIcon)
                NetworkDetailRow(title: "Ağ Arayüzü", value: networkMonitor.interfaceName, icon: "cable.connector")
                NetworkDetailRow(title: "Yerel IP (Mac)", value: networkMonitor.localIP, icon: "laptopcomputer")
                NetworkDetailRow(title: "Ağ Geçidi (Gateway)", value: networkMonitor.gatewayIP, icon: "point.3.connected.trianglepath.dotted")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.7))
        )
    }

    // MARK: - Automation & Settings Card
    private var automationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Otomasyon & Kurulum Ayarları", systemImage: "gearshape.2.fill")
                .font(.system(size: 14, weight: .bold))

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                AutomationToggleRow(
                    title: "Uygulama açılınca otomatik 65 yap",
                    subtitle: "Program her başlatıldığında TTL'yi doğrudan 65'e çeker.",
                    isOn: $ttlManager.autoSetOnLaunch
                )

                AutomationToggleRow(
                    title: "Ağa bağlanınca otomatik 65 yap",
                    subtitle: "Wi-Fi veya Hotspot ağına her bağlandığında TTL'yi kontrol eder.",
                    isOn: $ttlManager.autoSetOnNetworkChange
                )

                AutomationToggleRow(
                    title: "Mac açıldığında otomatik başlat",
                    subtitle: "Giriş ögelerine eklenir ve Mac her açıldığında arka planda çalışır.",
                    isOn: Binding(
                        get: { ttlManager.isLaunchAtLoginEnabled },
                        set: { ttlManager.toggleLaunchAtLogin(enable: $0) }
                    )
                )
            }

            Divider()

            // Sudoers Passwordless Mode
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Şifresiz Tek Tık Modu")
                            .font(.system(size: 13, weight: .semibold))

                        Text(ttlManager.isPasswordlessConfigured ? "Aktif" : "Kapalı")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ttlManager.isPasswordlessConfigured ? .green : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill((ttlManager.isPasswordlessConfigured ? Color.green : Color.gray).opacity(0.15))
                            )
                    }

                    Text("Açılışta veya butonda Touch ID / şifre sormadan sessizce 65 yapar.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                if ttlManager.isPasswordlessConfigured {
                    Button("İzni Kaldır") {
                        ttlManager.disablePasswordlessSudo()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)
                    .disabled(ttlManager.isLoading)
                } else {
                    Button("İzin Ver") {
                        ttlManager.enablePasswordlessSudo()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(ttlManager.isLoading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.7))
        )
    }

    // MARK: - Toast View
    private var statusToastView: some View {
        HStack(spacing: 8) {
            Image(systemName: ttlManager.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(ttlManager.isSuccess ? .green : .orange)

            Text(ttlManager.statusMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill((ttlManager.isSuccess ? Color.green : Color.orange).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((ttlManager.isSuccess ? Color.green : Color.orange).opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Footer Brand Logo View
    private var footerLogoView: some View {
        VStack(spacing: 6) {
            if let logo = loadLogoImage() {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150, maxHeight: 36)
                    .opacity(0.85)
            }

            Text("TTL 65 v\(appVersionString)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return version
    }

    private func loadLogoImage() -> NSImage? {
        // 1. Check inside application bundle (Contents/Resources/logo.png)
        if let url = Bundle.main.url(forResource: "logo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        // 2. Check local paths
        let paths = [
            "Resources/logo.png",
            "logo.png"
        ]
        for path in paths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }
}

// MARK: - Automation Toggle Row
private struct AutomationToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Network Detail Row
private struct NetworkDetailRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
