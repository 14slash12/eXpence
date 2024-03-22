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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self, ExpenseCategory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
//            return try ModelContainer(for: schema, migrationPlan: ExpensesMigrationPlan.self, configurations: [modelConfiguration])
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            var categoryFetchDescriptor = FetchDescriptor<ExpenseCategory>()
            categoryFetchDescriptor.fetchLimit = 1

            guard try container.mainContext.fetch(categoryFetchDescriptor).count == 1 else { return container }

            // This code will only run if the persistent store is empty.
            let categories = [
//                ExpenseCategory(name: "Groceries", symbol: "🛒"),
                ExpenseCategory(name: "Insurance", symbol: "🛡️"),
                ExpenseCategory(name: "Lunch", symbol: "🥗")
            ]

            for category in categories {
                container.mainContext.insert(category)
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
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
