//
//  Generalize.swift
//  MyExpenses
//
//  Created by David Lin on 08.03.24.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
let previewRandomContainer: ModelContainer = {
    do {
        let schema = Schema([
            Expense.self, ExpenseCategory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container = try ModelContainer(for: schema,
                                           configurations: .init(isStoredInMemoryOnly: true))

        for _ in 1...10 {
            container.mainContext.insert(generate())
        }

        return container
    } catch {
        fatalError("Failed to create container")
    }
}()

@MainActor
let previewConstantContainer: ModelContainer = {
    do {
        let schema = Schema([
            Expense.self, ExpenseCategory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container = try ModelContainer(for: schema,
                                           configurations: .init(isStoredInMemoryOnly: true))

        let before3day = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let before2day = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let next2day = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let next3day = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        
        let grocery = ExpenseCategory(name: "Groceries", symbol: "🛒")

        let expenses = [
            Expense(name: "Rewe", amount: 10.0, timestamp: Date(), category: grocery),
            Expense(name: "Edeka", amount: 10.0, timestamp: yesterday, category: grocery),
            Expense(name: "dm", amount: 10.0, timestamp: yesterday, category: grocery),
            Expense(name: "Zoettl", amount: 20.0, timestamp: tomorrow, category: grocery),
            Expense(name: "Aldi", amount: 20.0, timestamp: tomorrow, category: grocery),
            Expense(name: "Rewe", amount: 10.0, timestamp: next2day, category: grocery),
            Expense(name: "Rewe", amount: 10.0, timestamp: next3day, category: grocery),
            Expense(name: "Rewe", amount: 10.0, timestamp: Date(), category: grocery),
            Expense(name: "Edeka", amount: 10.0, timestamp: before2day, category: grocery),
            Expense(name: "dm", amount: 10.0, timestamp: yesterday, category: grocery),
            Expense(name: "Zoettl", amount: 20.0, timestamp: before3day, category: grocery),
            Expense(name: "Aldi", amount: 20.0, timestamp: before3day, category: grocery),
            Expense(name: "Rewe", amount: 10.0, timestamp: next2day, category: grocery),
            Expense(name: "Rewe", amount: 10.0, timestamp: next2day, category: grocery),
        ]
        for expense in expenses {
            container.mainContext.insert(expense)
        }

        return container
    } catch {
        fatalError("Failed to create container")
    }
}()

func generate() -> Expense {
    let expenseNames = [ "Edeka", "Rewe", "dm", "Apple Store", "SportScheck", "Sorry Jonny", "Fausto", "dean & david", "Fred Perry" ]
    let grocery = ExpenseCategory(name: "Groceries", symbol: "🛒")

    let randomIndex = Int.random(in: 0..<expenseNames.count)
    let randomTask = expenseNames[randomIndex]

    return Expense(name: randomTask, amount: Double.random(in: 1.0..<100), timestamp:
                    Calendar.current.date(byAdding: .day, value: Int.random(in: -10 ..< 0), to: Date())!, category: grocery
    )
}


extension Date {

    static func randomBetween(start: String, end: String, format: String = "yyyy-MM-dd") -> String {
        let date1 = Date.parse(start, format: format)
        let date2 = Date.parse(end, format: format)
        return Date.randomBetween(start: date1, end: date2).dateString(format)
    }

    static func randomBetween(start: String, end: String, format: String = "yyyy-MM-dd") -> Date {
        let date1 = Date.parse(start, format: format)
        let date2 = Date.parse(end, format: format)
        return Date.randomBetween(start: date1, end: date2)
    }

    static func randomBetween(start: Date, end: Date) -> Date {
        var date1 = start
        var date2 = end
        if date2 < date1 {
            let temp = date1
            date1 = date2
            date2 = temp
        }
        let span = TimeInterval.random(in: date1.timeIntervalSinceNow...date2.timeIntervalSinceNow)
        return Date(timeIntervalSinceNow: span)
    }

    func dateString(_ format: String = "yyyy-MM-dd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    static func parse(_ string: String, format: String = "yyyy-MM-dd") -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.default
        dateFormatter.dateFormat = format

        let date = dateFormatter.date(from: string)!
        return date
    }
}

extension Date {
    var startOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let lastSunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 1, to: lastSunday)
    }

    var endOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let startOfWeek = self.startOfWeek else { return nil }
        return gregorian.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)

    }

    var startOfMonth: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }

    var endOfMonth: Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1), to: self.startOfMonth)!
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}

enum K {
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }

    static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }

    static var stringToDoubleFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.maximumFractionDigits = 2
        return formatter
    }

    static var dateFormatter2: DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd")
        return formatter
    }

}

extension CGFloat {

    @inlinable public static var myCornerRadius: CGFloat { get { 15.0 } }
    @inlinable public static var myLarge1: CGFloat { get { 50.0 } }
    @inlinable public static var myLarge2: CGFloat { get { 25.0 } }
}

extension HorizontalAlignment {
   private enum MyLeadingAlignment: AlignmentID {
      static func defaultValue(in dimensions: ViewDimensions) -> CGFloat {
         return dimensions[HorizontalAlignment.leading]
      }
   }
   static let myLeading = HorizontalAlignment(MyLeadingAlignment.self)
}

extension HorizontalAlignment {
    /// A custom alignment for image titles.
    private struct ImageTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Default to bottom alignment if no guides are set.
            context[HorizontalAlignment.leading]
        }
    }


    /// A guide for aligning titles.
    static let imageTitleAlignmentGuide = HorizontalAlignment(
        ImageTitleAlignment.self
    )
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
