import Foundation
import Combine
import Darwin
import ServiceManagement

// Nonisolated helper operations for process and AppleScript execution
private enum TTLOperations: Sendable {
    static func executeSudoNonInteractive(ttl: Int) -> (success: Bool, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n", "/usr/sbin/sysctl", "-w", "net.inet.ip.ttl=\(ttl)"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (process.terminationStatus == 0, output)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    static func executeElevatedAppleScript(ttl: Int) -> (success: Bool, error: String?) {
        let script = "do shell script \"/usr/sbin/sysctl -w net.inet.ip.ttl=\(ttl)\" with administrator privileges"
        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorDict)
            if errorDict == nil {
                return (true, nil)
            } else {
                let msg = errorDict?[NSAppleScript.errorMessage] as? String ?? "İşlem iptal edildi."
                return (false, msg)
            }
        }
        return (false, "AppleScript çalıştırılamadı.")
    }

    static func executeElevatedScript(script: String) -> (success: Bool, error: String?) {
        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorDict)
            if errorDict == nil {
                return (true, nil)
            } else {
                let msg = errorDict?[NSAppleScript.errorMessage] as? String ?? "Yetki verilmedi."
                return (false, msg)
            }
        }
        return (false, "AppleScript çalıştırılamadı.")
    }
}

@MainActor
public final class TTLManager: ObservableObject {
    @Published public private(set) var currentTTL: Int = 0
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var statusMessage: String = ""
    @Published public private(set) var isSuccess: Bool = true
    @Published public private(set) var isPasswordlessConfigured: Bool = false
    @Published public private(set) var isLaunchAtLoginEnabled: Bool = false

    // Automation preferences
    @Published public var autoSetOnLaunch: Bool {
        didSet {
            UserDefaults.standard.set(autoSetOnLaunch, forKey: "autoSetOnLaunch")
        }
    }
    @Published public var autoSetOnNetworkChange: Bool {
        didSet {
            UserDefaults.standard.set(autoSetOnNetworkChange, forKey: "autoSetOnNetworkChange")
        }
    }

    private var pollTask: Task<Void, Never>?

