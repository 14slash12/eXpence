//
//  MainView.swift
//  MyExpenses
//
//  Created by David Lin on 08.03.24.
//

import SwiftUI
import SwiftData
import Charts

struct ExpenseView: View {
    let expense: Expense

    var body: some View {
        HStack {
            ZStack {
                Circle().foregroundStyle(.white)
                    .frame(width: 35)
                    .shadow(radius: 5)
                Text(expense.category?.symbol ?? "💵")
            }
            VStack(alignment: .leading) {
                Text(expense.name)
                Text(expense.timestampText)
                    .foregroundStyle(Color.gray)
                    .opacity(0.5)
            }

            Spacer()

            Text(expense.amountString)
        }
    }
}

struct SumView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var expenses: [Expense]
    @Binding var specialDate: SpecialDate
    private var sumText: String {
        let sum = expenses.reduce(0.0) { $0 + $1.amount }

        return K.currencyFormatter.string(from: sum as NSNumber) ?? "-"
    }

    enum RelativeIndicator {
        case increased
        case neutral
        case decreased
    }

    init(filter: Predicate<Expense> = #Predicate { _ in true}, sort: SortDescriptor<Expense>, specialDate: Binding<SpecialDate>) {
        _expenses = Query(filter: filter, sort: [sort])
        _specialDate = specialDate
    }

    var body: some View {
        sumView()
    }

    private func sumView() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total spending")
                    .foregroundStyle(colorScheme == .light ? Color(.lightGray) : .black)

                Text(sumText)
                    .foregroundStyle(colorScheme == .light ? .white : .black)
                    .fontDesign(.monospaced)
                    .font(.custom("Menlo", size: .myLarge2))
                    .fontWeight(.heavy)
                    .contentTransition(.numericText())
            }
            .padding([.trailing])

            Group {
                switch decreasedToLast {
                case .increased:
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.red)
                case .neutral:
                    Text("-")
                        .foregroundStyle(.blue)
                case .decreased:
                    Image(systemName: "arrow.down.right")
                        .foregroundStyle(.green)
                }
            }
            .frame(width: .myLarge2)
        }
        .padding()
        .background {
            ZStack {
                GeometryReader { geo in

                    RoundedRectangle(cornerRadius: .myCornerRadius)
                        .shadow(radius: 5)
                    Rectangle()
                        .foregroundStyle({
                            switch decreasedToLast {
                            case .increased:
                                return Color(.quaternary)
                            case .neutral:
                                return Color(.tertiary)
                            case .decreased:
                                return Color(.secondary)
                            }
                        }())
                        .offset(x: geo.size.width - .myLarge1)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: .myCornerRadius,
                                topTrailingRadius: .myCornerRadius
                            )
                        )
                }
            }
        }
        .padding([.leading, .trailing])
    }

        func fetch(for descriptor: FetchDescriptor<Expense>) -> [Expense] {
            do {
                return try modelContext.fetch(descriptor)
            } catch {
                print("ERROR")
            }

            return []
        }

        // If the total spending decreased to the last day, week or month depending on what is currently shown to the user (i.e. in specialDate.type)
        var decreasedToLast: RelativeIndicator {
            let predicate = filterByDate()
            let lastExpenses = fetch(for: FetchDescriptor<Expense>(predicate: predicate))
            let lastExpensesSum = lastExpenses.reduce(0.0) {$0 + $1.amount}
            let currentExpensesSum = expenses.reduce(0.0) {$0 + $1.amount}


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
}

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var expenses: [Expense]
    @Binding var editExpense: Expense?

    init(filter: Predicate<Expense> = #Predicate { _ in true}, sort: SortDescriptor<Expense>, editExpense: Binding<Expense?>) {
        _expenses = Query(filter: filter, sort: [sort])
        _editExpense = editExpense
    }

    var body: some View {
        VStack {
            //ShareLink(item: generateCSV())

            List {
                ForEach(expenses) { expense in
                    Button {
                        withAnimation {
                            editExpense = expense
                        }
                    } label: {
                        ExpenseView(expense: expense)
                    }
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.plain)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }

    private func generateCSV() -> URL {
        var fileURL: URL!
        // heading of CSV file.
        let heading = "Name, Date, Amount\n"

        // file rows
        let rows = expenses.map { "\($0.name),\($0.timestamp),\($0.amount)" }

        // rows to string data
        let stringData = heading + rows.joined(separator: "\n")

        do {

            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)

            fileURL = path.appendingPathComponent("MyExpenses-\(Date()).csv")

            // append string data to file
            try stringData.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)

        } catch {
            print("error generating csv file")
        }
        return fileURL
    }
}

