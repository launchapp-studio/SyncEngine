import SwiftUI
import SwiftData
import SyncEngine

struct ContentView: View {
    @Environment(SyncEngine.self) private var syncEngine
    @Environment(\.modelContext) private var modelContext

    // Reactive query against the SwiftData store
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var tasks: [TaskItem]

    @State private var newTaskTitle: String = ""

    var body: some View {
        NavigationStack {
            List {
                // Controls to interact with SyncEngine
                Section("Controls") {
                    HStack {
                        TextField("New task...", text: $newTaskTitle)

                        Button("Create") {
                            createTask()
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Button {
                        Task {
                            try? await syncEngine.sync()
                        }
                    } label: {
                        Label("Force Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                // Model list to verify SyncState changes in real time
                Section("Local Records (\(tasks.count))") {
                    if tasks.isEmpty {
                        ContentUnavailableView(
                            "No data",
                            systemImage: "tray",
                            description: Text("Create a task to test status tracking.")
                        )
                    } else {
                        ForEach(tasks) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.body)
                                    Text(task.syncID.uuidString.prefix(8))
                                        .font(.caption2)
                                        .monospaced()
                                        .foregroundStyle(.tertiary)
                                }

                                Spacer()

                                // Per-record status badge
                                Text(task.syncState.rawValue.capitalized)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(badgeColor(for: task.syncState).opacity(0.15))
                                    .foregroundStyle(badgeColor(for: task.syncState))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .navigationTitle("SyncEngine Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SyncStatusBadge()
                }
            }
        }
    }

    private func createTask() {
        let task = TaskItem(title: newTaskTitle)
        // SyncEngine's automatic state tracking marks it `.pending` on save.
        modelContext.insert(task)
        try? modelContext.save()
        newTaskTitle = ""
    }

    private func badgeColor(for state: SyncState) -> Color {
        switch state {
        case .synced: return .green
        case .pending: return .orange
        case .conflict: return .red
        }
    }
}
