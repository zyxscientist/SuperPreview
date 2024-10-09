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
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 2)
    }
}

// 成交明细单元视图
struct TransactionDetailsCell: View {
    
    let transactionDetailsCellData: TransactionDetailsCellData
    @State private var isHighlighted = false
    
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
                
                // 价格
                Text(transactionDetailsCellData.price)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color(.colorUtility3Red))
                    .modifier(CustomFontModifier(size: 11, font: .medium))
            }
            
            Spacer()
            
            HStack(spacing:1){
                
                // 成交量，字的颜色与类型标同步
                Text(transactionDetailsCellData.volume)
                    .foregroundStyle(Color(transactionDetailsCellData.typeSymbol.color))
                    .modifier(CustomFontModifier(size: 11, font: .medium))
                    .multilineTextAlignment(.trailing)
                
                // 主买卖及中性类型标识图标
                Image(transactionDetailsCellData.typeSymbol.imageName)
                    .resizable()
                    .frame(width:7, height: 6)
                    .padding(.trailing, 2)
            }
        }
        .padding(.vertical, 4)
        .background(
            transactionDetailsCellData.typeSymbol.color.opacity(isHighlighted ? 0.1 : 0)
        )
        .animation(.easeOut(duration: 0.2), value: isHighlighted)
        .onAppear {
            isHighlighted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isHighlighted = false
            }
        }
    }
}

#Preview {
    Comp_TransactionDetails()
}
