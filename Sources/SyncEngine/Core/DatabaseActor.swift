//
//  DatabaseActor.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import SwiftData

/// An actor that owns SwiftData mutations off the main thread.
@ModelActor
public actor DatabaseActor {
    /// Inserts a model and marks it `.pending` for the next sync.
    public func savePending<T: SyncableModel>(_ model: T) throws {
        model.updatedAt = Date()
        model.syncState = .pending
        modelContext.insert(model)
        try modelContext.save()
    }

    /// Reconciles all `.pending` records of the given type to `.synced`.
    // CloudKit uploads bytes but ignores our `syncStateRaw`; reconcile local flags once online.
    public func markPendingAsSynced<T: SyncableModel>(ofType type: T.Type) throws {
        let pendingRaw = SyncState.pending.rawValue
        let descriptor = FetchDescriptor<T>(
            predicate: #Predicate { $0.syncStateRaw == pendingRaw }
        )
        let pendingModels = try modelContext.fetch(descriptor)
        for model in pendingModels {
            model.syncState = .synced
        }
        try modelContext.save()
    }

    /// Fetches all `.pending` records of the given type.
    public nonisolated func fetchPendingModels<T: SyncableModel>(ofType type: T.Type) throws -> sending [T] {
        let context = ModelContext(modelContainer)
        let pendingRaw = SyncState.pending.rawValue
        let descriptor = FetchDescriptor<T>(
            predicate: #Predicate { $0.syncStateRaw == pendingRaw }
        )
        return try context.fetch(descriptor)
    }
}
