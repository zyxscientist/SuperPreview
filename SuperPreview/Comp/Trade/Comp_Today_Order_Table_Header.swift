//
//  Comp_Today_Order_Table_Header.swift
//  SuperPreview
//
//  Created by admin on 2023/1/13.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Today_Order_Table_Header: View {
    
    var horizontalPadding: Double = 15
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("状态")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .multilineTextAlignment(.leading)
                    .padding(.leading, horizontalPadding)
            }.frame(width: UIScreen.main.bounds.width * 24 / 100, alignment: .leading)
            
            
            
            Text("名称")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color("color-text-60"))
                .frame(width: UIScreen.main.bounds.width * 26 / 100, alignment: .leading)
            
            VStack(alignment: .trailing) {
                Text("委托价")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .padding(.trailing, 21) // 对齐文字而非按钮
            }
            .frame(width: UIScreen.main.bounds.width * 27 / 100, alignment: .trailing)
            
            VStack(alignment: .trailing, spacing: 5.0) {
                Text("数量/成交")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .padding(.trailing, horizontalPadding)
            }
            .frame(width: UIScreen.main.bounds.width * 23 / 100, alignment: .trailing)
            
        }
        .background(Color("color-transparent"))
        .padding(.vertical, 5)
    }
}

struct Comp_Today_Order_Table_Header_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Today_Order_Table_Header()
    }
}
