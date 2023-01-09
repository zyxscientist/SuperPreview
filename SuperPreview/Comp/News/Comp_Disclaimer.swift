//
//  Comp_Disclaimer.swift
//  SuperPreview
//
//  Created by admin on 2021/4/30.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Disclaimer: View {
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 3.0) {
                Text("来源: 新浪财经 本文版权归原作者/机构所有 ")
                    .font(.system(size: 12))
                    .foregroundColor(Color("color-text-30"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                Text("文章内容仅代表作者观点，与云锋有鱼立场无关。本文仅供投资参考，亦不构成任何投资建议。为了提供更好的阅读体验，云锋有鱼对原网页版式进行了优化调整，您可以通过选择「原始网页」切换至源网页。如对云锋有鱼提供的“阅读模式”服务有任何疑问或建议，欢迎联系：editorial_center@yff.com")
                    .font(.system(size: 12))
                    .foregroundColor(Color("color-text-90"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                
            }.padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        }
        .background(Color("color-scale-1"))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 13)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
}

struct Comp_Disclaimer_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Disclaimer()
    }
}
