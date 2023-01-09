//
//  Comp_Evening_Sum_Clip.swift
//  SuperPreview
//
//  Created by 朱宇軒 on 2021/11/18.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Evening_Sum_Clip: View {
    var body: some View {
        HStack(spacing: 0) {
            
            Image("date")
                .padding(.leading, 0)
                .padding(.top, 0)
                .padding(.bottom, 0)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 0.0) {
                HStack {
                    Image("sun")
                    Text("有鱼晚报 | 股市日历")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("color-text-60"))
                }
                .padding(.bottom, 0)
                
                Text("美国商务部长罗斯：贸易战并不新鲜，美国准备好了")
                    .frame(minWidth: 265,alignment: .leading)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("color-text-30"))
                    .padding(.top, 10)
            }

        }
        .padding(.horizontal, 15)
        .frame(minWidth: 375, maxWidth: .infinity, maxHeight: 110)
        .background(Color("color-base-1"))
    }
}

struct Comp_Evening_Sum_Clip_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Evening_Sum_Clip().previewLayout(.sizeThatFits)
    }
}
