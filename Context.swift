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
        let standardCategories = [
            ExpenseCategory(name: String(localized: "Groceries", table: .localizable), symbol: "🛒"),
            ExpenseCategory(name: String(localized: "Insurance", table: .localizable), symbol: "🛡️"),
            ExpenseCategory(name: String(localized: "Restaurant", table: .localizable), symbol: "🥙"),
            ExpenseCategory(name: String(localized: "Fitness", table: .localizable), symbol: "🏃"),
            ExpenseCategory(name: String(localized: "Pet Care", table: .localizable), symbol: "🐾"),
            ExpenseCategory(name: String(localized: "Rent", table: .localizable), symbol: "🏡"),
            ExpenseCategory(name: String(localized: "Shopping", table: .localizable), symbol: "🛍️"),
            ExpenseCategory(name: String(localized: "Technology", table: .localizable), symbol: "📱"),
            ExpenseCategory(name: String(localized: "Entertainment", table: .localizable), symbol: "🖥️"),
            ExpenseCategory(name: String(localized: "Utilities", table: .localizable), symbol: "💡"),
            ExpenseCategory(name: String(localized: "Mobility", table: .localizable), symbol: "🚗"),
        ]

        for category in standardCategories {
            container.mainContext.insert(category)
        }

        return container
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
