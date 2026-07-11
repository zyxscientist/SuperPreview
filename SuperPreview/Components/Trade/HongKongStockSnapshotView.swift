//
//  HongKongStockSnapshotView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/12.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct HongKongStockSnapshotView: View {
    var body: some View {
            VStack(alignment: .center, spacing: 0.0){
                
                SnapshotGroupTitleView(flag_icon: "flag_HK", title: "港股")
                
                VStack(spacing: 0.0) {
                    SnapshotGroupTableHeaderView()
                    SnapshotHoldingGainRowView(name: "腾讯控股", symbol: "00700.HK")
                    SnapshotHoldingGainRowView(name: "汇丰控股", symbol: "00005.HK")
                    SnapshotHoldingGainRowView(name: "阿里巴巴", symbol: "09988.HK")
                    SnapshotHoldingLossRowView(name: "星盛商业", symbol: "06668.US")
                }
                .cornerRadius(13, antialiased: true)
                .padding(.leading, 10)
                .padding(.bottom, 0)
                
                
                
            }
            .background(Color("color-base-1"))
            .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
            .padding(.horizontal, 15)
    }
}

struct HongKongStockSnapshotViewPreviews: PreviewProvider {
    static var previews: some View {
        HongKongStockSnapshotView().environment(\.colorScheme, .dark)
    }
}
