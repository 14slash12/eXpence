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

    init() {
        Purchases.shared.getCustomerInfo { customerInfo, error in
//            self.isSubscriptionActive = customerInfo?.entitlements.all["Pro"]?.isActive == true
            self.isSubscriptionActive = true
        }
    }
}
