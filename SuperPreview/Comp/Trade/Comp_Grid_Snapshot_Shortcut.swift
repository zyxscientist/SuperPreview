//
//  Comp_Grid_Snapshot_Shortcut.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/12.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Grid_Snapshot_Shortcut: View {
    var body: some View {
        VStack(spacing: 0.0) {
            
            Comp_Asset_Snapshot_Header(market: "股票")
            
            HStack {
                NavigationLink {
                    Page_Stock_Trade()
                } label: {
                    VStack(spacing: 10.0){
                        Image("trade_fill")
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                        Text("交易")
                            .foregroundColor(Color("color-text-30"))
                            .font(.system(size: 12, weight: .regular))
                            .frame(maxWidth: 375)
                    }
                    .frame(maxWidth: 375, maxHeight: 75)
                }
                
                NavigationLink(destination: EmptyView()) {
                    EmptyView()
                }
                
                VStack(spacing: 10.0){
                    Image("his_fill")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                    Text("今日订单")
                        .foregroundColor(Color("color-text-30"))
                        .font(.system(size: 12, weight: .regular))
                        .frame(maxWidth: 375)
                    }
                    .frame(maxWidth: 375, maxHeight: 75)
                
                VStack(spacing: 10.0){
                    Image("ipo_fill")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                    Text("新股中心")
                        .foregroundColor(Color("color-text-30"))
                        .font(.system(size: 12, weight: .regular))
                        .frame(maxWidth: 375)
                }
                .frame(maxWidth: 375, maxHeight: 75)
                
                VStack(spacing: 10.0){
                    Image("deposit_fill")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                    Text("入金")
                        .foregroundColor(Color("color-text-30"))
                        .font(.system(size: 12, weight: .regular))
                        .frame(maxWidth: 375)
                }
                .frame(maxWidth: 375, maxHeight: 75)
                
                VStack(spacing: 10.0){
                    Image("more_fill")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                    Text("更多")
                        .foregroundColor(Color("color-text-30"))
                        .font(.system(size: 12, weight: .regular))
                        .frame(maxWidth: 375)
                   }
                        .frame(maxWidth: 375, maxHeight: 75)
            }.padding(.top, 12)
        }
        .frame(minWidth: 345, minHeight: 134)
        .background(Color("color-base-1"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 15)
    }
}

struct Comp_Grid_Snapshot_Shortcut_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Grid_Snapshot_Shortcut()
            .preferredColorScheme(.dark)
    }
}
