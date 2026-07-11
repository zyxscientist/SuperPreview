//
//  TradeView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/12.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct TradeView: View {
    var body: some View {

                ScrollView {
                    VStack(spacing: 15.0) {
                            VStack(spacing: 10.0) {
                                TotalAssetView()
                                HeaderTabsView()
                                SnapshotShortcutGridView()
                                HongKongStockSnapshotView()
                                USStockSnapshotView()
                                AShareStockSnapshotView()
                            }
                    }.offset(y:0)
                }
                .background(Color("color-base-0"))
    }
}

struct TradeViewPreviews: PreviewProvider {
    static var previews: some View {
         ZStack {
           Color("color-base-0")
                .edgesIgnoringSafeArea(.all)
            TradeView()
         }
    }
}
