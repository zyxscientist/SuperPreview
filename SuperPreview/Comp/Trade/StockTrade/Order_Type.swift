//
//  Order_Type.swift
//  SuperPreview
//
//  Created by admin on 2023/1/10.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Order_Type: View {
    var body: some View {
        HStack(spacing: 0) {
            
            Text("订单类型")
                .foregroundColor(Color("color-text-60"))
                .font(.system(size: 16, weight: .regular, design: .default))
            
            Text("增强限价交易")
                .padding(.leading, 33)
                .foregroundColor(Color("color-text-30"))
                .modifier(CustomFontModifier(size: 16, font: .medium))
            
            Spacer()
            
            Image("chevron_down_filled_sm")
                .padding(.trailing, 22)
            
        }
        .padding(.leading, 15)
        .frame(width: UIScreen.main.bounds.size.width,height: 44)
        .background(Color("color-base-1"))
        .overlay {
            Comp_Separator_Full()
        }
    }
}

struct Order_Type_Previews: PreviewProvider {
    static var previews: some View {
        Order_Type().previewLayout(.sizeThatFits)
    }
}
