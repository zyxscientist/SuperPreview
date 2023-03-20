//
//  Quantity_Inputfield.swift
//  SuperPreview
//
//  Created by admin on 2023/1/11.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Quantity_Inputfield: View {
    
    @EnvironmentObject var priceQuantityViewModel: PriceQuantityViewModel
    @Binding var quantityQuickType: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            
            Text("数量")
                .foregroundColor(Color("color-text-60"))
                .font(.system(size: 16, weight: .regular, design: .default))
            
            HStack(spacing:0){
                Image("decrease_normal")
                    .padding(.trailing, 10)
                    .onTapGesture {
                        if priceQuantityViewModel.quantity > 0 {
                            priceQuantityViewModel.decreaseQuan()
                            priceQuantityViewModel.getAmount()
                            HapticManager.instance.impactHaptic(type: .medium)
                        } else {
                            HapticManager.instance.notificationHaptic(type: .error)
                        }
        
                    }
                Text("\(priceQuantityViewModel.quantity)")
                    .foregroundColor(Color("color-text-30"))
                    .modifier(CustomFontModifier(size: 16, font: .medium))
            }.padding(.leading, 65)
            
            Spacer()
            
            HStack(spacing: 0) {
                Image("increase_normal")
                    .padding(.trailing, 10)
                    .onTapGesture {
                        priceQuantityViewModel.increaseQuan()
                        priceQuantityViewModel.getAmount()
                        HapticManager.instance.impactHaptic(type: .medium)
                    }
                
                Image(quantityQuickType ? "quantity_quick_select_active" : "quantity_quick_select_inactive")
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 1, blendDuration: 0.8)){
                                quantityQuickType.toggle()
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

struct Quantity_Inputfield_Previews: PreviewProvider {
    static var previews: some View {
        Quantity_Inputfield(quantityQuickType: .constant(false))
    }
}
