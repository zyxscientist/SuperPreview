//
//  Comp_Indicator.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/27.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Indicator: View {
    var body: some View {
        HStack(spacing: 5.0) {
            Capsule().frame(width: 10, height: 3).foregroundColor(Color("color-text-30"))
            Capsule().frame(width: 5, height: 3).foregroundColor(Color("color-text-90"))
            Capsule().frame(width: 5, height: 3).foregroundColor(Color("color-text-90"))
        }.frame(minWidth: 375,maxWidth: .infinity, minHeight: 20, maxHeight: 20)
    }
}

struct Comp_Indicator_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Indicator()
            
    }
}
