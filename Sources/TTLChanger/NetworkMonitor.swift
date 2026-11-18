import Foundation
import Network
import Combine
import Darwin

public enum ConnectionType: String, Sendable {
    case cellularHotspot = "Kişisel Erişim Noktası (Hotspot)"
    case wifi = "Wi-Fi"
    case ethernet = "Kablolu Ethernet"
    case other = "Diğer Ağ"
    case disconnected = "Bağlantı Yok"

    public var systemIcon: String {
        switch self {
        case .cellularHotspot: return "personalhotspot"
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .other: return "network"
        case .disconnected: return "wifi.slash"
        }
    }
}

private enum NetworkHelpers: Sendable {
    /// Parse `route -n get default` output to find interface and gateway
    static func fetchDefaultRoute() -> (interface: String?, gateway: String?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/route")
        process.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return (nil, nil)
            }

            var interface: String?
            var gateway: String?

            for line in output.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("interface:") {
                    interface = trimmed.replacingOccurrences(of: "interface:", with: "").trimmingCharacters(in: .whitespaces)
                } else if trimmed.hasPrefix("gateway:") {
                    gateway = trimmed.replacingOccurrences(of: "gateway:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }

            return (interface, gateway)
        } catch {
            return (nil, nil)
        }
    }

    /// Read IPv4 address for a specific network interface (e.g. en0)
    static func getInterfaceIP(for targetInterface: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let ifName = String(cString: interface.ifa_name)
            if ifName == targetInterface && interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                var addr = interface.ifa_addr.pointee
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &host, socklen_t(host.count),
                            nil, 0, NI_NUMERICHOST)
                let len = host.firstIndex(of: 0) ?? host.count
                let bytes = host.prefix(len).map { UInt8(bitPattern: $0) }
                return String(decoding: bytes, as: UTF8.self)
            }
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }
        return nil
    }
}

@MainActor
public final class NetworkMonitor: ObservableObject {
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var connectionType: ConnectionType = .disconnected
    @Published public private(set) var interfaceName: String = "-"
    @Published public private(set) var localIP: String = "-"
    @Published public private(set) var gatewayIP: String = "-"
    @Published public private(set) var isHotspot: Bool = false
    @Published public private(set) var isExpensive: Bool = false
    @Published public private(set) var isConstrained: Bool = false
    @Published public private(set) var lastUpdated: Date = Date()

    public var onConnected: (() -> Void)?

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.metinmeliksah.ttl65.networkmonitor", qos: .background)
    private var wasConnected: Bool = false
    private var refreshTask: Task<Void, Never>?

    public init() {
        startMonitoring()

        // Periodic background refresh task
        self.refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { break }
                self?.refreshNetworkDetails()
            }
        }
    }

    deinit {
        monitor.cancel()
        refreshTask?.cancel()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func handlePathUpdate(_ path: NWPath) {
        let connected = (path.status == .satisfied)
        self.isConnected = connected
        self.isExpensive = path.isExpensive
        self.isConstrained = path.isConstrained

        refreshNetworkDetails()

        // Trigger onConnected if we just transitioned to connected
        if connected && !wasConnected {
            wasConnected = true
            onConnected?()
        } else if !connected {
            wasConnected = false
        }
    }

    public func refreshNetworkDetails() {
        lastUpdated = Date()

        // 1. Fetch default route details (interface and gateway)
        let routeInfo = NetworkHelpers.fetchDefaultRoute()
        let ifName = routeInfo.interface ?? (monitor.currentPath.availableInterfaces.first?.name ?? "en0")
        let gw = routeInfo.gateway ?? "-"

        self.interfaceName = ifName
        self.gatewayIP = gw

        // 2. Fetch Local IP for interface
        if ifName != "-" {
            self.localIP = NetworkHelpers.getInterfaceIP(for: ifName) ?? "-"
        } else {
            self.localIP = "-"
        }

        // 3. Determine connection type & hotspot status
        let isIPhoneHotspot = gw.hasPrefix("172.20.10.") || (gw == "172.20.10.1")
        let isAndroidHotspot = gw.hasPrefix("192.168.43.") || gw.hasPrefix("192.168.44.")
        let hotspotDetected = isIPhoneHotspot || isAndroidHotspot || monitor.currentPath.isExpensive

        self.isHotspot = hotspotDetected

        if !isConnected {
            self.connectionType = .disconnected
        } else if hotspotDetected {
            self.connectionType = .cellularHotspot
        } else if monitor.currentPath.usesInterfaceType(.wifi) {
            self.connectionType = .wifi
        } else if monitor.currentPath.usesInterfaceType(.wiredEthernet) {
            self.connectionType = .ethernet
        } else {
            self.connectionType = .other
        }
    }
}
