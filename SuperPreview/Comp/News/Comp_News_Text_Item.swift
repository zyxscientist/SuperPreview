//
//  Comp_News_Text_Item.swift
//  SuperPreview
//
//  Created by admin on 2021/4/30.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Text_Item: View {
    
    var title : String
    var source : String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(2)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 10)
                
                HStack(spacing: 1.0) {
                    Text("独家")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("color-brand-blue"))
                        .cornerRadius(2)
                        .padding(.trailing, 3)
                    Text("14:20")
                        .font(.system(size: 11))
                        .foregroundColor(Color("color-text-90"))
                        .multilineTextAlignment(.leading)
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundColor(Color("color-text-90"))
                        .multilineTextAlignment(.leading)
                    Text("4/29")
                        .font(.system(size: 11))
                        .foregroundColor(Color("color-text-90"))
                        .multilineTextAlignment(.leading)
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundColor(Color("color-text-90"))
                        .multilineTextAlignment(.leading)
                    Text(source)
                        .font(.system(size: 11))
                        .foregroundColor(Color("color-text-90"))
                        .multilineTextAlignment(.leading)
                }.padding(.bottom, 10).padding(.top, 20)
            
            
            }
            .padding(.leading, 15)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .overlay(Comp_Separator_Justify())
    }
}

struct Comp_News_Text_Item_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Text_Item(title: "美联储议息会议前瞻：美联储或延续鸽派基调", source:"有鱼投研")
            
    }
}
