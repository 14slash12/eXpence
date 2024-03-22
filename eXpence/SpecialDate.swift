//
//  SpecialDate.swift
//  MyExpenses
//
//  Created by David Lin on 09.03.24.
//

import Foundation

struct SpecialDate: Equatable {
    var date: Date
    var type: DateType
}

enum DateType {
    case day
    case week
    case month
}
