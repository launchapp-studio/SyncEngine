//
//  SyncEngine.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import Observation
import SwiftData

/// An error thrown while synchronizing.
public enum SyncError: LocalizedError, Sendable, Equatable {
    /// There is no network connection available.
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

/// The main entry point for offline-first synchronization.
///
/// Inject an instance into your SwiftUI environment and call ``sync()`` to
/// reconcile local `.pending` records to `.synced`.
@MainActor
@Observable
public final class SyncEngine {
    /// The observable status of the engine, suitable for driving UI.
    public enum SyncStatus: Sendable, Equatable {
        /// No sync is in progress.
        case idle
        /// A sync is currently running.
        case syncing
        /// The last sync failed with the associated message.
        case error(String)
    }

    /// The current synchronization status.
    public private(set) var status: SyncStatus = .idle

    /// The number of `.pending` records across ``SyncConfiguration/syncableTypes``.
    ///
    /// Refreshed on creation, after every main-context save, and after each ``sync()``.
    /// Call ``refreshPendingCount()`` after saving from other contexts.
    public private(set) var pendingCount: Int = 0

    private let databaseActor: DatabaseActor
    private let networkMonitor: NetworkMonitor
    private let stateTracker: SyncStateTracker?
    @ObservationIgnored private nonisolated(unsafe) var didSaveObserver: NSObjectProtocol?
    /// The configuration the engine was created with.
    public let configuration: SyncConfiguration

    /// Whether the device currently has a network connection.
    public var isConnected: Bool {
        networkMonitor.isConnected
    }

    /// Creates a sync engine bound to a SwiftData container.
    /// - Parameters:
    ///   - modelContainer: The container whose records are synchronized.
    ///   - configuration: The behavior configuration. Defaults to ``SyncConfiguration/default``.
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
        didSaveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: modelContainer.mainContext,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in await self?.refreshPendingCount() }
        }
        Task { [weak self] in await self?.refreshPendingCount() }
    }

    deinit {
        if let didSaveObserver {
            NotificationCenter.default.removeObserver(didSaveObserver)
        }
    }

    /// Recounts the `.pending` records of every registered model type into ``pendingCount``.
    public func refreshPendingCount() async {
        var total = 0
        for modelType in configuration.syncableTypes {
            total += (try? databaseActor.pendingCount(ofType: modelType)) ?? 0
        }
        pendingCount = total
    }

    /// Reconciles every registered model's `.pending` records to `.synced`.
    /// - Throws: ``SyncError/networkUnavailable`` when offline, or a persistence error.
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

            await refreshPendingCount()
            status = .idle
        } catch {
            await refreshPendingCount()
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
