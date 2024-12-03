import Network
import Foundation

/// Håndterer overvågning af netværksforbindelse på tværs af appen.
class NetworkMonitorHandler {
    static let shared = NetworkMonitorHandler()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isMonitoring = false

    private init() {}

    /// Starter overvågning af netværksstatus. Kald kun én gang fra fx AppDelegate eller en ViewModel.
    func startMonitoring(onStatusChange: ((Bool) -> Void)? = nil) {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { path in
            // Returner true/false baseret på netværkstilgængelighed
            onStatusChange?(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    /// Stop overvågning (hvis påkrævet).
    func stopMonitoring() {
        monitor.cancel()
        isMonitoring = false
    }
} 