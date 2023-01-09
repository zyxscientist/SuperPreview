//
//  Comp_News_Carousel.swift
//  SuperPreview
//
//  Created by admin on 2021/5/7.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Carousel: View {
    var body: some View {
        ZStack {
            HStack {
                Image("fake_carousel")
                    .resizable()
                    .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    .cornerRadius(8)
            }
                .padding(.horizontal, 15)
            .frame(maxHeight: 168)
            
            VStack(alignment: .leading, spacing: 5.0) {
                Text("苹果(AAPL.US)造车或成为特斯拉(TSLA.US)重大利空，维持目标价880美元")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.white))
                    .lineLimit(2)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 1.0) {
                    
                    Text("14:20")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.white))
                        .lineLimit(2)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                    
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.white))
                        .multilineTextAlignment(.leading)
                    
                    Text("有鱼投研")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.white))
                        .multilineTextAlignment(.leading)
                    
                    }
                }
                .offset(y:45)
                .padding(.horizontal, 25)
            
            HStack {
                Text("独家")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(.white))
                    .frame(minWidth: 0, maxWidth: 36, maxHeight: 18)
                    .background(Color("color-brand-blue"))
                    .cornerRadius(4)
                
                Spacer()
                }
                .offset(y:-70)
                .padding(.horizontal, 25)
        }.padding(.top, 20).padding(.bottom, 5)

    }
}

struct Comp_News_Carousel_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Carousel()
    }
}
