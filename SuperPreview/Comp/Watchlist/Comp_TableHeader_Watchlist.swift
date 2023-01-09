//
//  Comp_TableHeader_Watchlist.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/10/18.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_TableHeader_Watchlist: View {
    var key_col : String
    var first_col : String
    var second_col : String
    
    var body: some View {
        HStack(alignment: .center, spacing: 0.0) {
            Text(key_col)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color("color-text-60"))
                .padding(.leading ,15)
            Spacer()
            HStack(spacing: 0.0) {
                Text(first_col)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .padding(.trailing, 5)
                Image("Glyph_Sort")
            }.padding(.trailing, 34)
            HStack(spacing: 0.0) {
                Text(second_col)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .padding(.trailing, 5)
                    Image("Glyph_Sort")
            }.padding(.trailing, 11)
        }
        .frame(minHeight: 36,maxHeight: 36)
        .background(Color("color-base-1"))
        .overlay(Comp_Separator_Full())
    }
}

struct Comp_TableHeader_Two_Col_Previews: PreviewProvider {
    static var previews: some View {
        Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
    }
}
