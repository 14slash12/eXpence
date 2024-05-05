//
//  eXpenceWidgetBundle.swift
//  eXpenceWidget
//
//  Created by David Lin on 23.03.24.
//

import WidgetKit
import SwiftUI
import RevenueCat

@main
struct eXpenceWidgetBundle: WidgetBundle {

    init() {
        Purchases.configure(with:
            Configuration.Builder(withAPIKey: "appl_qEGalBcGAGTVeiEvhEcbFZrDvlc")
                    .with(userDefaults: .init(suiteName: "group.com.apperium.Xpenses")!)
                    .build()
        )
    }


    @WidgetBundleBuilder
    var body: some Widget {
        eXpenceWidget()
        eXpenceMonthlyWidget()
    }
}
