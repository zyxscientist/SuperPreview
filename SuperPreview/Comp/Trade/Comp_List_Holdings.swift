//
//  Comp_List_Holdings.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/12/28.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_List_Holdings: View {
    
    var name : String
    var symbol : String
    var fontsize : CGFloat
    
    var body: some View {
        HStack(spacing: 0.0) {
            VStack(alignment: .leading, spacing: 5.0) {
                Text(name)
                    .font(.system(size: fontsize, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                Text(symbol)
                    .font(.system(size: fontsize, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                }
            Spacer()

            VStack(alignment: .trailing, spacing: 5.0) {
                Text("8,888.88")
                    .font(.system(size: fontsize, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                Text("100")
                    .font(.system(size: fontsize, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                
            }.padding(.trailing, 32)
            
            VStack(alignment: .trailing, spacing: 5.0) {
                Text("343.000")
                    .font(.system(size: fontsize, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                Text("323.000")
                    .font(.system(size: fontsize, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                
            }.padding(.trailing, 15)
            VStack(alignment: .trailing, spacing: 5.0) {
                Text("+11,275.00")
                    .font(.system(size: fontsize, weight: .semibold))
                    .foregroundColor(Color("color-utility-red"))
                Text("+41.83%")
                    .font(.system(size: fontsize, weight: .semibold))
                    .foregroundColor(Color("color-utility-red"))
                
            }.padding(.leading, 0)
        }
        .background(Color("color-transparent"))
        .padding(15)
        .overlay(Comp_Separator_Full())
    }
}

struct Comp_List_Holdings_Previews: PreviewProvider {
    static var previews: some View {
        Comp_List_Holdings(name: "苹果", symbol: "AAPL.US", fontsize: 14)
    }
}
