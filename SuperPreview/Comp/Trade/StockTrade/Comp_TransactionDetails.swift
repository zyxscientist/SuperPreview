//
//  Comp_TransactionDetails.swift
//  SuperPreview
//
//  Created by admin on 2024/10/8.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_TransactionDetails: View {
    
    @StateObject private var viewModel = TransactionViewModel()
    
    var body: some View {
        ZStack(alignment:.bottom) {
            ScrollView {
                
                // 成交明细视图
                LazyVStack(spacing: 0){
                    ForEach(viewModel.transactions) { transaction in
                        TransactionDetailsCell(transactionDetailsCellData: transaction)
                            .transition(.move(edge: .top))
                    }
                }.animation(.easeInOut(duration: 0.2), value: viewModel.transactions)
                
            }
            .background(Color(.colorBase1))
            
            //固定尺寸
            .frame(minWidth: 130, maxWidth: 130, maxHeight: 315)
            
            Text("成交明细")
                .foregroundStyle(Color(.colorText90))
                .modifier(CustomFontModifier(size: 11, font: .medium))
                .frame(minWidth: 130, maxWidth: 130, maxHeight: 24)
                .background(Color(.colorBase1))
                .overlay {
                    Comp_Separator_Full()
                        .rotationEffect(.degrees(180))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        // 描边
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.colorSeparator10), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 2)
    }
}

// 成交明细单元视图
struct TransactionDetailsCell: View {
    
    let transactionDetailsCellData: TransactionDetailsCellData
    @State private var isHighlighted = false
    @State private var blurAmount: CGFloat = 2
    
    var body: some View {
        HStack(spacing:0){
            HStack(spacing:3){
                
                // 时间
                Text(transactionDetailsCellData.time)
                    .lineLimit(1)
                    .frame(width:30)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color(.colorText60))
                    .modifier(CustomFontModifier(size: 11, font: .medium))
                    .padding(.leading, 2)
                    .blur(radius: blurAmount)
                
                // 价格
                Text(transactionDetailsCellData.price)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color(.colorUtility3Red))
                    .modifier(CustomFontModifier(size: 11, font: .medium))
                    .blur(radius: blurAmount)
            }
            
            Spacer()
            
            HStack(spacing:1){
                
                // 成交量，字的颜色与类型标同步
                Text(transactionDetailsCellData.volume)
                    .foregroundStyle(Color(transactionDetailsCellData.typeSymbol.color))
                    .modifier(CustomFontModifier(size: 11, font: .medium))
                    .multilineTextAlignment(.trailing)
                    .blur(radius: blurAmount)
                
                // 主买卖及中性类型标识图标
                Image(transactionDetailsCellData.typeSymbol.imageName)
                    .resizable()
                    .frame(width:7, height: 6)
                    .padding(.trailing, 2)
                    .blur(radius: blurAmount)
            }
        }
        .padding(.vertical, 4)
        .background(
            transactionDetailsCellData.typeSymbol.color.opacity(isHighlighted ? 0.05 : 0)
        )
        .animation(.easeOut(duration: 0.2), value: isHighlighted)
        .animation(.easeInOut(duration: 0.3), value: blurAmount)
        .onAppear {
            
            isHighlighted = true
            blurAmount = 2
            
            withAnimation(.easeInOut(duration: 0.3)) {
                blurAmount = 0 // 数字模糊效果
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { // 异步倒计时让高亮结束
                isHighlighted = false
            }
        }
    }
}

#Preview {
    Comp_TransactionDetails()
}
