//
//  IntraDayCardView.swift
//  SuperPreview
//
//  Created by admin on 2024/9/30.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct IntraDayCardView: View {
    var body: some View {
        ScrollView{
            
            HStack{
                Comp_IntraDayCard(index_name: "道琼斯", utility_color:Color(.colorUtilityRed))
                Comp_IntraDayCard(index_name: "纳斯达克", utility_color:Color(.colorUtilityRed))
                Comp_IntraDayCard(index_name: "标普500", utility_color:Color(.colorUtilityRed))
            }
            .padding(.top, 10)
            .padding(.horizontal, 15)
            .ignoresSafeArea(.all)
            
        }
        .background(Color(.colorBase0))
    }

}

#Preview {
    IntraDayCardView()
}
