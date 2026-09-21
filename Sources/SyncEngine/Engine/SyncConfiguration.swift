//
//  SyncConfiguration.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

/// Configuration that controls how a ``SyncEngine`` behaves.
public struct SyncConfiguration: Sendable {
    /// The strategy used to resolve conflicting local and remote changes.
    public enum ConflictPolicy: Sendable {
        /// Keep the record with the newest `updatedAt` (default).
        case lastWriteWins
        /// Leave conflicts in the `.conflict` state for the app to resolve.
        case manual
    }

    /// The strategy used to resolve conflicts during a sync.
    public var conflictPolicy: ConflictPolicy
    /// The model types the engine reconciles when ``SyncEngine/sync()`` runs.
    public var syncableTypes: [any SyncableModel.Type]
    /// When `true`, inserted or modified models are flagged `.pending` on save.
    public var automaticStateTracking: Bool

    /// Creates a configuration.
    /// - Parameters:
    ///   - conflictPolicy: The conflict resolution strategy. Defaults to `.lastWriteWins`.
    ///   - syncableTypes: The model types to reconcile during a sync.
    ///   - automaticStateTracking: Whether to flag changed models `.pending` automatically.
    public init(
        conflictPolicy: ConflictPolicy = .lastWriteWins,
        syncableTypes: [any SyncableModel.Type] = [],
        automaticStateTracking: Bool = true
    ) {
        self.conflictPolicy = conflictPolicy
        self.syncableTypes = syncableTypes
        self.automaticStateTracking = automaticStateTracking
    }

    /// A configuration with default values.
    public static let `default` = SyncConfiguration()
}
