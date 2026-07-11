//
//  USStockSnapshotView.swift
//  SuperPreview
//
//  Created by admin on 2021/6/18.
//  Copyright © 2021 PeterZ. All rights reserved.
//
import SwiftUI

struct USStockSnapshotView: View {
    
    
    var body: some View {
            VStack(alignment: .center, spacing: 0.0){
               
                SnapshotGroupTitleView(flag_icon: "flag_US", title: "美股")
                
                VStack(spacing: 0.0) {
                    SnapshotGroupTableHeaderView()
                    SnapshotHoldingGainRowView(name: "爱马仕(ADR)", symbol: "HESAY.US")
                    SnapshotHoldingLossRowView(name: "Louis Vuitton MH", symbol: "LVMHF.US")
                    SnapshotHoldingGainRowView(name: "特斯拉", symbol: "TSLA.US")
                }
                .cornerRadius(13, antialiased: true)
                .padding(.leading, 10)
                .padding(.bottom, 0)
                
                
            }
            .background(Color("color-base-1"))
            .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
            .padding(.horizontal, 15)
            .clipped()
    }
}

struct USStockSnapshotViewPreviews: PreviewProvider {
    static var previews: some View {
        USStockSnapshotView().environment(\.colorScheme, .dark)
    }
}
