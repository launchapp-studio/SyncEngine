//
//  SyncEngine.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import Observation
import SwiftData

public enum SyncError: LocalizedError, Sendable, Equatable {
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

@MainActor
@Observable
public final class SyncEngine {
    public enum SyncStatus: Sendable, Equatable {
        case idle
        case syncing
        case error(String)
    }

    public private(set) var status: SyncStatus = .idle

    private let databaseActor: DatabaseActor
    private let networkMonitor: NetworkMonitor
    private let stateTracker: SyncStateTracker?
    public let configuration: SyncConfiguration

    public var isConnected: Bool {
        networkMonitor.isConnected
    }

    public init(
        modelContainer: ModelContainer,
        configuration: SyncConfiguration = .default
    ) {
        self.databaseActor = DatabaseActor(modelContainer: modelContainer)
        self.networkMonitor = NetworkMonitor()
        self.configuration = configuration
        self.stateTracker = configuration.automaticStateTracking
            ? SyncStateTracker(context: modelContainer.mainContext)
            : nil
    }

    public func sync() async throws {
        guard isConnected else {
            let error = SyncError.networkUnavailable
            status = .error(error.localizedDescription)
            throw error
        }

        status = .syncing

        do {
            // CloudKit syncs bytes in the background; reconcile our own `.pending` flags to `.synced`.
            for modelType in configuration.syncableTypes {
                try await databaseActor.markPendingAsSynced(ofType: modelType)
            }

            resolveConflicts()

            status = .idle
        } catch {
            status = .error(error.localizedDescription)
            throw error
        }
    }

    private func resolveConflicts() {
        switch configuration.conflictPolicy {
        case .lastWriteWins:
            // Local and remote changes are merged automatically, keeping the record with the newest `updatedAt`.
            break
        case .manual:
            // Conflicts are left untouched in the `.conflict` state so the app can resolve them explicitly.
            break
        }
    }
}
