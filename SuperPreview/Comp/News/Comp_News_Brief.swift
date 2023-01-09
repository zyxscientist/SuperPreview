//
//  Comp_News_Brief.swift
//  SuperPreview
//
//  Created by admin on 2021/5/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Brief: View {
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20.0) {
                Text("云锋导读")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                
                Text("1.摩根士丹利发表研究报告表示，苹果(AAPL.US)造车将成为特斯拉(TSLA.US)重大利空，维持对后者目标价880美元。")
                    .lineSpacing(5.8)
                    .font(.system(size: 16))
                    .foregroundColor(Color("color-text-30"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                Text("2.摩根士丹利发表研究报告表。")
                    .lineSpacing(5.8)
                    .font(.system(size: 16))
                    .foregroundColor(Color("color-text-30"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                Text("3.分析师Adam Jonas表示:“如果苹果进入电动汽车市场，其占据的市场份额更有可能是33%，而非微弱的3%。")
                    .lineSpacing(5.8)
                    .font(.system(size: 16))
                    .foregroundColor(Color("color-text-30"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                
            }
            .padding(.horizontal, 15)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .background(Color("color-scale-1"))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 13)
        .padding(.top, 0)
        .padding(.bottom, 40)
    }
}


struct Comp_News_Brief_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Brief()
    }
}
