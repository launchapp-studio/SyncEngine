//
//  SyncableModel.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import SwiftData

public enum SyncState: String, Codable, Sendable {
    case synced
    case pending
    case conflict
}

public protocol SyncableModel: PersistentModel {
    var syncID: UUID { get set }
    var updatedAt: Date { get set }
    var syncStateRaw: String { get set }
}

public extension SyncableModel {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pending }
        set { syncStateRaw = newValue.rawValue }
    }
}