struct DateAdjustView: View {
    @Binding var specialDate: SpecialDate

    var body: some View {
        HStack {
            Button {
                changeDate(by: -1)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: .myCornerRadius)
                        .foregroundStyle(Color(.tertiary))
                        .opacity(0.25)
                        .frame(width: .myLarge1, height: .myLarge1)
                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    Image(systemName: "arrow.left")
                }
            }

            Button(dateText) {
                switch specialDate.type {
                case .day:
                    specialDate.type = .week
                case .week:
                    specialDate.type = .month
                case .month:
                    specialDate.type = .day
                }
            }
            .foregroundStyle(Color(.lightGray))


            Button {
                changeDate(by: 1)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: .myCornerRadius)
                        .foregroundStyle(Color(.tertiary))
                        .opacity(0.25)
                        .frame(width: .myLarge1, height: .myLarge1)
                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    Image(systemName: "arrow.right")
                }
            }
        }
    }

    func changeDate(by value: Int) {
        switch specialDate.type {
        case .day:
            guard let newDate = Calendar.current.date(byAdding: .day, value: value, to: specialDate.date) else {
                return
            }
            specialDate.date = newDate
        case .week:
            guard let newDate = Calendar.current.date(byAdding: .weekOfYear, value: value, to: specialDate.date) else {
                return
            }
            specialDate.date = newDate
        case .month:
            guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: specialDate.date) else {
                return
            }
            specialDate.date = newDate
        }
    }


    var dateText: String {
        let showYear = !isSameYear(specialDate.date, Date())

        var result = ""

        switch specialDate.type {
        case .day:
            result += K.dateFormatter.string(from: specialDate.date)
        case .week:
            result += "Week \(Calendar.current.component(.weekOfYear, from: specialDate.date))"
        case .month:
            result += "Month \(Calendar.current.component(.month, from: specialDate.date))"

        }
        
        if showYear {
            result += " of \(Calendar.current.component(.year, from: specialDate.date))"
        }

        return result
    }

    func isSameYear(_ first: Date, _ second: Date) -> Bool {
        return Calendar.current.compare(first, to: second, toGranularity: .year) == .orderedSame
    }
}

struct AggregatedExpense: Identifiable {
    var id: Date {
        return timestamp
    }

    let timestamp: Date
    let amount: Double
}

