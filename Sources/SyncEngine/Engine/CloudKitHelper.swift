//
//  CloudKitHelper.swift
//  SyncEngine
//
//  Created by LaunchApp Studio on 2026.
//

import Foundation
import SwiftData

public enum CloudKitHelper {
    /// Creates a `ModelContainer` configuration ready to sync with CloudKit.
    /// - Parameters:
    ///   - containerIdentifier: The iCloud container identifier (e.g. "iCloud.com.yourcompany.app").
    ///   - isStoredInMemoryOnly: For testing environments or mocks.
    public static func makeConfiguration(
        containerIdentifier: String,
        isStoredInMemoryOnly: Bool = false
    ) -> ModelConfiguration {
        ModelConfiguration(
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: .private(containerIdentifier)
        )
    }
}