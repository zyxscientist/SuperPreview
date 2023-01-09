//
//  Comp_News_Writer.swift
//  SuperPreview
//
//  Created by admin on 2021/5/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Writer: View {
    var body: some View {
        HStack {
            Text("作者：刘少杰 苏扬")
                .lineSpacing(13.8)
                .font(.system(size: 14))
                .foregroundColor(Color("color-text-90"))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 25)
    }
}

struct Comp_News_Writer_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Writer()
    }
}
