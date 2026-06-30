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
        VStack(spacing: 32) {
            HStack(spacing: 8) {
                Picker("推送频率", selection: $viewModel.pushFrequency) {
                    ForEach(TransactionPushFrequency.allCases) { frequency in
                        Text(frequency.title)
                            .tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)

                Button {
                    viewModel.startSimulatingDataPush()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(.colorText90))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color(.colorBase1))
                        )
                }
                .buttonStyle(.plain)
                .opacity(viewModel.isPlaying ? 0.35 : 1)
                .disabled(viewModel.isPlaying)
                .accessibilityLabel("播放推送")
            }

            ZStack(alignment:.bottom) {
                ScrollView {

                    // 成交明细视图
                    LazyVStack(spacing: 0){
                        ForEach(viewModel.transactions) { transaction in
                            TransactionDetailsCell(
                                transactionDetailsCellData: transaction,
                                isFirst: transaction.id == viewModel.transactions.first?.id
                            )
                                .transition(.move(edge: .top))
                        }.animation(.linear(duration: 0.2), value: viewModel.transactions.first?.id)
                    }

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
}

// 成交明细单元视图
struct TransactionDetailsCell: View {

    let transactionDetailsCellData: TransactionDetailsCellData
    let isFirst: Bool
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
            transactionDetailsCellData.typeSymbol.color.opacity(isFirst && isHighlighted ? 0.05 : 0)
        )
        .animation(.easeOut(duration: 0.2), value: isHighlighted)
        .onAppear {

            isHighlighted = isFirst

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 异步倒计时让高亮结束
                isHighlighted = false
            }
        }
        .onChange(of: isFirst) { _, newValue in
            if !newValue {
                isHighlighted = false
            }
        }
    }
}

#Preview {
    Comp_TransactionDetails()
}
