//
//  Amount.swift
//  SuperPreview
//
//  Created by admin on 2023/1/12.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Amount: View {
    
    @EnvironmentObject var priceQuantityViewModel: PriceQuantityViewModel
    @Binding var advanceSetting: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            
            Text("金额")
                .foregroundColor(Color("color-text-60"))
                .font(.system(size: 16, weight: .regular, design: .default))
            
            
            VStack(alignment: .leading, spacing: 0) {
                Text(String(format: "%.2f", priceQuantityViewModel.amount)) // 小数位管理
                    .padding(.leading, 65)
                    .foregroundColor(Color("color-text-30"))
                    .modifier(CustomFontModifier(size: 15, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                
                HStack(spacing: 5) {
                    
                    Text("持仓占比预估")
                        .padding(.leading, 65)
                        .foregroundColor(Color("color-text-60"))
                        .font(.system(size: 12, weight: .regular, design: .default))
                    
                    Text(String(format: "%.2f", priceQuantityViewModel.predictivePercentage)+"%")
                        .foregroundColor(Color("color-text-60"))
                        .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 15)
        .frame(width: UIScreen.main.bounds.size.width,height: 44)
        .background(Color("color-base-1"))
        .overlay {
            Comp_Separator_Full()
            Capsule()
                .frame(width: 54, height: 23)
                .foregroundColor(Color("color-base-1"))
                .clipShape(Capsule(style: .continuous))
                .overlay(
                    Text(advanceSetting ? "收起" : "展开")
                        .font(.system(size: 12, weight: .semibold, design: .default))
                )
                .overlay( // 再次叠加
                    Capsule(style: .continuous)
                        .stroke(Color("color-separator-10"), lineWidth: 0.5)
                )
                .shadow(color:.black.opacity(0.07),radius: 4)
                .offset(x:UIScreen.main.bounds.width/2-27-15, y: 22)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 1, blendDuration: 0.8))  {
                        advanceSetting.toggle()
                    }
                    HapticManager.instance.impactHaptic(type: .medium)
                }
        }
    }
}

struct Amount_Previews: PreviewProvider {
    static var previews: some View {
        Amount(advanceSetting: .constant(false))
    }
}

