//
//  MyExpensesApp.swift
//  MyExpenses
//
//  Created by David Lin on 08.03.24.
//

import SwiftUI
import SwiftData

@main
@MainActor
struct eXpenceApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: PhoneViewModel(modelContext: sharedModelContainer.mainContext))
        }
        .modelContainer(sharedModelContainer)
    }
}

enum ExpensesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ExpensesSchemaV1.self, ExpensesSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: ExpensesSchemaV1.self,
        toVersion: ExpensesSchemaV2.self)
}
