//
//  Comp_Separator_Leading.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/10/18.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Separator_Leading: View {
    var body: some View {
        VStack {
            Spacer()
            Rectangle()
                .frame(maxHeight:0.5)
                .foregroundColor(Color("color-separator-10"))
                .padding(.leading,15)
        }
    }
}

struct Comp_Separator_Leading_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Separator_Leading()
    }
}
