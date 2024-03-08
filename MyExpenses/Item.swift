//
//  Item.swift
//  MyExpenses
//
//  Created by David Lin on 08.03.24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
