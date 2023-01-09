//
//  Comp_News_Text_Image_Item.swift
//  SuperPreview
//
//  Created by admin on 2021/4/30.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Text_Image_Item: View {
    
    var title : String
    var source : String
    var image_name : String
    
    var body: some View {
        HStack(spacing: 0.0) {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(2)
                    .lineSpacing(3)
                    .padding(.top, 10)
                    .frame(minWidth: 220)
                    .padding(.leading, 0)
                    .padding(.trailing, 0)
                    .padding(.bottom, 5)
                
                
                HStack(spacing: 1.0) {
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
                }.padding(.bottom, 10).padding(.top, 20).padding(.leading, 0)
            
            
            }
            .padding(.leading, 15)
            .padding(.bottom, 0)
            
            Spacer()
            
            Image(image_name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 105, height: 80)
                .cornerRadius(8)
                .clipped()
                .padding(.trailing, 15)
                .padding(.leading, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
            
        }
        .frame(minWidth: 375, maxWidth: .infinity, maxHeight: 100)
        .overlay(Comp_Separator_Justify())
    }
}

struct Comp_News_Text_Image_Item_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Text_Image_Item(title: "中国4月官方制造业PMI 51.1，高于2019年和2020年同期水平", source:"有鱼资讯", image_name: "tesla")
    }
}
