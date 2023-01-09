//
//  Comp.swift
//  SuperPreview
//
//  Created by admin on 2021/6/18.
//  Copyright © 2021 PeterZ. All rights reserved.
//
import SwiftUI

struct Comp_Snapshot_Stock_US: View {
    
    
    var body: some View {
            VStack(alignment: .center, spacing: 0.0){
               
                Comp_Snapshot_Group_Ttile(flag_icon: "flag_US", title: "美股")
                
                VStack(spacing: 0.0) {
                    Comp_Snapshot_Group_Table_Header()
                    Comp_List_Snapshot_Holdings_Gain(name: "爱马仕(ADR)", symbol: "HESAY.US")
                    Comp_List_Snapshot_Holdings_Loss(name: "Louis Vuitton MH", symbol: "LVMHF.US")
                    Comp_List_Snapshot_Holdings_Gain(name: "特斯拉", symbol: "TSLA.US")
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

struct Comp_Snapshot_Previews_US: PreviewProvider {
    static var previews: some View {
        Comp_Snapshot_Stock_US().environment(\.colorScheme, .dark)
    }
}
