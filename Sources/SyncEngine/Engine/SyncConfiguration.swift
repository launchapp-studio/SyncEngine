//
//  SyncConfiguration.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

public struct SyncConfiguration: Sendable {
    public enum ConflictPolicy: Sendable {
        case lastWriteWins
        case manual
    }

    public var conflictPolicy: ConflictPolicy
    public var syncableTypes: [any SyncableModel.Type]
    public var automaticStateTracking: Bool

    public init(
        conflictPolicy: ConflictPolicy = .lastWriteWins,
        syncableTypes: [any SyncableModel.Type] = [],
        automaticStateTracking: Bool = true
    ) {
        self.conflictPolicy = conflictPolicy
        self.syncableTypes = syncableTypes
        self.automaticStateTracking = automaticStateTracking
    }

    public static let `default` = SyncConfiguration()
}
