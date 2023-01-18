//
//  Page_Trade.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/12.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Page_Trade: View {
    var body: some View {

                ScrollView {
                    VStack(spacing: 15.0) {
                            VStack(spacing: 10.0) {
                                Comp_Total_Asset()
                                Comp_Header_Tabs()
                                Comp_Grid_Snapshot_Shortcut()
                                Comp_Snapshot_Stock_HK()
                                Comp_Snapshot_Stock_US()
                                Comp_Snapshot_Stock_Ashare()
                            }
                    }.offset(y:0)
                }
                .background(Color("color-base-0"))
    }
}

struct Page_Trade_Previews: PreviewProvider {
    static var previews: some View {
         ZStack {
           Color("color-base-0")
                .edgesIgnoringSafeArea(.all)
            Page_Trade()
         }
    }
}
