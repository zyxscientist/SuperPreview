//
//  Price_Inputfield.swift
//  SuperPreview
//
//  Created by admin on 2023/1/11.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Price_Inputfield: View {
    
    @EnvironmentObject var priceQuantityViewModel: PriceQuantityViewModel
    @Binding var priceTargetingMenu: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            
            Text("价格")
                .foregroundColor(Color("color-text-60"))
                .font(.system(size: 16, weight: .regular, design: .default))
            
            HStack(spacing:0){
                Image("decrease_normal")
                    .padding(.trailing, 10)
                    .onTapGesture {
                        priceQuantityViewModel.decreasePrice()
                        priceQuantityViewModel.getAmount()
                        HapticManager.instance.impactHaptic(type: .medium)
                    }
                Text("\(priceQuantityViewModel.price.formatted())")
                    .foregroundColor(Color("color-text-30"))
                    .modifier(CustomFontModifier(size: 16, font: .medium))
            }.padding(.leading, 65)
            
            Spacer()
            
            HStack(spacing: 0) {
                Image("increase_normal")
                    .padding(.trailing, 10)
                    .onTapGesture {
                        priceQuantityViewModel.increasePrice()
                        priceQuantityViewModel.getAmount()
                        HapticManager.instance.impactHaptic(type: .medium)
                    }
                
                Image(priceTargetingMenu ? "price_targeting_active" : "price_targeting_inactive")
                    .overlay {
                        PriceTargetingMenu()
                            .opacity(priceTargetingMenu ? 1 : 0)
                            .blur(radius: priceTargetingMenu ? 0 : 4)
                            .scaleEffect(priceTargetingMenu ? 1 : 0, anchor: .topTrailing)
                            .offset(x:-29 , y: 105)
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 1, blendDuration: 0.8)){
                                priceTargetingMenu.toggle()
                        }
                        HapticManager.instance.impactHaptic(type: .medium)
                    }
            }
            
        }
        .padding(.horizontal, 15)
        .frame(width: UIScreen.main.bounds.size.width,height: 44)
        .background(Color("color-base-1"))
        .overlay {
            Comp_Separator_Full()
        }
    }
}

struct Price_Inputfield_Previews: PreviewProvider {
    static var previews: some View {
        Price_Inputfield(priceTargetingMenu: .constant(false))
    }
}

struct PriceTargetingMenu: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("指定价")
                .foregroundColor(Color("color-brand-blue"))
                .frame(width: 88, height: 40)
                .overlay {
                    Comp_Separator_Full()
                }
            Text("跟市价")
                .foregroundColor(Color("color-text-30"))
                .frame(width: 88, height: 40)
                .overlay {
                    Comp_Separator_Full()
                }
            Text("跟买一")
                .foregroundColor(Color("color-text-30"))
                .frame(width: 88, height: 40)
                .overlay {
                    Comp_Separator_Full()
                }
            Text("跟卖一")
                .foregroundColor(Color("color-text-30"))
                .frame(width: 88, height: 40)
        }
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
        .overlay( // 再次叠加
            RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                .stroke(Color("color-separator-10"), lineWidth: 0.5)
        )
        .shadow(color:.black.opacity(0.07),radius: 4)
    }
}
