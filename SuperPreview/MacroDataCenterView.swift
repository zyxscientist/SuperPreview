//
//  MacroDataCenterView.swift
//  SuperPreview
//
//  Created by admin on 2024/10/17.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct MacroDataCenterView: View {
    var body: some View {
        VStack(spacing: 20){
            MacroDataCPIView()
            MacroDataPCEView()
        }
        .padding(.top, 20)
    }
}

#Preview {
    MacroDataCenterView()
}
