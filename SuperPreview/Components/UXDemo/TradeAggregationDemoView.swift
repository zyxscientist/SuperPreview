//
//  TradeAggregationDemoView.swift
//  SuperPreview
//

import SwiftUI

struct TradeAggregationDemoView: View {
    @State private var selectedCategory: AssetCategory = .stocks
    @State private var isNumberHidden = false
    @State private var quickMenuTopPositions: [AssetCategory: CGFloat] = [:]

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    Color.clear
                        .frame(height: TradeAggregationLayout.topInset)

                    TotalAsset(isNumberHidden: $isNumberHidden)

                    Color.clear
                        .frame(height: TradeAggregationLayout.totalAssetBottomSpacing)

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
        .navigationBarTitle("新交易", displayMode: .inline)
        .toolbarBackground(Color("color-base-1"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onPreferenceChange(TradeAggregationQuickMenuTopPreferenceKey.self) {
            quickMenuTopPositions.merge($0) { _, newValue in newValue }
        }
    }

    private var selectedCategoryPage: some View {
        TradeAggregationCategoryPage(
            category: selectedCategory,
            isNumberHidden: isNumberHidden
        )
        .id(selectedCategory)
    }

    private var isQuickMenuPinned: Bool {
        guard let top = quickMenuTopPositions[selectedCategory] else {
            return false
        }
        return top <= 0
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

private struct TradeAggregationCategoryPage: View {
    let category: AssetCategory
    let isNumberHidden: Bool

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
            StockSubAssetCard(isNumberHidden: isNumberHidden)
        case .funds:
            FundSubAssetCard(isNumberHidden: isNumberHidden)
        case .virtualAssets:
            VirtualAssetsSubAssetCard(isNumberHidden: isNumberHidden)
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
            StockHoldingListGroup(isNumberHidden: isNumberHidden)
        case .funds:
            FundHoldingListGroup(isNumberHidden: isNumberHidden)
        case .virtualAssets:
            VirtualAssetHoldingListGroup(isNumberHidden: isNumberHidden)
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

struct TradeAggregationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TradeAggregationDemoView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
