//
//  WatchViewModel.swift
//  eXpenceWatch Watch App
//
//  Created by David Lin on 29.03.24.
//

import Foundation
import WatchConnectivity
import SwiftData

class WatchViewModel: NSObject,  WCSessionDelegate, ObservableObject {
    var modelContext: ModelContext

    @Published var categories: [String] = []

    var session: WCSession
    @Published var messageText = 0 /*CustomText(name: "", message: [])*/
    init(session: WCSession = .default, modelContext: ModelContext) {
        self.session = session
        self.modelContext = modelContext
        super.init()
        self.session.delegate = self
        session.activate()
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard let dictType = message["message"] as? [String:Any] else { return }

            guard let name = dictType["name"] as? String, let message = dictType["message"] as? [String] else { return }

//            self.messageText = CustomText(name: name, message: message)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            if let categories = userInfo["categories"] as? [String] {
                do {
                    let currentCategories = try self.modelContext.fetch(FetchDescriptor<ExpenseCategory>())
                    
                    // Add categories which are on the phone    
                    for category in categories {
                        if !currentCategories.contains(where: { $0.name == category }) {
                            let newCategory = ExpenseCategory(name: category, symbol: "")
                            self.modelContext.insert(newCategory)
                        }
                    }

                    // Delete categories which are no longer on the phone
                    for category in currentCategories {
                        if !categories.contains(where: { $0 == category.name }) {
                            self.modelContext.delete(category)
                        }
                    }

                    self.categories = categories
                } catch {
                    print("ERROR: Fetching all categories")
                }
            }

            if let dailyAmount = userInfo["dailyAmount"] as? String {
                
            }

//            guard let name = dictType["name"] as? String, let message = dictType["message"] as? [String] else { return }


        }
    }
}
