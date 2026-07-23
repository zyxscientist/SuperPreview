//
//  TradeAggregationDemoView.swift
//  SuperPreview
//

import SwiftUI

struct TradeAggregationDemoView: View {
    @StateObject private var viewModel = TradeAggregationDemoViewModel()
    @State private var selectedCategory: AssetCategory = .stocks
    @State private var isNumberHidden = false
    @State private var quickMenuTopPositions: [AssetCategory: CGFloat] = [:]
    @State private var isShowingDebugPanel = false
    @State private var isLiveDataEnabled = false
    @State private var isMRTestingEnabled = false
    @State private var isSummerAdvertisementEnabled = false
    @State private var selectedMainTab: AppTab = .tab2

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    if isMRTestingEnabled {
                        TradeAggregationMRNoticeBar()
                    }

                    Color.clear
                        .frame(height: TradeAggregationLayout.topInset)

                    TotalAsset(
                        currency: "USD",
                        totalAmount: viewModel.snapshot.totalAmount,
                        totalProfitLoss: viewModel.snapshot.totalProfitLoss,
                        isDataAvailable: !isMRTestingEnabled,
                        isNumberHidden: $isNumberHidden
                    )

                    Color.clear
                        .frame(height: TradeAggregationLayout.totalAssetBottomSpacing)

                    if isSummerAdvertisementEnabled {
                        TradeAggregationSummerAdvertisement()

                        Color.clear
                            .frame(height: TradeAggregationLayout.standardVerticalSpacing)
                    }

                    AssetCategoryTabBar(selection: $selectedCategory)

                    selectedCategoryPage
                }
            }
            if isQuickMenuPinned {
                pinnedQuickMenu(for: selectedCategory)
                    .transition(.identity)
                    .zIndex(2)
            }
        }
        .coordinateSpace(name: TradeAggregationLayout.stickyCoordinateSpace)
        .background(Color("color-base-1").ignoresSafeArea())
        .mainTabBar(selectedTab: $selectedMainTab)
        .navigationBarTitle("新交易", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                isShowingDebugPanel = true
            }) {
                Text("Debug")
                    .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                    .foregroundColor(Color("color-text-30"))
            }
        )
        .toolbarBackground(Color("color-base-1"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isShowingDebugPanel) {
            TradeAggregationDebugPanel(
                isLiveDataEnabled: $isLiveDataEnabled,
                isMRTestingEnabled: $isMRTestingEnabled,
                isSummerAdvertisementEnabled: $isSummerAdvertisementEnabled
            )
        }
        .onPreferenceChange(TradeAggregationQuickMenuTopPreferenceKey.self) {
            quickMenuTopPositions.merge($0) { _, newValue in newValue }
        }
        .onChange(of: isQuickMenuPinned) { wasPinned, isPinned in
            guard !wasPinned, isPinned else { return }
            HapticManager.instance.impactHaptic(type: .light)
        }
        .task(id: isLiveDataEnabled) {
            guard isLiveDataEnabled else { return }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(
                            Double.random(in: 4.5...5.5) * 1_000_000_000
                        )
                    )
                } catch {
                    return
                }

                await MainActor.run {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        viewModel.simulateRandomRefresh()
                    }
                }
            }
        }
    }

    private var selectedCategoryPage: some View {
        Group {
            if isMRTestingActive {
                TradeAggregationMRMaintenanceStateView()
            } else {
                TradeAggregationCategoryPage(
                    category: selectedCategory,
                    isNumberHidden: isNumberHidden,
                    snapshot: viewModel.snapshot
                )
            }
        }
        .id("\(selectedCategory.rawValue)-\(isMRTestingActive)")
    }

    private var isQuickMenuPinned: Bool {
        guard !isMRTestingActive else { return false }
        guard let top = quickMenuTopPositions[selectedCategory] else {
            return false
        }
        return top <= 0
    }

    private var isMRTestingActive: Bool {
        isMRTestingEnabled && selectedCategory != .virtualAssets
    }

    @ViewBuilder
    private func quickMenu(for category: AssetCategory) -> some View {
        switch category {
        case .stocks:
            StockAssetQuickMenu()
        case .funds:
            FundAssetQuickMenu()
        case .virtualAssets:
            VirtualAssetsQuickMenu()
        }
    }

    private func pinnedQuickMenu(for category: AssetCategory) -> some View {
        VStack(spacing: 0) {
            quickMenu(for: category)

            Color.clear
                .frame(height: TradeAggregationLayout.quickMenuSeparatorAreaHeight)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color("color-separator-10"))
                        .frame(height: TradeAggregationLayout.quickMenuSeparatorLineHeight)
                }
                .accessibilityHidden(true)
        }
        .background(Color("color-base-1"))
    }

}

