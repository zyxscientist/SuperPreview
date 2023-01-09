//
//  Comp_News_Quote.swift
//  SuperPreview
//
//  Created by admin on 2021/5/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Quote: View {
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 0.0) {
                Rectangle()
                    .frame(width: 3, height: 180, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                Text("“对苹果和特斯拉来说，Jonas及其团队认为，其价值在于移动生态系统，尤其是数据和网络的价值，这超出了对特斯拉的正常销售单位与股价的分析。” -- Catherine Wood")
                    .lineSpacing(13.8)
                    .font(.system(size: 20))
                    .foregroundColor(Color("color-text-60"))
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 15)
            }
        }
        .padding(.top, 0)
        .padding(.bottom, 40)
        .padding(.horizontal, 13)
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct Comp_News_Quote_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Quote()
    }
}
