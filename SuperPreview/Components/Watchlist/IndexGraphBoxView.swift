//
//  IndexGraphBoxView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/26.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct IndexGraphBoxView: View {
    
    var direction : String
    var indexName : String
    var indexPrice : String
    var indexChangeOrderAmountView : String
    var indexQuoteChange : String
    var red : Bool
    
    var body: some View {
        VStack(alignment: .leading,spacing: 0.0){
            if direction == "up"{
                UpGradientLineChartView().padding(.bottom, 8)
            } else {
                DownGradientLineChartView().padding(.bottom, 8)
            }
            Text(indexName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("color-text-30"))
                .padding(.bottom, 5)
            Text(indexPrice)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(red ? Color("color-utility-red"):Color("color-utility-green"))
            HStack {
                Text(indexChangeOrderAmountView)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(red ? Color("color-utility-red"):Color("color-utility-green"))
                
                Text(indexQuoteChange)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(red ? Color("color-utility-red"):Color("color-utility-green"))
            }
        }.background(Color("color-transparent"))
    }
}

struct IndexGraphBoxViewPreviews: PreviewProvider {
    static var previews: some View {
        IndexGraphBoxView(direction: "up", indexName: "恒生指数", indexPrice: "23307.55", indexChangeOrderAmountView: "+195.99", indexQuoteChange: "+0.88%", red: true)
    }
}
