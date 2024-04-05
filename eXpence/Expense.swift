//
//  Item.swift
//  MyExpenses
//
//  Created by David Lin on 08.03.24.
//

import Foundation
import SwiftData

enum ExpensesSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self]
    }

    @Model
    final class Expense {
        var name: String
        var amount: Double
        var timestamp: Date

        init(name: String, amount: Double, timestamp: Date) {
            self.name = name
            self.amount = amount
            self.timestamp = timestamp
        }
    }
}

enum ExpensesSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, ExpenseCategory.self]
    }

    @Model
    final class Expense {
        var name: String
        var amount: Double
        var timestamp: Date
        var category: ExpenseCategory?

        init(name: String, amount: Double, timestamp: Date, category: ExpenseCategory?) {
            self.name = name
            self.amount = amount
            self.timestamp = timestamp
            self.category = category
        }

        var asDictionary: [String: Any] {
            var dict = [String: Any]()
            dict["name"] = self.name
            dict["amount"] = self.amount
            dict["timestamp"] = self.timestamp
            if let category = self.category {
                dict["category"] = category.asDictionary
            }
            return dict
        }
    }

    @Model
    final class ExpenseCategory {
        @Attribute(.unique) var name: String
        var symbol: String

        init(name: String, symbol: String) {
            self.name = name
            self.symbol = symbol
        }

        var asDictionary: [String: Any] {
            var dict = [String: Any]()
            dict["name"] = self.name
            dict["symbol"] = self.symbol
            return dict
        }
    }
}

typealias ExpenseCategory = ExpensesSchemaV2.ExpenseCategory

typealias Expense = ExpensesSchemaV2.Expense

extension Expense {
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }

    var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }

    var timestampText: String {
        return dateFormatter.string(from: timestamp)
    }

    var amountString: String {
        return currencyFormatter.string(from: amount as NSNumber) ?? "n.a"
    }
}
