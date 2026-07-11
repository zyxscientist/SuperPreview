//
//  NewsHeading1View.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct NewsHeading1View: View {
    
    var content: String
    
    var body: some View {
        VStack {
            HStack {
                Text(content)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                
                Spacer()
            }.padding(.horizontal, 15)
        }
        .padding(.top, 0)
        .padding(.bottom, 20)
    }
}

struct NewsHeading1ViewPreviews: PreviewProvider {
    static var previews: some View {
        NewsHeading1View(content: "Heading1")
    }
}
