//
//  TransactionDetailsView.swift
//  SuperPreview
//
//  Created by admin on 2024/10/8.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

private struct TransactionPushAnimationState {
    let newestTransactionID: UUID
    let distance: CGFloat
    let startDate: Date
    let duration: TimeInterval

    func offset(at date: Date) -> CGFloat {
        let elapsed = max(date.timeIntervalSince(startDate), 0)
        let progress = min(elapsed / duration, 1)
        return distance * CGFloat(1 - progress)
    }
}

struct TransactionDetailsView: View {

    @StateObject private var viewModel = TransactionViewModel()
    @State private var scrollPosition = ScrollPosition(idType: UUID.self, edge: .bottom)
    @State private var isBrowsingHistory = false
    @State private var isAtBottom = true
    @State private var pushAnimationState: TransactionPushAnimationState?
    @State private var pushAnimationTask: Task<Void, Never>?

    var body: some View {
        let newestTransactionID = viewModel.transactions.last?.id
        let refreshAnimationDuration = viewModel.pushFrequency.refreshAnimationDuration

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
                    TimelineView(
                        .animation(
                            minimumInterval: 1.0 / 60.0,
                            paused: pushAnimationState == nil
                        )
                    ) { timeline in
                        ZStack(alignment: .top) {
                            VStack(spacing: 0){
                                ForEach(viewModel.transactions) { transaction in
                                    TransactionDetailsCell(
                                        transactionDetailsCellData: transaction,
                                        isLatest: transaction.id == newestTransactionID
                                    )
                                }
                            }
                            .transaction { transaction in
                                // 内层只更新行结构，绝不参与位移动画。
                                transaction.animation = nil
                            }
                            .scrollTargetLayout()
                        }
                        // 位移由时间轴逐帧计算，不依赖 SwiftUI 是否提交了某个预置帧。
                        .offset(y: pushAnimationState?.offset(at: timeline.date) ?? 0)
                    }

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
                        duration: refreshAnimationDuration
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
            viewModel.finishPresentation()
        }
    }

    private func beginHistoryBrowsing() {
        guard !isBrowsingHistory else { return }

        pushAnimationTask?.cancel()

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            pushAnimationState = nil
        }

        isBrowsingHistory = true
        viewModel.setHistoryBrowsing(true)
    }

    private func animateNewTransactions(
        toward newestTransactionID: UUID,
        duration: TimeInterval
    ) {
        pushAnimationTask?.cancel()

        let presentationCount = max(viewModel.latestPresentationCount, 1)
        let pushDistance = TransactionDetailsCell.rowHeight * CGFloat(presentationCount)

        // 数据写入后按相同行高反向补偿。时间轴会从补偿位置线性推进到零，
        // 因此保留行整体上移，新行同时从底部进入。
        let leadInDuration = 1.0 / 60.0
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            pushAnimationState = TransactionPushAnimationState(
                newestTransactionID: newestTransactionID,
                distance: pushDistance,
                startDate: Date().addingTimeInterval(leadInDuration),
                duration: duration
            )
            scrollPosition.scrollTo(id: newestTransactionID, anchor: .bottom)
        }

        pushAnimationTask = Task { @MainActor in
            do {
                try await Task.sleep(
                    nanoseconds: UInt64((leadInDuration + duration) * 1_000_000_000)
                )
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                guard pushAnimationState?.newestTransactionID == newestTransactionID else {
                    return
                }
                pushAnimationState = nil
                viewModel.finishPresentation()
            }
        }
    }

    private func resumeFollowingLatest() {
        guard isBrowsingHistory else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            pushAnimationState = nil
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
