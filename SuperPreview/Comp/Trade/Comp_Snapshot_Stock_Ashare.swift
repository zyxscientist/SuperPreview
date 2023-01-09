//
//  Comp_Snapshot_Stock_Ashare.swift
//  SuperPreview
//
//  Created by admin on 2021/6/18.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Snapshot_Stock_Ashare: View {
    var body: some View {
            VStack(alignment: .center, spacing: 0.0){
                
                Comp_Snapshot_Group_Ttile(flag_icon: "flag_CN", title: "A股")
            
                VStack(spacing: 0.0) {
                    Comp_Snapshot_Group_Table_Header()
                    Comp_List_Snapshot_Holdings_Gain(name: "海天味业", symbol: "603288.SH")
                    Comp_List_Snapshot_Holdings_Gain(name: "贵州茅台", symbol: "603288.HK")
                }
                .cornerRadius(10, antialiased: true)
                .padding(.leading, 10)
                .padding(.bottom, 0)
                
                
            }
            .background(Color("color-base-1"))
            .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
            .padding(.horizontal, 15)
    }
}

struct Comp_Snapshot_Previews_Ashare: PreviewProvider {
    static var previews: some View {
        Comp_Snapshot_Stock_Ashare().environment(\.colorScheme, .dark)
    }
}
