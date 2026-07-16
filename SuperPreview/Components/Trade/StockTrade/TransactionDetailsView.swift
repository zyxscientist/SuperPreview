//
//  TransactionDetailsView.swift
//  SuperPreview
//
//  Created by admin on 2024/10/8.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct TransactionDetailsView: View {

    @StateObject private var viewModel = TransactionViewModel()
    @State private var scrollPosition = ScrollPosition(idType: UUID.self, edge: .bottom)
    @State private var isBrowsingHistory = false
    @State private var isAtBottom = true
    @State private var contentPushOffset: CGFloat = 0
    @State private var pushAnimationTask: Task<Void, Never>?

    var body: some View {
        let newestTransactionID = viewModel.transactions.last?.id
        let refreshAnimation = Animation.linear(
            duration: viewModel.pushFrequency.refreshAnimationDuration
        )

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
                    VStack(spacing: 0){
                        ForEach(viewModel.transactions) { transaction in
                            TransactionDetailsCell(
                                transactionDetailsCellData: transaction,
                                isLatest: transaction.id == newestTransactionID
                            )
                        }
                    }
                    .transaction { transaction in
                        // 行集合的增删必须瞬时完成；唯一允许的位移动画由外层 offset 驱动。
                        transaction.animation = nil
                    }
                    .scrollTargetLayout()
                    .offset(y: contentPushOffset)

                }
                .background(Color(.colorBase1))
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, 24, for: .scrollContent)

                //固定尺寸
                .frame(minWidth: 130, maxWidth: 130, maxHeight: 315)
                .scrollPosition($scrollPosition, anchor: .bottom)
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.containerSize.height >=
                        geometry.contentSize.height + geometry.contentInsets.bottom - 1
                } action: { _, isAtBottom in
                    self.isAtBottom = isAtBottom
                }
                .onScrollPhaseChange { _, newPhase in
                    if newPhase == .interacting {
                        beginHistoryBrowsing()
                    } else if newPhase == .idle, isAtBottom {
                        resumeFollowingLatest()
                    }
                }
                .onChange(of: newestTransactionID) { _, newValue in
                    guard let newValue, !isBrowsingHistory else { return }
                    animateNewTransactions(
                        toward: newValue,
                        animation: refreshAnimation
                    )
                }
                .overlay(alignment: .bottom) {
                    if isBrowsingHistory {
                        Button(action: resumeFollowingLatest) {
                            Text("回到最新")
                                .foregroundStyle(Color(.colorText90))
                                .modifier(CustomFontModifier(size: 10, font: .medium))
                                .padding(.horizontal, 8)
                                .frame(height: 20)
                                .background(
                                    Capsule()
                                        .fill(Color(.colorBase1))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color(.colorSeparator10), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 28)
                        .accessibilityLabel("回到最新")
                    }
                }

                Text("成交明细")
                    .foregroundStyle(Color(.colorText90))
                    .modifier(CustomFontModifier(size: 11, font: .medium))
                    .frame(minWidth: 130, maxWidth: 130, maxHeight: 24)
                    .background(Color(.colorBase1))
                    .overlay {
                        FullWidthSeparatorView()
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
        .onDisappear {
            pushAnimationTask?.cancel()
        }
    }

    private func beginHistoryBrowsing() {
        guard !isBrowsingHistory else { return }

        pushAnimationTask?.cancel()

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            contentPushOffset = 0
        }

        isBrowsingHistory = true
        viewModel.setHistoryBrowsing(true)
    }

    private func animateNewTransactions(
        toward newestTransactionID: UUID,
        animation: Animation
    ) {
        pushAnimationTask?.cancel()

        let presentationCount = max(viewModel.latestPresentationCount, 1)
        let pushDistance = TransactionDetailsCell.rowHeight * CGFloat(presentationCount)

        // 数据已写入后先反向补偿同等高度，使保留下来的行停留在旧位置。
        // 随后只动画这一份 offset，整列便会线性上移，新行也会从底部进入。
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            contentPushOffset = pushDistance
            scrollPosition.scrollTo(id: newestTransactionID, anchor: .bottom)
        }

        pushAnimationTask = Task { @MainActor in
            // 留出一个显示帧提交“新数据 + 等高补偿”，防止结构 diff 被并入位移动画。
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }

            withAnimation(animation) {
                contentPushOffset = 0
            }
        }
    }

    private func resumeFollowingLatest() {
        guard isBrowsingHistory else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            contentPushOffset = 0
            isBrowsingHistory = false
            viewModel.setHistoryBrowsing(false)
            if let newestTransactionID = viewModel.transactions.last?.id {
                scrollPosition.scrollTo(id: newestTransactionID, anchor: .bottom)
            } else {
                scrollPosition.scrollTo(edge: .bottom)
            }
        }
    }
}

// 成交明细单元视图
struct TransactionDetailsCell: View {

    static let rowHeight: CGFloat = 20

    let transactionDetailsCellData: TransactionDetailsCellData
    let isLatest: Bool
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
        .frame(height: Self.rowHeight)
        .background(
            transactionDetailsCellData.typeSymbol.color.opacity(isLatest && isHighlighted ? 0.05 : 0)
        )
        .animation(.easeOut(duration: 0.2), value: isHighlighted)
        .onAppear {
            guard isLatest else { return }

            isHighlighted = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 异步倒计时让高亮结束
                isHighlighted = false
            }
        }
        .onChange(of: isLatest) { _, newValue in
            if !newValue {
                isHighlighted = false
            }
        }
    }
}

#Preview {
    TransactionDetailsView()
}
