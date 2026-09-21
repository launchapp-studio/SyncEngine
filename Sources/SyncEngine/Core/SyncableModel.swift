//
//  SyncableModel.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import SwiftData

/// The synchronization state of a `SyncableModel` record.
public enum SyncState: String, Codable, Sendable {
    /// The local record matches the remote store.
    case synced
    /// The local record has changes waiting to be pushed.
    case pending
    /// The local and remote records diverged and need resolution.
    case conflict
}

/// A SwiftData model that SyncEngine can track and synchronize.
///
/// Conform your `@Model` types to this protocol to opt into automatic state
/// tracking and reconciliation.
public protocol SyncableModel: PersistentModel {
    /// A stable identifier shared between the local and remote records.
    var syncID: UUID { get set }
    /// The timestamp of the last local change, used for last-write-wins.
    var updatedAt: Date { get set }
    /// The raw persisted value backing ``SyncableModel/syncState``.
    var syncStateRaw: String { get set }
}

public extension SyncableModel {
    /// The strongly-typed sync state, backed by ``SyncableModel/syncStateRaw``.
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pending }
        set { syncStateRaw = newValue.rawValue }
    }
}
