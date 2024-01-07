//
//  Page_Stock_Quoto_Detail.swift
//  SuperPreview
//
//  Created by admin on 2023/1/18.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Page_Stock_Quoto_Detail: View {
    
    @State var openTagGroup: Bool = false
    @State var openMask: Bool = false
    
    var body: some View {
        VStack{
            ZStack(alignment:.top){
                Image("price_block")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.8))  {
                            openTagGroup.toggle()
                        }
                        openMask.toggle()
                    }
                
                Rectangle()
                    .opacity(openMask ? 0.1 : 0)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.8))  {
                            openTagGroup.toggle()
                        }
                        openMask.toggle()
                    }
                
                
                HStack{
                    Image("tag_group_dialog")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, openTagGroup ? 55 : 45)
                    .opacity(openTagGroup ? 1 : 0)
                    .blur(radius: openTagGroup ? 0 : 2)
                    .clipped()

            }
            
            Spacer()
        }
    }
}

struct Page_Stock_Quoto_Detail_Previews: PreviewProvider {
    static var previews: some View {
        Page_Stock_Quoto_Detail()
    }
}

// .blur(radius: openGraphView ? 0 : 3)