private enum TradeAggregationLayout {
    static let viewportWidth: CGFloat = 402
    static let topInset: CGFloat = 12
    static let totalAssetBottomSpacing: CGFloat = 12
    static let standardVerticalSpacing: CGFloat = 12
    static let cardToQuickMenuSpacing: CGFloat = 22
    static let quickMenuHeight: CGFloat = 74
    static let quickMenuSeparatorAreaHeight: CGFloat = 1
    static let quickMenuSeparatorLineHeight: CGFloat = 0.5
    static let quickMenuToTitleSpacing: CGFloat = 22
    static let holdingsTitleHeight: CGFloat = 28
    static let titleToHoldingsSpacing: CGFloat = 22
    static let bottomSpacing: CGFloat = 20
    static let stickyCoordinateSpace = "TradeAggregationStickyViewport"
}

private struct TradeAggregationSummerAdvertisement: View {
    var body: some View {
        Image("summeradv")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: TradeAggregationSummerAdvertisementStyle.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: TradeAggregationSummerAdvertisementStyle.cornerRadius,
                    style: .continuous
                )
                    .stroke(Color("color-separator-10"), lineWidth: 0.5)
            }
            .padding(.horizontal, 16)
            .accessibilityLabel("夏季新客开户礼遇活动")
    }
}

private enum TradeAggregationSummerAdvertisementStyle {
    static let cornerRadius: CGFloat = 16
}

private struct TradeAggregationCategoryPage: View {
    let category: AssetCategory
    let isNumberHidden: Bool
    let snapshot: TradeAggregationDemoSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            subAssetCard
                .padding(.horizontal, 16)

            Color.clear
                .frame(height: TradeAggregationLayout.cardToQuickMenuSpacing)

            quickMenu
                .frame(height: TradeAggregationLayout.quickMenuHeight)
                .background(quickMenuPositionReader)

            Color.clear
                .frame(height: TradeAggregationLayout.quickMenuToTitleSpacing)

            holdingsTitle

            Color.clear
                .frame(height: TradeAggregationLayout.titleToHoldingsSpacing)

            holdingList

