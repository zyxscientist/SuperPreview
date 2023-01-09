//
//  Comp_Temp_Holdings.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/12/28.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Temp_Holdings: View {
    var body: some View {
        ScrollView {
            Text("10号")
            VStack(spacing: 0.0){
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 10)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 10)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 10)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 10)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 10)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 10)
            }
            Text("12号")
            VStack(spacing: 0.0){
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 12)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 12)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 12)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 12)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 12)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 12)
            }
            Text("14号")
            VStack(spacing: 0.0){
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 14)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 14)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 14)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 14)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 14)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 14)
            }
            Text("15号")
            VStack(spacing: 0.0){
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 15)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 15)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 15)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 15)
                Comp_List_Holdings(name: "阿里巴巴", symbol: "09988.HK", fontsize: 15)
                Comp_List_Holdings(name: "腾讯控股", symbol: "00700.HK", fontsize: 15)
            }
        }
        
    }
}

struct Comp_Temp_Holdings_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Temp_Holdings()
    }
}
