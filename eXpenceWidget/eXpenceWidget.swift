//
//  eXpenceWidget.swift
//  eXpenceWidget
//
//  Created by David Lin on 23.03.24.
//

import WidgetKit
import SwiftUI
import SwiftData
import Charts

struct Provider: TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), expenses: fetch())
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: .now, expenses: fetch())
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        var entries: [SimpleEntry] = []
//
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, expenses: [Expense(name: "Rewe", amount: 20.0, timestamp: Date(), category: nil)])
//            entries.append(entry)
//        }

        let timeline = Timeline(entries: [SimpleEntry(date: .now, expenses: fetch())], policy: .after(.now.addingTimeInterval(5)))
        completion(timeline)
    }

    @MainActor 
    func fetch(for descriptor: FetchDescriptor<Expense> = FetchDescriptor<Expense>(predicate: #Predicate<Expense> {_ in true})) -> [Expense] {
        
        guard let modelContainer = try? ModelContainer(for: Expense.self) else { return []
        }
        let descriptor = FetchDescriptor<Expense> (predicate: #Predicate { expense in
        true })
        let expenses = try? modelContainer.mainContext.fetch(descriptor)
        return expenses ?? []
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let expenses: [Expense]
}

struct eXpenceWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme

    var entry: Provider.Entry
    let specialDate = SpecialDate(date: .now, type: .week)

    var body: some View {
        VStack {
            sumView()
//            Chart(aggregateWeekly()) { expense in
//                LineMark(x: .value("Date", expense.timestamp),
//                         y: .value("Amount", expense.amount))
//            }
//            ForEach(entry.expenses) { expense in
//                Text(expense.name)
//            }
        }
    }

    private var sumText: String {
        let sum = entry.expenses.reduce(0.0) { $0 + $1.amount }

        return K.currencyFormatter.string(from: sum as NSNumber) ?? "-"
    }

    enum RelativeIndicator {
        case increased
        case neutral
        case decreased
    }

    private func sumView() -> some View {
            HStack {
                GeometryReader { geo in
                ZStack {
                    colorScheme == .light ? Color.black : Color.white

                    VStack(alignment: .leading) {
                        Text("This week")
                            .foregroundStyle(Color(.lightGray))

                        Text(sumText)
                            .foregroundStyle(colorScheme == .light ? .white : .black)
                            .fontDesign(.monospaced)
                            .font(.custom("Menlo", size: 21))
                            .fontWeight(.heavy)
                            .contentTransition(.numericText())
                    }
                    .padding([.leading, .trailing])
                }
                .frame(width: geo.size.width/4 * 3)

                Group {
                    switch decreasedToLast {
                    case .increased:
                        ZStack {
                            Color(.quaternary)
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.red)
                        }
                    case .neutral:
                        ZStack {
                            Color(.tertiary)
                            Text("-")
                                .foregroundStyle(.blue)
                        }
                    case .decreased:
                        ZStack {
                            Color(.secondary)
                            Image(systemName: "arrow.down.right")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .frame(width: geo.size.width/4)
                .offset(x: geo.size.width/4 * 3)
            }
        }
    }

        // If the total spending decreased to the last day, week or month depending on what is currently shown to the user (i.e. in specialDate.type)
        var decreasedToLast: RelativeIndicator {
            let predicate = filterByDate()!
            let lastExpenses = try? entry.expenses.filter(predicate)
            let lastExpensesSum = lastExpenses?.reduce(0.0) {$0 + $1.amount}
            let currentExpensesSum = entry.expenses.reduce(0.0) {$0 + $1.amount}
            
            guard let lastExpensesSum else { return .neutral }

            print(lastExpensesSum)
            print(currentExpensesSum)
            if currentExpensesSum < lastExpensesSum {
                return .decreased
            } else if currentExpensesSum == lastExpensesSum {
                return .neutral
            } else {
                return .increased
            }
        }

        func filterByDate() -> Predicate<Expense>? {
            var start: Date
            var end: Date

            switch specialDate.type {
            case .day:
                guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: specialDate.date) else { return nil }
                start = Calendar.current.startOfDay(for: yesterday)
                guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: start) else {
                    return nil
                }
                end = endOfDay

            case .week:
                let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: specialDate.date)

                guard let startOfWeek = lastWeek?.startOfWeek, let endOfWeek = lastWeek?.endOfWeek else {
                    return nil
                }

                start = startOfWeek
                end = endOfWeek

            case .month:

                guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: specialDate.date) else { return nil }

                start = lastMonth.startOfMonth
                end = lastMonth.endOfMonth
            }

            return #Predicate<Expense> { expense in
                return expense.timestamp <= end && expense.timestamp >= start
            }
        }

    private func aggregateWeekly() -> [AggregatedExpense] {
        let weekDays = (0...6).map { Calendar(identifier: .iso8601).date(byAdding: .day, value: $0, to: specialDate.date.startOfWeek ?? Date())! }

        let aggregatedExpenses = entry.expenses.reduce(into: [Date: Double]()) { partialResult, expense in
            let currentAmount: Double = partialResult[expense.timestamp.startOfDay] ?? 0.0
            partialResult[expense.timestamp.startOfDay] = currentAmount + expense.amount
        }

        return weekDays.map { weekDay in
            if let amount = aggregatedExpenses[weekDay] {
                AggregatedExpense(timestamp: weekDay, amount: amount)
            } else {
                AggregatedExpense(timestamp: weekDay, amount: 0.0)
            }
        }
        .sorted { $0.timestamp < $1.timestamp }

    }
}

struct eXpenceWidget: Widget {
    let kind: String = "eXpenceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                eXpenceWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                eXpenceWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    eXpenceWidget()
} timeline: {
    SimpleEntry(date: .now, expenses: [Expense(name: "Rewe", amount: 20.0, timestamp: Date(), category: nil)])
}
