//
//  PhoneViewModel.swift
//  eXpence
//
//  Created by David Lin on 29.03.24.
//

import Foundation
import WatchConnectivity
import SwiftData

class PhoneViewModel : NSObject, WCSessionDelegate, ObservableObject {
    var modelContext: ModelContext

    var session: WCSession
    init(session: WCSession = .default, modelContext: ModelContext){
        self.session = session
        self.modelContext = modelContext
        super.init()
        self.session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }

    func sessionDidBecomeInactive(_ session: WCSession) {

    }

    func sessionDidDeactivate(_ session: WCSession) {

    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard let expenseDict = message["message"] as? [String:Any] else { return }

            guard let name = expenseDict["name"] as? String,
                  let amount = expenseDict["amount"] as? Double,
                  let timestamp = expenseDict["timestamp"] as? Date else { return }

            if let categoryName = expenseDict["category_name"] as? String {

                let category = try? self.modelContext.fetch(FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.name == categoryName })).first

                //Add Expense
                let expense = Expense(name: name, amount: amount, timestamp: timestamp, category: category)
                self.modelContext.insert(expense)
            } else {
                //Add Expense
                let expense = Expense(name: name, amount: amount, timestamp: timestamp, category: nil)
                self.modelContext.insert(expense)
            }
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            guard let expenseDict = userInfo["message"] as? [String:Any] else { return }

            guard let name = expenseDict["name"] as? String,
                  let amount = expenseDict["amount"] as? Double,
                  let timestamp = expenseDict["timestamp"] as? Date else { return }

            if let categoryName = expenseDict["category_name"] as? String {

                let category = try? self.modelContext.fetch(FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.name == categoryName })).first

                //Add Expense
                let expense = Expense(name: name, amount: amount, timestamp: timestamp, category: category)
                self.modelContext.insert(expense)
            } else {
                //Add Expense
                let expense = Expense(name: name, amount: amount, timestamp: timestamp, category: nil)
                self.modelContext.insert(expense)
            }
        }
    }
}


