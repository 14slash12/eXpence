//
//  MyExpensesApp.swift
//  MyExpenses
//
//  Created by David Lin on 08.03.24.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
@MainActor
struct eXpenceApp: App {
    @StateObject var userViewModel = UserViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(userViewModel)
    }

    init() {
        Purchases.logLevel = .debug
        Purchases.configure(with: 
            Configuration.Builder(withAPIKey: "appl_qEGalBcGAGTVeiEvhEcbFZrDvlc")
                    .with(userDefaults: .init(suiteName: "group.com.apperium.Xpenses")!)
                    .build()
        )
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
