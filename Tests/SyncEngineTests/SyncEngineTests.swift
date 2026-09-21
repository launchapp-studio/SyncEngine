//
//  SyncEngineTests.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import SwiftData
import Testing
@testable import SyncEngine

@Model
final class SampleTask: SyncableModel {
    var syncID: UUID
    var title: String
    var updatedAt: Date
    var syncStateRaw: String

    init(
        syncID: UUID = UUID(),
        title: String,
        updatedAt: Date = Date(),
        syncStateRaw: String = SyncState.synced.rawValue
    ) {
        self.syncID = syncID
        self.title = title
        self.updatedAt = updatedAt
        self.syncStateRaw = syncStateRaw
    }
}

// 1. Actor persistence and concurrency test
@Test func savePendingMarksModelAsPendingAndIsFetchable() async throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: SampleTask.self, configurations: configuration)
    let actor = DatabaseActor(modelContainer: container)

    let task = SampleTask(title: "Write tests")
    #expect(task.syncState == .synced)

    try await actor.savePending(task)

    let pending = try actor.fetchPendingModels(ofType: SampleTask.self)
    #expect(pending.count == 1)
    #expect(pending.first?.title == "Write tests")
    #expect(pending.first?.syncState == .pending)
}

// 2. SyncEngine status cycle test (exercise sync)
@MainActor
@Test func syncEngineStatusCycle() async throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: SampleTask.self, configurations: configuration)
    let engine = SyncEngine(modelContainer: container)

    #expect(engine.status == .idle)
    
    try await engine.sync()
    
    #expect(engine.status == .idle)
}

// 3. sync() reconciles registered pending models to synced (Free tier)
@MainActor
@Test func syncReconcilesPendingModelsToSynced() async throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: SampleTask.self, configurations: configuration)
    let actor = DatabaseActor(modelContainer: container)

    try await actor.savePending(SampleTask(title: "First"))
    try await actor.savePending(SampleTask(title: "Second"))
    #expect(try actor.fetchPendingModels(ofType: SampleTask.self).count == 2)

    let engine = SyncEngine(
        modelContainer: container,
        configuration: SyncConfiguration(syncableTypes: [SampleTask.self])
    )
    try await engine.sync()

    #expect(try actor.fetchPendingModels(ofType: SampleTask.self).isEmpty)
    #expect(engine.status == .idle)
}

// 4. Automatic state tracking flags freshly inserted models as pending
@MainActor
@Test func automaticStateTrackingMarksInsertedModelsPending() async throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: SampleTask.self, configurations: configuration)
    // Instantiating the engine attaches automatic state tracking to the main context.
    let engine = SyncEngine(
        modelContainer: container,
        configuration: SyncConfiguration(syncableTypes: [SampleTask.self])
    )

    let context = container.mainContext
    let task = SampleTask(title: "Auto")
    #expect(task.syncState == .synced)

    context.insert(task)
    try context.save()

    withExtendedLifetime(engine) {
        #expect(task.syncState == .pending)
    }
}