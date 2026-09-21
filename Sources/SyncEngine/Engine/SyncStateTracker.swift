//
//  SyncStateTracker.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import SwiftData

/// Observes a `ModelContext` and stamps inserted or modified `SyncableModel`s as `.pending`
/// before each save, so adopters never have to manage sync state by hand.
@MainActor
final class SyncStateTracker {
    private let context: ModelContext
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    init(context: ModelContext) {
        self.context = context
        observer = NotificationCenter.default.addObserver(
            forName: ModelContext.willSave,
            object: context,
            queue: nil
        ) { [weak self] _ in
            // `willSave` for a main context is delivered synchronously on the main thread.
            MainActor.assumeIsolated {
                self?.flagPendingModels()
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func flagPendingModels() {
        let candidates = context.insertedModelsArray + context.changedModelsArray
        // Guarding on `!= .pending` keeps this idempotent and avoids re-firing on our own change.
        for case let model as any SyncableModel in candidates where model.syncState != .pending {
            model.updatedAt = Date()
            model.syncState = .pending
        }
    }
}