            Color.clear
                .frame(height: TradeAggregationLayout.bottomSpacing)
        }
        .frame(
            width: TradeAggregationLayout.viewportWidth,
            alignment: .topLeading
        )
    }

    @ViewBuilder
    private var subAssetCard: some View {
        switch category {
        case .stocks:
            StockSubAssetCard(
                model: snapshot.stockCard,
                isNumberHidden: isNumberHidden
            )
        case .funds:
            FundSubAssetCard(
                model: snapshot.fundCard,
                isNumberHidden: isNumberHidden
            )
        case .virtualAssets:
            VirtualAssetsSubAssetCard(
                model: snapshot.virtualAssetCard,
                isNumberHidden: isNumberHidden
            )
        }
    }

    @ViewBuilder
    private var quickMenu: some View {
        switch category {
        case .stocks:
            StockAssetQuickMenu()
        case .funds:
            FundAssetQuickMenu()
        case .virtualAssets:
            VirtualAssetsQuickMenu()
        }
    }

    private var holdingsTitle: some View {
        Text("持仓明细")
            .font(
                .custom(
                    "PlusJakartaSans-SemiBold",
                    size: 18,
                    relativeTo: .headline
                )
            )
            .foregroundColor(Color("color-text-30"))
            .frame(
                width: TradeAggregationLayout.viewportWidth - 16,
                height: TradeAggregationLayout.holdingsTitleHeight,
                alignment: .leading
            )
            .padding(.leading, 16)
    }

    @ViewBuilder
    private var holdingList: some View {
        switch category {
        case .stocks:
            StockHoldingListGroup(
                sections: snapshot.stockSections,
                isNumberHidden: isNumberHidden
            )
        case .funds:
            FundHoldingListGroup(
                sections: snapshot.fundSections,
                isNumberHidden: isNumberHidden
            )
        case .virtualAssets:
            VirtualAssetHoldingListGroup(
                sections: snapshot.virtualAssetSections,
                isNumberHidden: isNumberHidden
            )
        }
    }

    private var quickMenuPositionReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: TradeAggregationQuickMenuTopPreferenceKey.self,
                value: [
                    category: proxy.frame(
                        in: .named(TradeAggregationLayout.stickyCoordinateSpace)
                    ).minY
                ]
            )
        }
    }

}

private struct TradeAggregationQuickMenuTopPreferenceKey: PreferenceKey {
    static var defaultValue: [AssetCategory: CGFloat] = [:]

    static func reduce(
        value: inout [AssetCategory: CGFloat],
        nextValue: () -> [AssetCategory: CGFloat]
    ) {
        value.merge(nextValue()) { _, newValue in newValue }
    }
}

private struct TradeAggregationMRNoticeBar: View {
    var body: some View {
        Text("系统维护期间无法获取总资产数据，完成后将恢复正常")
            .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
            .foregroundColor(Color("color-utility6-orange"))
            .frame(maxWidth: .infinity, minHeight: 36, maxHeight: 36, alignment: .leading)
            .padding(.horizontal, 16)
            .background(Color(red: 1, green: 243 / 255, blue: 231 / 255))
            .accessibilityLabel("系统维护提示：系统维护期间无法获取总资产数据，完成后将恢复正常")
    }
}

private struct TradeAggregationMRMaintenanceStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("mr_testing")
                .resizable()
                .frame(width: 70, height: 70)

            Text("正在升级系统")
                .modifier(CustomFontModifier(size: 18, font: .medium, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))
                .frame(maxWidth: .infinity)

            Text("升级时间：YYYY/MM/DD HH:MM 至 YYYY/MM/DD HH:MM，升级期间可能影响的交易与数据展示，升级完成后系统将恢复正常")
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 60)
        .frame(width: TradeAggregationLayout.viewportWidth, alignment: .top)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .combine)
    }
}

private struct TradeAggregationDebugPanel: View {
    @Binding var isLiveDataEnabled: Bool
    @Binding var isMRTestingEnabled: Bool
    @Binding var isSummerAdvertisementEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("调试")
                .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                .foregroundColor(Color("color-text-30"))

            Toggle(isOn: $isLiveDataEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("模拟实时数据")
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(
                        isLiveDataEnabled
                            ? "不同资产会以各自节奏持续刷新"
                            : "开启后模拟推送，数字会小幅变化"
                    )
                    .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                }
            }

            Toggle(isOn: $isMRTestingEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MR 测试状态")
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text("股票和基金显示系统升级状态，虚拟资产保持正常")
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                }
            }

            Toggle(isOn: $isSummerAdvertisementEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("显示夏季运营广告")
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text("在总资产下方展示夏季新客活动图")
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .background(Color("color-base-1").edgesIgnoringSafeArea(.all))
    }
}

struct TradeAggregationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TradeAggregationDemoView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
