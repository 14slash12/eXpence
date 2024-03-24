//
//  eXpenceWidget.swift
//  eXpenceWidget
//
//  Created by David Lin on 23.03.24.
//

import WidgetKit
import SwiftUI
import SwiftData

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
    var entry: Provider.Entry

    var body: some View {
        VStack {
            ForEach(entry.expenses) { expense in
                Text(expense.name)
            }
        }
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
    }
}

#Preview(as: .systemSmall) {
    eXpenceWidget()
} timeline: {
    SimpleEntry(date: .now, expenses: [Expense(name: "Rewe", amount: 20.0, timestamp: Date(), category: nil)])
}
