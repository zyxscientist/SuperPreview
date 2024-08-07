//
//  Comp-List-Snapshot-Holdings.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/8.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_List_Snapshot_Holdings_Gain: View {
    
    var name : String
    var symbol : String
    
    var body: some View {
        HStack(spacing: 2.0) {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("color-text-30"))
                    .frame(width: 110, height: 20, alignment: .leading)
                Text(symbol)
                    .modifier(CustomFontModifier(size: 14, font: .medium))
                    .foregroundColor(Color("color-text-60"))
                    .frame(width: 110, height: 20, alignment: .leading)
                }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    VStack(alignment: .trailing, spacing: 0.0) {
                        Text("191,143.00")
                            .modifier(CustomFontModifier(size: 14, font: .medium))
                            .foregroundColor(Color("color-text-30"))
                            .frame(width: 86, height: 20, alignment: .trailing)
                        Text("200,000")
                            .modifier(CustomFontModifier(size: 14, font: .medium))
                            .foregroundColor(Color("color-text-30"))
                            .frame(width: 86, height: 20, alignment: .trailing)
                        
                    }
                VStack(alignment: .trailing, spacing: 0.0) {
                    Text("126.200")
                        .modifier(CustomFontModifier(size: 14, font: .medium))
                        .foregroundColor(Color("color-text-30"))
                        .frame(width: 76, height: 20, alignment: .trailing)
                    Text("8.110")
                        .modifier(CustomFontModifier(size: 14, font: .medium))
                        .foregroundColor(Color("color-text-30"))
                        .frame(width: 76, height: 20, alignment: .trailing)
                    
                }
                
                VStack(alignment: .trailing, spacing: 0.0) {
                    Text("+1,111.88")
                        .modifier(CustomFontModifier(size: 14, font: .medium))
                        .foregroundColor(Color("color-utility-red"))
                        .frame(width: 84, height: 20, alignment: .trailing)
                    Text("+11.83%")
                        .modifier(CustomFontModifier(size: 14, font: .medium))
                        .foregroundColor(Color("color-utility-red"))
                        .frame(width: 84, height: 20, alignment: .trailing)
                }
                
                VStack(alignment: .trailing, spacing: 0.0) {
                    Text("+1,000.88")
                        .padding(.trailing, 10)
                        .modifier(CustomFontModifier(size: 14, font: .medium))
                        .foregroundColor(Color("color-utility-red"))
                        .frame(width: 96, height: 20, alignment: .trailing)
                    Text("+5.83%")
                        .padding(.trailing, 10)
                        .modifier(CustomFontModifier(size: 14, font: .medium))
                        .foregroundColor(Color("color-utility-red"))
                        .frame(width: 95, height: 20, alignment: .trailing)
                    }
                }
            }
        }
        .background(Color("color-transparent"))
        .padding(.vertical, 7)
        .padding(.horizontal ,0)
    }//
}

struct Comp_List_Snapshot_Holdings_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Comp_List_Snapshot_Holdings_Gain(name: "苹果", symbol: "AAPL.US").previewLayout(.sizeThatFits)
            
            Comp_List_Snapshot_Holdings_Gain(name: "苹果", symbol: "AAPL.US")
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
        }
    }
}
