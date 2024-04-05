//
//  ContentView.swift
//  eXpenceWatch Watch App
//
//  Created by David Lin on 29.03.24.
//

import SwiftUI
import SwiftData

@Model
struct WeekExpense {
    init(amount: Double) {
        self.amount = amount
    }

    let amount: Double
}

struct ContentView: View {
    @StateObject var viewModel: WatchViewModel


    @State var text = ""
    @State var category: String?
    
    
    @Query var categories: [ExpenseCategory]

    var body: some View {
            VStack {



//                TextField("", text: $text)
//                Picker(selection: $category, label: Text("Choose")) {
//                    Group {
//                        Text("None")
//                            .tag(nil as String?)
//
//                        ForEach(viewModel.categories, id: \.self) { category in
//                            Text(category)
//                                .tag(category as String?)
//                        }
//                    }
//                    .padding([.top, .bottom])
//                }
//
//
//                Button("Send") {
//                    sendExpense()
//                }
            }
    }

    private func sendExpense() {
        var expenseDict = ["name": text, "amount": 10.0, "timestamp": Date()] as [String : Any]
        if let category {
            expenseDict["category_name"] = category
        }

        self.viewModel.session.transferUserInfo(["message" : expenseDict])
    }
}

#Preview {
    ContentView(viewModel: WatchViewModel(modelContext: previewConstantContainer.mainContext))
        .modelContainer(previewConstantContainer)
}
