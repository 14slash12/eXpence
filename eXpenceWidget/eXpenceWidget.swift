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
    func fetch() -> [Expense] {
        
        guard let modelContainer = try? ModelContainer(for: Expense.self) else { return []
        }
        let descriptor = FetchDescriptor<Expense>()
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
    @StateObject var userViewModel = UserViewModel()

    var entry: Provider.Entry
    let specialDate: SpecialDate

    var body: some View {
        VStack {
            if userViewModel.isSubscriptionActive {
                sumView()
            } else {
                Text("Become a Pro member to unlock widgets")
            }

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
        let currentExpensesPredicate = filterInterval(from: .now, by: specialDate.type)!
        let currentExpenses = try? entry.expenses.filter(currentExpensesPredicate)
        let currentExpensesSum = currentExpenses?.reduce(0.0) {$0 + $1.amount}

        guard let currentExpensesSum else { return "-" }
        return K.currencyFormatter.string(from: currentExpensesSum as NSNumber) ?? "-"
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
                        Text(specialDate.type == .week ? "This week" : "This month")
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
            let lastExpensesPredicate = filterInterval(from: specialDate.type == .week ? Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())! : Calendar.current.date(byAdding: .month, value: 1, to: Date())!, by: specialDate.type)!
            let currentExpensesPredicate = filterInterval(from: .now, by: specialDate.type)!

            let lastExpenses = try? entry.expenses.filter(lastExpensesPredicate)
            let lastExpensesSum = lastExpenses?.reduce(0.0) {$0 + $1.amount}
            let currentExpenses = try? entry.expenses.filter(currentExpensesPredicate)
            let currentExpensesSum = currentExpenses?.reduce(0.0) {$0 + $1.amount}

            guard let lastExpensesSum, let currentExpensesSum else {
                return .neutral
            }

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

    private func filterInterval(from input: Date, by type: DateType) -> Predicate<Expense>? {
        var start: Date
        var end: Date

        switch type {
        case .day:
            start = Calendar.current.startOfDay(for: input)
            guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: start) else {
                return nil
            }
            end = endOfDay

        case .week:
            guard let startOfWeek = input.startOfWeek, let endOfWeek = input.endOfWeek else {
                return nil
            }

            start = startOfWeek
            end = endOfWeek

            print(start)
            print(end)

        case .month:
            start = input.startOfMonth
            end = input.endOfMonth
        }


        return #Predicate<Expense> { expense in
            return expense.timestamp < end && expense.timestamp >= start
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
                eXpenceWidgetEntryView(entry: entry, specialDate: SpecialDate(date: .now, type: .week))
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                eXpenceWidgetEntryView(entry: entry, specialDate: SpecialDate(date: .now, type: .week))
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Weekly")
        .description("Shows total weekly expenses.")
        .contentMarginsDisabled()
    }
}

struct eXpenceMonthlyWidget: Widget {
    let kind: String = "eXpenceWidgetMonthly"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                eXpenceWidgetEntryView(entry: entry, specialDate: SpecialDate(date: .now, type: .month))
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                eXpenceWidgetEntryView(entry: entry, specialDate: SpecialDate(date: .now, type: .month))
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Monthly")
        .description("Shows total monthly expenses.")
        .contentMarginsDisabled()
    }
}


// Do not delete this preview -> idk why but otherwise the preview will result in an error
struct CountdownsWidget_Previews: PreviewProvider {
    static var previews: some View {
        let modelContainer = try! ModelContainer(for: Expense.self)
        eXpenceWidgetEntryView(entry: SimpleEntry(date: .now, expenses: [Expense(name: "Rewe", amount: 20.0, timestamp: Date(), category: nil)]), specialDate: SpecialDate(date: .now, type: .month))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .modelContainer(modelContainer)
            .containerBackground(.fill.tertiary, for: .widget)

    }
}

#Preview(as: .systemSmall) {
    eXpenceMonthlyWidget()
} timeline: {
    SimpleEntry(date: .now, expenses: [Expense(name: "Rewe", amount: 20.0, timestamp: Date(), category: nil)])
}

#Preview(as: .systemSmall) {
    eXpenceWidget()
} timeline: {
    SimpleEntry(date: .now, expenses: [Expense(name: "Rewe", amount: 20.0, timestamp: Date(), category: nil)])
}
