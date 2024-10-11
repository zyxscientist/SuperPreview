//
//  Comp_AssociatedInfo.swift
//  SuperPreview
//
//  Created by admin on 2024/10/11.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_AssociatedInfo: View {
    var body: some View {
        
        VStack(spacing:5){
            
            // 😮 关联信息单元
            HStack(spacing:0){
                
                HStack(spacing:5){
                    Image(.assciateInfoFinancialReport)
                        .resizable()
                        .frame(width: 14, height: 14)
                    
                    Text("2025/01/01")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width: 85, alignment: .leading)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                }
                
                Text("业绩公布")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(.colorText30))
                    .modifier(CustomFontModifier(size: 13, font: .regular))
                
                Spacer()
                
            }
            .padding(.vertical, 4.5)
            .padding(.horizontal, 9)
            .background(Color(.colorBase1))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            // 描边
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(.colorSeparator10), lineWidth: 0.5)
            )
            // 🔚结束
            
            // 😮 关联信息单元
            HStack(spacing:0){
                
                HStack(spacing:5){
                    Image(.assciateInfoDividen)
                        .resizable()
                        .frame(width: 14, height: 14)
                    
                    Text("2025/01/15")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .frame(width: 85, alignment: .leading)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                }
                
                Text("每股派息3.4000港元")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(.colorText30))
                    .modifier(CustomFontModifier(size: 13, font: .regular))
                
                Spacer()
                
            }
            .padding(.vertical, 4.5)
            .padding(.horizontal, 9)
            .background(Color(.colorBase1))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            // 描边
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(.colorSeparator10), lineWidth: 0.5)
            )
            // 🔚结束
            
            // 😮 关联信息单元
            HStack(spacing:0){
                
                HStack(spacing:5){
                    Image(.assciateInfoMerge)
                        .resizable()
                        .frame(width: 14, height: 14)
                    
                    Text("2025/01/20")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .frame(width: 85, alignment: .leading)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                }
                
                Text("并股：每5股合1股")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(.colorText30))
                    .modifier(CustomFontModifier(size: 13, font: .regular))
                
                Spacer()
                
            }
            .padding(.vertical, 4.5)
            .padding(.horizontal, 9)
            .background(Color(.colorBase1))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            // 描边
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(.colorSeparator10), lineWidth: 0.5)
            )
            // 🔚结束
            
        }
        .padding(.horizontal, 15)
    }
}

#Preview {
    Comp_AssociatedInfo()
}
