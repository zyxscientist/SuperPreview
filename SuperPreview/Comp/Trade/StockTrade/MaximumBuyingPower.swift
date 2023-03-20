//
//  MaximumBuyingPower.swift
//  SuperPreview
//
//  Created by admin on 2023/1/12.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct MaximumBuyingPower: View {
    var body: some View {
        VStack{
            HStack(spacing: 0) {
                
                Text("最大购买力")
                    .foregroundColor(Color("color-text-60"))
                    .font(.system(size: 12, weight: .medium, design: .default))
                
                
                    Text("HKD 20,168,098.00")
                        .foregroundColor(Color("color-text-30"))
                        .modifier(CustomFontModifier(size: 12, font: .medium))
                        .padding(.leading, 37)
                
                Spacer()
                
            }.padding(.top, 9)
            Spacer()
        }
        .padding(.leading, 15)
        .frame(width: UIScreen.main.bounds.size.width, height: 35)
        .background(Color("color-base-1"))
        .overlay {
            Comp_Separator_Full()
        }
    }
}

struct MaximumBuyingPower_Previews: PreviewProvider {
    static var previews: some View {
        MaximumBuyingPower()
    }
}