struct ChartView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var expenses: [Expense] = []
    
    @Binding var specialDate: SpecialDate
    @State private var selectedExpense: Date?
    
    private var aggregatedExpenses: [AggregatedExpense] {
        if specialDate.type == .day || specialDate.type == .week {
            return aggregateWeekly()
        } else {
            return aggregateMonthly()
        }
    }
    
    @State private var showPreview: Bool = true

    private var selectedAmount: Double? {
        guard let selectedExpense else { return nil }

        return aggregatedExpenses.first(where: {$0.timestamp == Calendar.current.startOfDay(for: selectedExpense)})?.amount
    }

    private var xAxisCount: Int {
        switch specialDate.type {
        case .day:
            return 7
        case .week:
            return 7
        case .month:
            return 7
        }
    }

    private var unit: Calendar.Component = .hour

    init(filter: Predicate<Expense> = #Predicate { _ in true}, sort: SortDescriptor<Expense>, specialDate: Binding<SpecialDate>) {
        _expenses = Query(filter: filter, sort: [sort])
        _specialDate = specialDate
    }

    let lightGradient = LinearGradient(
            gradient: Gradient (
                colors: [
                    .purple.opacity(0.1),
                     .white
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )

    let darkGradient = LinearGradient(
            gradient: Gradient (
                colors: [
                    .purple,
                    .black
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )

    var body: some View {
        Chart(aggregatedExpenses) {
            AreaMark(x: .value("Date", $0.timestamp), y:
                    .value("Amount", $0.amount))
            .interpolationMethod(.monotone)
            .foregroundStyle(colorScheme == .light ? lightGradient : darkGradient)
            
            if case .month = specialDate.type {
                LineMark(
                    x: .value("Date", $0.timestamp),
                    y: .value("Amount", $0.amount)
                )
                .interpolationMethod(.monotone)
            } else {
                LineMark(
                    x: .value("Date", $0.timestamp),
                    y: .value("Amount", $0.amount)
                )
                .interpolationMethod(.monotone)
                .symbol(.circle)
            }


            if let selectedExpense {
                RectangleMark(x: .value("Unit", selectedExpense, unit: unit))
                    .foregroundStyle(.primary.opacity(0.2))
                    .annotation(position: .trailing, spacing: 0, overflowResolution: .init(x: .fit(to: .chart))) {
                        VStack {
                            Text(selectedExpense.formatted(.dateTime.month().day()))

                            if let selectedAmount, let amountString = K.currencyFormatter.string(from: selectedAmount as NSNumber) {
                                Text(amountString)
                            }
                        }
                        .foregroundStyle(Color(.lightGray))
                        .padding()
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: .myCornerRadius/2)
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
            }
        }
        .chartXScale(domain: (aggregatedExpenses.map { $0.timestamp }.min() ?? Date())...(aggregatedExpenses.map { $0.timestamp}.max() ?? Date()))
        .chartXSelection(value: $selectedExpense)
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic(desiredCount: xAxisCount)) {
                let value = $0.as(Date.self)!
                AxisValueLabel(K.dateFormatter2.string(from: value), verticalSpacing: 20)
                    .foregroundStyle(Color(.lightGray))
            }
        }
        .chartYAxis {
            AxisMarks {
                let value = $0.as(Double.self)!
                AxisValueLabel(K.currencyFormatter.string(from: value as NSNumber)!, horizontalSpacing: 20)
                    .foregroundStyle(Color(.lightGray))
            }
        }
    }

    private func aggregateMonthly() -> [AggregatedExpense] {
        let end = Calendar.current.date(byAdding: .minute, value: -1, to: specialDate.date.endOfMonth)!
        let endDay = Calendar.current.dateComponents([.day], from: end).day!
        print("end \(end)")
        print(endDay)
        print(specialDate.date.startOfMonth)

        let weeksPerMonth = (0...endDay-1).map { Calendar(identifier: .iso8601).date(byAdding: .day, value: $0, to: specialDate.date.startOfMonth)! }

        let aggregatedExpenses = expenses.reduce(into: [Date: Double]()) { partialResult, expense in
            let currentAmount: Double = partialResult[expense.timestamp.startOfDay] ?? 0.0
            partialResult[expense.timestamp.startOfDay] = currentAmount + expense.amount
        }

        return weeksPerMonth.map { week in
            if let amount = aggregatedExpenses[week] {
                AggregatedExpense(timestamp: week, amount: amount)
            } else {
                AggregatedExpense(timestamp: week, amount: 0.0)
            }
        }
        .sorted { $0.timestamp < $1.timestamp }

    }

    private func aggregateWeekly() -> [AggregatedExpense] {
        let weekDays = (0...6).map { Calendar(identifier: .iso8601).date(byAdding: .day, value: $0, to: specialDate.date.startOfWeek ?? Date())! }

        let aggregatedExpenses = expenses.reduce(into: [Date: Double]()) { partialResult, expense in
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

    private func aggregatePreview() -> [AggregatedExpense] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let start = formatter.date(from: "20204/03/22 00:00")!

        let day1 = start.startOfWeek!.startOfDay
        let day2 = Calendar.current.date(byAdding: .day, value: 1, to: day1)!
        let day3 = Calendar.current.date(byAdding: .day, value: 2, to: day1)!
        let day4 = Calendar.current.date(byAdding: .day, value: 3, to: day1)!
        let day5 = Calendar.current.date(byAdding: .day, value: 4, to: day1)!
        let day6 = Calendar.current.date(byAdding: .day, value: 5, to: day1)!
        let day7 = Calendar.current.date(byAdding: .day, value: 6, to: day1)!

        return [
            AggregatedExpense(timestamp: day1, amount: 0.0),
            AggregatedExpense(timestamp: day2, amount: 40.0),
            AggregatedExpense(timestamp: day3, amount: 10.0),
            AggregatedExpense(timestamp: day4, amount: 30.0),
            AggregatedExpense(timestamp: day5, amount: 20.0),
            AggregatedExpense(timestamp: day6, amount: 40.0),
            AggregatedExpense(timestamp: day7, amount: 40.0)
        ]
    }
}

struct DataView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var specialDate: SpecialDate

    @State private var sort = SortDescriptor(\Expense.timestamp, order: .reverse)
    @State private var weekFilter = #Predicate<Expense> { _ in true }
    @State private var monthFilter = #Predicate<Expense> { _ in true }

    var body: some View {
//        ScrollView(.horizontal) {
//            HStack {
            ChartView(filter: weekFilter, sort: sort, specialDate: $specialDate )
                .padding()

                .foregroundStyle(.purple)
                .frame(width: .myLarge1*7, height: .myLarge1*4)
//                .containerRelativeFrame(.horizontal)
//        }.scrollTargetBehavior(.paging)



            .onChange(of: specialDate) {
                filterDates()
            }
            .onAppear() {
                filterDates()
                print("Special Date \(specialDate.date)")
            }
    }

    private func filterDates() {
        guard let weekPredicate = filterInterval(from: specialDate.date, by: .week), let monthPredicate = filterInterval(from: specialDate.date, by: .month) else { return }
        if specialDate.type == .week || specialDate.type == .day {
            weekFilter = weekPredicate
        } else {
            weekFilter = monthPredicate
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
            print("Start of Month\(start)")
            end = input.endOfMonth
            print("End of Month\(end)")
        }

        return #Predicate<Expense> { expense in
            return expense.timestamp < end && expense.timestamp >= start
        }
    }
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query var categories: [ExpenseCategory]

    @State var editExpense: Expense? = nil

    @State var name: String = ""
    @State var amount: String = ""
    @State var date: Date = Date()
    @State var category: ExpenseCategory?

    @State private var sortOrder = SortDescriptor(\Expense.timestamp, order: .reverse)
    @State private var filter = #Predicate<Expense> { _ in true}
    @State var specialDate = SpecialDate(date: Date(), type: .week)
    @State var showAddView: Bool = false
    @State var showDataView: Bool = true

    enum Page {
        case list
        case add
    }

    var body: some View {
        VStack {
            welcomeView()

            SumView(filter: filter, sort: sortOrder, specialDate: $specialDate)

            if showDataView {
                DataView(specialDate: $specialDate)
            }

            HStack(alignment: .center) {
                Spacer()
                if showAddView || editExpense != nil {
                    cancelButton()
                } else {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            Text("Name")
                                .tag(SortDescriptor(\Expense.name))

                            Text("Date")
                                .tag(SortDescriptor(\Expense.timestamp, order: .reverse))

                            Text("Amount")
                                .tag(SortDescriptor(\Expense.amount))
                        }
                        .pickerStyle(.inline)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: .myCornerRadius)
                                .foregroundStyle(Color(.primary))
                                .opacity(0.25)
                                .frame(width: .myLarge1, height: .myLarge1)
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundStyle(.purple)
                        }
                    }
                }

                Spacer()


                DateAdjustView(specialDate: $specialDate)

                Spacer()
                if showAddView || editExpense != nil {
                    saveButton()
                } else {
                    Button {
                        withAnimation {
                            showAddView = true
                            reset()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: .myCornerRadius)
                                .foregroundStyle(Color(.primary))
                                .opacity(0.25)
                                .frame(width: .myLarge1, height: .myLarge1)
                            Image(systemName: "plus")
                                .foregroundStyle(.purple)
                        }
                    }
                }

                Spacer()
            }

            if showAddView || editExpense != nil {
                addItemView()
            }

            ListView(filter: filter, sort: sortOrder, editExpense: $editExpense)
        }
        .onChange(of: specialDate) {
            filterDate()
        }
        .onAppear() {
            filterDate()
        }
        .onChange(of: editExpense) {
            let formatter = NumberFormatter()
            formatter.locale = .current
            formatter.maximumFractionDigits = 2

            guard let editExpense, let amountString = formatter.string(from: editExpense.amount as NSNumber) else { return }

            self.name = editExpense.name
            self.amount = amountString
            self.date = editExpense.timestamp
            self.category = editExpense.category

        }
    }

    private func reset() {
        self.name = ""
        self.amount = ""
        self.date = Date()
        self.category = nil
    }

    private func cancelButton() -> some View {
        Button {
            withAnimation {
                showAddView = false
                editExpense = nil
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: .myCornerRadius)
                    .foregroundStyle(.red)
                    .opacity(0.25)
                    .frame(width: .myLarge1, height: .myLarge1)
                Image(systemName: "xmark")
                    .foregroundStyle(.red)
            }
        }
    }

    private func saveButton() -> some View {
        Button {
            withAnimation {
                addItem()
                showAddView = false
                editExpense = nil
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: .myCornerRadius)
                    .foregroundStyle(.green)
                    .opacity(0.25)
                    .frame(width: .myLarge1, height: .myLarge1)
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
            }
        }
    }

    private func addItem() {
        guard let amount = K.stringToDoubleFormatter.number(from: amount)?.doubleValue else {
            print("Amount failed")
            return
        }

        if showAddView {
            let newItem = Expense(name: name, amount: amount, timestamp: date, category: category)
            modelContext.insert(newItem)
        } else if let editExpense {
            // edit expense
            editExpense.name = name
            editExpense.amount = amount
            editExpense.timestamp = date
            editExpense.category = category
        }
    }

    private func filterDate() {
        guard let predicate = filterInterval(from: specialDate.date, by: specialDate.type) else { return }
        filter = predicate
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

    private func welcomeView() -> some View {
        HStack {
            Text("Welcome 👋")
                .font(.title)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding()
            Spacer()

            Button {
                withAnimation {
                    showDataView.toggle()
                }
            } label: {
                HStack {
                    Text(showDataView ? "Hide" : "Show")
                    Image(systemName: showDataView ? "arrowtriangle.down.fill" : "arrowtriangle.left.fill")
                }
                .foregroundStyle(Color(.lightGray))
                .padding(.myLarge1/5)
                .background {
                    RoundedRectangle(cornerRadius: .myCornerRadius*2)
                        .foregroundStyle(.gray.opacity(0.1))
                }
            }
            .padding()
        }
    }

    private func addItemView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "person")
                    .padding([.trailing])
                    .frame(width: .myLarge2)

                TextField("Name", text: $name)
                    .padding(10.0)
                    .background {
                        RoundedRectangle(cornerRadius: .myCornerRadius/2)
                            .foregroundStyle(Color(.lightGray))
                            .opacity(0.25)
                    }
            }
            .padding([.bottom], 5.0)
            HStack {
                Image(systemName: "creditcard")
                    .padding([.trailing])
                    .frame(width: .myLarge2)

                TextField("Amount", text: $amount)
                    .padding(10.0)
                    .background {
                        RoundedRectangle(cornerRadius: .myCornerRadius/2)
                            .foregroundStyle(Color(.lightGray))
                            .opacity(0.25)
                    }
            }
            .padding([.bottom], 5.0)

            HStack {
                Image(systemName: "calendar")
                    .padding([.trailing])
                    .frame(width: .myLarge2)

                DatePicker("Date:", selection: $date)
                    .labelsHidden()
                    .tint(.purple)
                    .alignmentGuide(.imageTitleAlignmentGuide) { context in
                        context[.firstTextBaseline]
                    }
                

            }
            .padding([.bottom], 5.0)

            HStack {
                Image(systemName: "cart")
                    .padding([.trailing])
                    .frame(width: .myLarge2)


                Picker(selection: $category, label: Text("Choose")) {
                    Text("None")
                        .tag(nil as ExpenseCategory?)

                    ForEach(categories, id: \.self) { category in
                        Text(category.name)
                            .tag(category as ExpenseCategory?)
                    }
                }.tint(colorScheme == .light ? .black : .white)
                    .padding(.horizontal, -10)
            }
        }
        .padding([.leading, .trailing, .top])
        .padding()
        .opacity(1)
        .background {
            RoundedRectangle(cornerRadius: .myCornerRadius)
                .foregroundStyle(colorScheme == .light ? Color(.primary) : .black)
                .shadow(radius: 10)
                .padding([.leading, .trailing, .top])
                .opacity(0.25)
        }
    }
}

#Preview {
    MainView()
        .modelContainer(previewConstantContainer)
}
