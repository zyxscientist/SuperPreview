//
//  Comp_Snapshot.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/12.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Snapshot_Stock_HK: View {
    var body: some View {
            VStack(alignment: .center, spacing: 0.0){
                
                Comp_Snapshot_Group_Ttile(flag_icon: "flag_HK", title: "港股")
                
                VStack(spacing: 0.0) {
                    Comp_Snapshot_Group_Table_Header()
                    Comp_List_Snapshot_Holdings_Gain(name: "腾讯控股", symbol: "00700.HK")
                    Comp_List_Snapshot_Holdings_Gain(name: "汇丰控股", symbol: "00005.HK")
                    Comp_List_Snapshot_Holdings_Gain(name: "阿里巴巴", symbol: "09988.HK")
                    Comp_List_Snapshot_Holdings_Loss(name: "星盛商业", symbol: "06668.US")
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

struct Comp_Snapshot_Previews_HK: PreviewProvider {
    static var previews: some View {
        Comp_Snapshot_Stock_HK().environment(\.colorScheme, .dark)
    }
}
