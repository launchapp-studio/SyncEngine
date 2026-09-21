//
//  SyncStatusBadge.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import SwiftUI

/// A toolbar-ready badge that reflects the ``SyncEngine`` status and connectivity.
///
/// Reads the engine from the SwiftUI environment, so make sure one is injected.
public struct SyncStatusBadge: View {
    @Environment(SyncEngine.self) private var syncEngine

    /// Creates a sync status badge.
    public init() {}

    public var body: some View {
        Group {
            if !syncEngine.isConnected {
                Label("Offline", systemImage: "wifi.slash")
                    .foregroundStyle(.red)
            } else {
                switch syncEngine.status {
                case .syncing:
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Syncing")
                    }
                    .foregroundStyle(.secondary)
                case .idle:
                    Label("Synced", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .error(let message):
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .help(message) // Shows the error text on hover (macOS) or via Accessibility
                }
            }
        }
        .font(.caption)
        .labelStyle(.titleAndIcon)
        .imageScale(.small)
        .lineLimit(1)
        // Minimum width to avoid the navigation bar jumping when the state changes
        .frame(minWidth: 80, alignment: .trailing)
        // Smooth animation between state changes
        .animation(.default, value: syncEngine.status)
        .animation(.default, value: syncEngine.isConnected)
    }
}