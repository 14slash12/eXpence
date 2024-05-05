//
//  UserViewModel.swift
//  eXpence
//
//  Created by David Lin on 24.03.24.
//

import Foundation
import RevenueCat

class UserViewModel: ObservableObject {
    @Published var isSubscriptionActive = false

    var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    init() {
        if !isPreview {
            Purchases.shared.getCustomerInfo { customerInfo, error in
                self.isSubscriptionActive = customerInfo?.entitlements.all["Pro"]?.isActive == true

            }
        }
    }
}
