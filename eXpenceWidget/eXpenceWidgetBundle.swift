//
//  eXpenceWidgetBundle.swift
//  eXpenceWidget
//
//  Created by David Lin on 23.03.24.
//

import WidgetKit
import SwiftUI

@main
struct eXpenceWidgetBundle: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        eXpenceWidget()
        eXpenceMonthlyWidget()
    }
}
