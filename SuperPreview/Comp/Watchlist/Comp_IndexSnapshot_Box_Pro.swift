//
//  Comp_IndexSnapshot_Box_Pro.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/27.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_IndexSnapshot_Box_Pro: View {
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(alignment: .center, spacing: 0.0) {
                Comp_IndexBox_With_Graph(direction: "down", indexName: "恒生指数", indexPrice: "25477.89", indexChangeAmount: "-294.23", indexQuoteChange: "1.42%", red: false)
                Spacer()
                Comp_IndexBox_With_Graph(direction: "up", indexName: "国企指数", indexPrice: "10407.89", indexChangeAmount: "+294.23", indexQuoteChange: "0.12%", red: true)
                Spacer()
                Comp_IndexBox_With_Graph(direction: "up", indexName: "红筹指数", indexPrice: "25477.89", indexChangeAmount: "+294.23", indexQuoteChange: "0.42%", red: true)
                    
            }.padding(.top, 15).padding(.horizontal, 15)
            Comp_Indicator()
        }
        .frame(minWidth: 375, maxWidth: .infinity, minHeight: 123).background(Color("color-base-1"))
        .overlay(Comp_Separator_Full())
    }
}

struct Comp_IndexSnapshot_Box_Pro_Previews: PreviewProvider {
    static var previews: some View {
        Comp_IndexSnapshot_Box_Pro()
            .preferredColorScheme(.light)
    }
}
