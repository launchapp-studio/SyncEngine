import SwiftUI
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

@main
struct SyncEngineDemoApp: App {
    let container: ModelContainer
    @State private var syncEngine: SyncEngine

    init() {
        do {
            let container = try ModelContainer(for: TaskItem.self)
            self.container = container
            self._syncEngine = State(
                initialValue: SyncEngine(
                    modelContainer: container,
                    configuration: SyncConfiguration(syncableTypes: [TaskItem.self])
                )
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncEngine)
        }
        .modelContainer(container)
    }
}
