//
//  Comp_Snapshot_Group_Table_Header.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/12.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Snapshot_Group_Table_Header: View {
    var body: some View {
        HStack(spacing: 2.0) {
            VStack(alignment: .leading) {
                Text("名称")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .multilineTextAlignment(.leading)
            }.frame(width: 110, height: 17, alignment: .leading)
            
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    VStack(alignment: .trailing) {
                        Text("市值/持有")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("color-text-60"))
                    }
                    .frame(width: 86, height: 17, alignment: .trailing)
            
            VStack(alignment: .trailing) {
                Text("现价/成本")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
            }
            .frame(width: 76, height: 17, alignment: .trailing)
            
            VStack(alignment: .trailing, spacing: 5.0) {
                Text("今日盈亏")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
            }
            .frame(width: 84, height: 17, alignment: .trailing)
            
            VStack(alignment: .trailing, spacing: 5.0) {
                Text("总盈亏")
                    .padding(.trailing, 10)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
            }
            .frame(width: 94, height: 17, alignment: .trailing)
                }
            }
            
        }
        .background(Color("color-transparent"))
        .padding(.vertical, 4)
    }
}

struct Comp_Snapshot_Group_Table_Header_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Snapshot_Group_Table_Header()
    }
}
