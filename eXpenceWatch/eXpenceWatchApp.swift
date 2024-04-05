//
//  eXpenceWatchApp.swift
//  eXpenceWatch Watch App
//
//  Created by David Lin on 29.03.24.
//

import SwiftUI
import SwiftData

@main
struct eXpenceWatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExpenseCategory.self, WeekExpense.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            //            return try ModelContainer(for: schema, migrationPlan: ExpensesMigrationPlan.self, configurations: [modelConfiguration])
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("error")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: WatchViewModel(modelContext: sharedModelContainer.mainContext))
                .modelContainer(sharedModelContainer)
        }
    }
}
