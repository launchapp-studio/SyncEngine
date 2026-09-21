# SyncEngine ⚡️

A modern, **Offline-First** sync engine built for **SwiftData** and **Swift 6**. Designed with strict concurrency isolation to prevent data races, duplicated records, and sync conflicts.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Key Features

- **Swift 6 Strict Concurrency:** Fully isolated `@ModelActor` database mutations to guarantee thread safety.
- **Automatic State Tracking:** Inserted or modified models are flagged `.pending` on save automatically — just conform, no manual bookkeeping.
- **Offline-First State Management:** Automatic tracking of sync states (`.synced`, `.pending`, `.conflict`) on every model.
- **Reactive Network Monitoring:** Live connectivity detection using `NWPathMonitor` wrapped in SwiftUI `@Observable`.
- **CloudKit Ready:** Pre-configured helpers for native Apple iCloud database synchronization out of the box.
- **SwiftUI Integration:** Ready-to-use `SyncStatusBadge` component for instant navigation bar state feedback.

> **Note:** The open-source engine tracks the `.conflict` state and reconciles `.pending` records to `.synced`, delegating the actual merge to CloudKit's last-write-wins model. Automatic **field-level conflict detection and resolution** is part of **SyncEngine Pro**.

---

## Installation

Add `SyncEngine` to your project via **Swift Package Manager (SPM)** in Xcode:

```swift
dependencies: [
    .package(url: "https://github.com/launchapp-studio/SyncEngine.git", from: "1.0.0")
]
```

---

## Quick Start

### 1. Conform your SwiftData Model
Adopt the `SyncableModel` protocol on any SwiftData model class:

```swift
import SwiftData
import SyncEngine

@Model
final class TaskItem: SyncableModel {
    var syncID: UUID = UUID()
    var title: String
    var updatedAt: Date = Date()
    var syncStateRaw: String = SyncState.synced.rawValue

    init(title: String) {
        self.title = title
    }
}
```

### 2. Initialize SyncEngine in App Entry
Inject `SyncEngine` into your SwiftUI environment:

```swift
import SwiftUI
import SwiftData
import SyncEngine

@main
struct MyApp: App {
    let container: ModelContainer
    @State private var syncEngine: SyncEngine

    init() {
        let config = CloudKitHelper.makeConfiguration(containerIdentifier: "iCloud.com.example.MyApp")
        let container = try! ModelContainer(for: TaskItem.self, configurations: config)
        self.container = container

        // Register the models SyncEngine should reconcile during `sync()`.
        let syncConfig = SyncConfiguration(syncableTypes: [TaskItem.self])
        self._syncEngine = State(
            initialValue: SyncEngine(modelContainer: container, configuration: syncConfig)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncEngine)
        }
        .modelContainer(container)
    }
}
```

### 3. Trigger a sync
Call `sync()` from any view that has the engine in its environment. It checks connectivity, reconciles every registered model's `.pending` records to `.synced`, and updates `status` for the UI:

```swift
Button("Sync now") {
    Task { try? await syncEngine.sync() }
}
```

### 4. Display Sync Status in UI
Use the built-in toolbar badge in your views:

```swift
import SwiftUI
import SyncEngine

struct ContentView: View {
    @Environment(SyncEngine.self) private var syncEngine

    var body: some View {
        NavigationStack {
            List { ... }
                .navigationTitle("My Tasks")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        SyncStatusBadge()
                    }
                }
        }
    }
}
```

---

## Example App

A runnable SwiftUI demo lives in [`Examples/`](Examples/). Open `Examples/SyncEngineWorkspace.xcworkspace` in Xcode and run the **SyncEngineDemo** target to create records, watch their per-item state transition from `.pending` to `.synced`, and see the `SyncStatusBadge` update live.

---

## Architecture Overview

```text
┌────────────────────────────────────────────────────────┐
│                      SwiftUI View                      │
│            (Consumes @Observable SyncEngine)           │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
    ┌───────────────────┐       ┌───────────────────┐
    │  NetworkMonitor   │       │   DatabaseActor   │
    │  (NWPathMonitor)  │       │   (@ModelActor)   │
    └───────────────────┘       └─────────┬─────────┘
                                          │
                                          ▼
                                ┌───────────────────┐
                                │     SwiftData     │
                                └───────────────────┘
```

---

## Advanced Features & Pro Version

Cross-platform sync (PostgreSQL, Supabase, Web, Android), custom field-level conflict resolution, and an offline resilient mutation queue are planned for **SyncEngine Pro**. Stay tuned.

---

## License

`SyncEngine` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
