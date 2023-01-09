//
//  Comp_IndexBox_With_Graph.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/26.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_IndexBox_With_Graph: View {
    
    var direction : String
    var indexName : String
    var indexPrice : String
    var indexChangeAmount : String
    var indexQuoteChange : String
    var red : Bool
    
    var body: some View {
        VStack(alignment: .leading,spacing: 0.0){
            if direction == "up"{
                Graph_GradientLineChart_UP().padding(.bottom, 8)
            } else {
                Graph_GradientLineChart_DOWN().padding(.bottom, 8)
            }
            Text(indexName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("color-text-30"))
                .padding(.bottom, 5)
            Text(indexPrice)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(red ? Color("color-utility-red"):Color("color-utility-green"))
            HStack {
                Text(indexChangeAmount)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(red ? Color("color-utility-red"):Color("color-utility-green"))
                
                Text(indexQuoteChange)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(red ? Color("color-utility-red"):Color("color-utility-green"))
            }
        }.background(Color("color-transparent"))
    }
}

struct Comp_IndexBox_With_Graph_Previews: PreviewProvider {
    static var previews: some View {
        Comp_IndexBox_With_Graph(direction: "up", indexName: "恒生指数", indexPrice: "23307.55", indexChangeAmount: "+195.99", indexQuoteChange: "+0.88%", red: true)
    }
}
