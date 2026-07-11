//
//  TemporaryHoldingsView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/12/28.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct TemporaryHoldingsView: View {
    var body: some View {
        ScrollView {
            Text("10号")
            VStack(spacing: 0.0){
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 10)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 10)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 10)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 10)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 10)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 10)
            }
            Text("12号")
            VStack(spacing: 0.0){
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 12)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 12)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 12)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 12)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 12)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 12)
            }
            Text("14号")
            VStack(spacing: 0.0){
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 14)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 14)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 14)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 14)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 14)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 14)
            }
            Text("15号")
            VStack(spacing: 0.0){
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 15)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 15)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 15)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 15)
                HoldingRowView(name: "阿里巴巴", symbol: "09988.HK", fontsize: 15)
                HoldingRowView(name: "腾讯控股", symbol: "00700.HK", fontsize: 15)
            }
        }

    }
}

struct TemporaryHoldingsViewPreviews: PreviewProvider {
    static var previews: some View {
        TemporaryHoldingsView()
    }
}
