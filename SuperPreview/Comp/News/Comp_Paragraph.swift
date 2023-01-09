//
//  Comp_Paragraph.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Paragraph: View {
    
    var content : String
    var fontsize : CGFloat
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text(content)
                    .lineSpacing(13.8)
                    .font(.system(size: fontsize))
                    .foregroundColor(Color("color-text-30"))
                    .multilineTextAlignment(.leading)
            }.padding(.horizontal, 15)
        }
        .padding(.top, 0)
        .padding(.bottom, 25)
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct Comp_Paragraph_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Paragraph(content: "摩根士丹利发表研究报告表示，苹果(AAPL.US)造车将成为特斯拉(TSLA.US)重大利空，维持对后者目标价880美元。\n\n分析师Adam Jonas表示:“如果苹果进入电动汽车市场，其占据的市场份额更有可能是33%，而非微弱的3%。绝大多数客户都认为，在未来5到10年，传统OEM将是特斯拉的主要竞争对手。尽管正当的市场竞争都应该得到尊重，但苹果等公司进军新能源汽车行业将给特斯拉带来前所未有的竞争压力，”Jonas补充道。", fontsize: 18)
    }
}
