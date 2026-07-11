//
//  IndexSnapshotBoxProView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/27.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct IndexSnapshotBoxProView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(alignment: .center, spacing: 0.0) {
                IndexGraphBoxView(direction: "down", indexName: "恒生指数", indexPrice: "25477.89", indexChangeOrderAmountView: "-294.23", indexQuoteChange: "1.42%", red: false)
                Spacer()
                IndexGraphBoxView(direction: "up", indexName: "国企指数", indexPrice: "10407.89", indexChangeOrderAmountView: "+294.23", indexQuoteChange: "0.12%", red: true)
                Spacer()
                IndexGraphBoxView(direction: "up", indexName: "红筹指数", indexPrice: "25477.89", indexChangeOrderAmountView: "+294.23", indexQuoteChange: "0.42%", red: true)

            }.padding(.top, 15).padding(.horizontal, 15)
            IndicatorView()
        }
        .frame(minWidth: 375, maxWidth: .infinity, minHeight: 123).background(Color("color-base-1"))
        .overlay(FullWidthSeparatorView())
    }
}

struct IndexSnapshotBoxProViewPreviews: PreviewProvider {
    static var previews: some View {
        IndexSnapshotBoxProView()
            .preferredColorScheme(.light)
    }
}
