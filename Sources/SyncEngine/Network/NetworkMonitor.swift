//
//  NetworkMonitor.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import Network
import Observation

/// Observes network reachability and exposes it as observable state.
@MainActor
@Observable
public final class NetworkMonitor {
    /// Whether the device currently has a satisfied network path.
    public private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "SyncEngine.NetworkMonitor")

    /// Creates a monitor and starts observing the default network path.
    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }

    /// Stops observing the network path.
    public func cancel() {
        monitor.cancel()
    }
}
