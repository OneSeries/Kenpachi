// NetworkMonitor.swift
// Network connectivity monitoring service
// Tracks network availability and connection type for offline features

import Foundation
import Network
import Combine

/// Network monitor service for tracking connectivity status
/// Uses NWPathMonitor to observe network changes in real-time
@Observable
final class NetworkMonitor {
    /// Shared singleton instance for app-wide access
    static let shared = NetworkMonitor()
    
    /// Network path monitor instance from Network framework
    private let monitor: NWPathMonitor
    /// Dispatch queue for network monitoring operations
    private let queue = DispatchQueue(label: "com.kenpachi.networkmonitor")
    
    /// Current network connection status
    var isConnected: Bool = false
    /// Whether connected via WiFi
    var isWiFiConnected: Bool = false
    /// Whether connected via cellular
    var isCellularConnected: Bool = false
    /// Whether connection is expensive (cellular or hotspot)
    var isExpensive: Bool = false
    /// Current connection type description
    var connectionType: ConnectionType = .none
    
    /// Enum representing connection types
    enum ConnectionType {
        /// No connection available
        case none
        /// WiFi connection
        case wifi
        /// Cellular connection
        case cellular
        /// Ethernet connection
        case ethernet
        /// Other connection type
        case other
    }
    
    /// Private initializer for singleton pattern
    private init() {
        // Initialize network path monitor
        monitor = NWPathMonitor()
    }
    
    /// Starts monitoring network connectivity
    /// Observes network path changes and updates status
    func startMonitoring() {
        // Set up path update handler to receive network changes
        monitor.pathUpdateHandler = { [weak self] path in
            // Update connection status on main thread for UI updates
            DispatchQueue.main.async {
                // Update overall connection status
                self?.isConnected = path.status == .satisfied
                // Update WiFi connection status
                self?.isWiFiConnected = path.usesInterfaceType(.wifi)
                // Update cellular connection status
                self?.isCellularConnected = path.usesInterfaceType(.cellular)
                // Update expensive connection flag
                self?.isExpensive = path.isExpensive
                // Determine and update connection type
                self?.updateConnectionType(from: path)
                
                // Log network status change
                AppLogger.shared.log(
                    "Network status changed: \(self?.connectionType.description ?? "unknown")",
                    level: .debug
                )
            }
        }
        
        // Start monitoring on background queue
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity
    /// Should be called when monitoring is no longer needed
    func stopMonitoring() {
        // Cancel the network monitor
        monitor.cancel()
        // Log monitoring stopped
        AppLogger.shared.log("Network monitoring stopped", level: .debug)
    }
    
    /// Refreshes current network status
    /// Forces an immediate check of network connectivity
    func refreshStatus() {
        // Get current path status
        let path = monitor.currentPath
        // Update connection status
        isConnected = path.status == .satisfied
        // Update WiFi status
        isWiFiConnected = path.usesInterfaceType(.wifi)
        // Update cellular status
        isCellularConnected = path.usesInterfaceType(.cellular)
        // Update expensive flag
        isExpensive = path.isExpensive
        // Update connection type
        updateConnectionType(from: path)
    }
    
    /// Updates connection type based on network path
    /// - Parameter path: Current network path
    private func updateConnectionType(from path: NWPath) {
        // Check WiFi connection
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        }
        // Check cellular connection
        else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        }
        // Check ethernet connection
        else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        }
        // Check if connected but type unknown
        else if path.status == .satisfied {
            connectionType = .other
        }
        // No connection
        else {
            connectionType = .none
        }
    }
}

// MARK: - ConnectionType Extension
extension NetworkMonitor.ConnectionType {
    /// Human-readable description of connection type
    var description: String {
        switch self {
        case .none:
            return "No Connection"
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .ethernet:
            return "Ethernet"
        case .other:
            return "Other"
        }
    }
}
