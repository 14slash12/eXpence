//
//  Context.swift
//  eXpence
//
//  Created by David Lin on 23.03.24.
//

import Foundation
import SwiftData

@MainActor
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

        guard try container.mainContext.fetch(categoryFetchDescriptor).count == 0 else { return container }

        // This code will only run if the persistent store is empty.
        let categories = [
            ExpenseCategory(name: "Groceries", symbol: "🛒"),
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
