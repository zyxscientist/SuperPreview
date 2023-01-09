//
//  Comp_Separator_Justify.swift
//  SuperPreview
//
//  Created by admin on 2021/4/30.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Separator_Justify: View  {
    var body: some View {
        VStack() {
            Spacer()
            Rectangle()
                .frame(minHeight: 0.5, maxHeight:0.5)
                .foregroundColor(Color("color-separator-10"))
                .padding(.horizontal, 15)
        }
    }
}

struct Comp_Separator_Justify_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Separator_Justify()
    }
}