    public init() {
        if UserDefaults.standard.object(forKey: "autoSetOnLaunch") == nil {
            self.autoSetOnLaunch = true
        } else {
            self.autoSetOnLaunch = UserDefaults.standard.bool(forKey: "autoSetOnLaunch")
        }

        if UserDefaults.standard.object(forKey: "autoSetOnNetworkChange") == nil {
            self.autoSetOnNetworkChange = true
        } else {
            self.autoSetOnNetworkChange = UserDefaults.standard.bool(forKey: "autoSetOnNetworkChange")
        }

        self.currentTTL = Self.readCurrentTTL()
        checkPasswordlessStatus()
        checkLaunchAtLoginStatus()

        // Lightweight periodic polling with async Task
        self.pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { break }
                self?.refreshTTL()
            }
        }

        // On launch automation: Set TTL to 65 automatically
        if autoSetOnLaunch && currentTTL != 65 {
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                self.setTTL(to: 65, reason: "Açılışta otomatik TTL 65 ayarlandı.")
            }
        }
    }

    deinit {
        pollTask?.cancel()
    }

    /// Read TTL directly from kernel via sysctlbyname (0 overhead, instantaneous)
    public static nonisolated func readCurrentTTL() -> Int {
        var ttl: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("net.inet.ip.ttl", &ttl, &size, nil, 0) == 0 {
            return Int(ttl)
        }
        return 0
    }

    public func refreshTTL() {
        let ttl = Self.readCurrentTTL()
        if self.currentTTL != ttl {
            self.currentTTL = ttl
        }
        checkPasswordlessStatus()
        checkLaunchAtLoginStatus()
    }

    public func checkPasswordlessStatus() {
        let exists = FileManager.default.fileExists(atPath: "/etc/sudoers.d/ttl_changer")
        if self.isPasswordlessConfigured != exists {
            self.isPasswordlessConfigured = exists
        }
    }

    public func checkLaunchAtLoginStatus() {
        let status = SMAppService.mainApp.status
        let enabled = (status == .enabled)
        if self.isLaunchAtLoginEnabled != enabled {
            self.isLaunchAtLoginEnabled = enabled
        }
    }

    public func toggleLaunchAtLogin(enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            checkLaunchAtLoginStatus()
            statusMessage = enable ? "Başlangıçta otomatik açılma etkinleştirildi." : "Başlangıçta otomatik açılma kapatıldı."
            isSuccess = true
        } catch {
            statusMessage = "Giriş ögesi ayarlanamadı: \(error.localizedDescription)"
            isSuccess = false
        }
    }

    /// Set TTL to desired value (e.g. 65)
    public func setTTL(to value: Int, reason: String? = nil) {
        guard !isLoading else { return }
        isLoading = true
        statusMessage = "TTL değeri \(value) olarak ayarlanıyor..."
        isSuccess = true

        Task.detached(priority: .userInitiated) {
            // Step 1: Try non-interactive sudo (instant and silent if configured)
            let sudoResult = TTLOperations.executeSudoNonInteractive(ttl: value)
            if sudoResult.success {
                await MainActor.run {
                    self.currentTTL = Self.readCurrentTTL()
                    self.isLoading = false
                    self.isSuccess = true
                    self.statusMessage = reason ?? "TTL başarıyla \(value) yapıldı!"
                }
                return
            }

            // Step 2: Fallback to AppleScript with administrator privileges (Touch ID / Admin password dialog)
            let scriptResult = TTLOperations.executeElevatedAppleScript(ttl: value)
            await MainActor.run {
                self.currentTTL = Self.readCurrentTTL()
                self.isLoading = false
                self.isSuccess = scriptResult.success
                if scriptResult.success {
                    self.statusMessage = reason ?? "TTL başarıyla \(value) yapıldı!"
                } else {
                    self.statusMessage = scriptResult.error ?? "Yetkilendirme başarısız oldu."
                }
            }
        }
    }

    /// Configure passwordless sudo for sysctl so future changes need no password prompt
    public func enablePasswordlessSudo() {
        guard !isLoading else { return }
        isLoading = true
        statusMessage = "Şifresiz mod yetkilendirmesi yapılıyor..."

        Task.detached(priority: .userInitiated) {
            let script = """
            do shell script "mkdir -p /etc/sudoers.d && echo '%admin ALL=(ALL) NOPASSWD: /usr/sbin/sysctl -w net.inet.ip.ttl=*' > /etc/sudoers.d/ttl_changer && chmod 0440 /etc/sudoers.d/ttl_changer" with administrator privileges
            """
            let result = TTLOperations.executeElevatedScript(script: script)

            await MainActor.run {
                self.isLoading = false
                self.checkPasswordlessStatus()
                if result.success {
                    self.isSuccess = true
                    self.statusMessage = "Şifresiz mod aktif! Artık açılışta ve ağ değişiminde şifre sormayacak."
                } else {
                    self.isSuccess = false
                    self.statusMessage = "Şifresiz mod ayarlanamadı: \(result.error ?? "Yetki verilmedi.")"
                }
            }
        }
    }

    /// Remove passwordless sudo configuration
    public func disablePasswordlessSudo() {
        guard !isLoading else { return }
        isLoading = true
        statusMessage = "Şifresiz mod kaldırılıyor..."

        Task.detached(priority: .userInitiated) {
            let script = """
            do shell script "rm -f /etc/sudoers.d/ttl_changer" with administrator privileges
            """
            let result = TTLOperations.executeElevatedScript(script: script)

            await MainActor.run {
                self.isLoading = false
                self.checkPasswordlessStatus()
                if result.success {
                    self.isSuccess = true
                    self.statusMessage = "Şifresiz mod kaldırıldı."
                } else {
                    self.isSuccess = false
                    self.statusMessage = "Şifresiz mod kaldırılamadı."
                }
            }
        }
    }
}
