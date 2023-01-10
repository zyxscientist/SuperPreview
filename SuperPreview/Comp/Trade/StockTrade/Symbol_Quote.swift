//
//  Symbol_Quote.swift
//  SuperPreview
//
//  Created by admin on 2023/1/10.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Symbol_Quote: View {
    
    @Binding var openGraphView: Bool
    
    var body: some View {
        VStack{
            HStack(spacing: 0) {
                
                Text("云锋金融")
                    .foregroundColor(Color("color-text-30"))
                    .font(.system(size: 12, weight: .medium, design: .default))
                
                HStack(spacing: 5) {
                    Text("16.990")
                        .foregroundColor(Color("color-utility3-red"))
                        .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                    Text("+1.210")
                        .foregroundColor(Color("color-utility3-red"))
                        .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                    Text("+8.41%")
                        .foregroundColor(Color("color-utility3-red"))
                        .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                }.padding(.leading, 49)
                
                Spacer()
                
                Image("chevron_down_filled_sm")
                    .rotationEffect(.degrees(openGraphView ? -180 : 0))
                    .transaction { view in
                        view.animation = .interactiveSpring(
                            response: 0.40,
                            dampingFraction: 1,
                            blendDuration: 10)
                    }
                    .padding(.trailing, 22)
            }.padding(.top, 9)
            Spacer()
        }
        .padding(.leading, 15)
        .frame(width: UIScreen.main.bounds.size.width,height: 35)
        .background(Color("color-base-1"))
        .overlay {
            Comp_Separator_Full()
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 1, blendDuration: 0.8))  {
                openGraphView.toggle()
            }
        }
    }
}

struct Symbol_Quote_Previews: PreviewProvider {
    static var previews: some View {
        Symbol_Quote(openGraphView: .constant(false)) // constant 来维持正常预览
    }
}
