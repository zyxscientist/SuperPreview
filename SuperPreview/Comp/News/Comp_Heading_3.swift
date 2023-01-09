//
//  Comp_Heading_3.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Heading_3: View {
    
    var content: String
    
    var body: some View {
        VStack {
            HStack {
                Text(content)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                
                Spacer()
            }.padding(.horizontal, 15)
        }
        .padding(.top, 0)
        .padding(.bottom, 20)
    }
}
struct Comp_Heading_3_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Heading_3(content: "Heading3")
    }
}
