//
//  Page_Macro_Data_Center.swift
//  SuperPreview
//
//  Created by admin on 2024/10/17.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct Page_Macro_Data_Center: View {
    var body: some View {
        VStack(spacing: 20){
            Comp_Macro_Data_CPI()
            Comp_Macro_Data_PCE()
        }
        .padding(.top, 20)
    }
}

#Preview {
    Page_Macro_Data_Center()
}
