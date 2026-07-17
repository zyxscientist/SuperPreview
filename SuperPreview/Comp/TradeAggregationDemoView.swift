//
//  TradeAggregationDemoView.swift
//  SuperPreview
//

import SwiftUI

struct TradeAggregationDemoView: View {
    @State private var selectedCategory: AssetCategory = .stocks
    @State private var isNumberHidden = false
    @State private var pageHeights: [AssetCategory: CGFloat] = [:]
    @State private var quickMenuTopPositions: [AssetCategory: CGFloat] = [:]

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(
                    alignment: .leading,
                    spacing: 0,
                    pinnedViews: [.sectionHeaders]
                ) {
                    Color.clear
                        .frame(height: TradeAggregationLayout.topInset)

                    TotalAsset(isNumberHidden: $isNumberHidden)

                    Color.clear
                        .frame(height: TradeAggregationLayout.totalAssetBottomSpacing)

                    Section {
                        categoryPager
                    } header: {
                        AssetCategoryTabBar(selection: $selectedCategory)
                            .zIndex(1)
                    }
                }
            }
            .coordinateSpace(name: TradeAggregationLayout.scrollCoordinateSpace)

            if isQuickMenuPinned {
                quickMenu(for: selectedCategory)
                    .offset(y: TradeAggregationLayout.categoryTabHeight)
                    .transition(.identity)
                    .zIndex(2)
            }
        }
        .background(Color("color-base-1").ignoresSafeArea())
        .navigationBarTitle("新交易", displayMode: .inline)
        .onPreferenceChange(TradeAggregationPageHeightPreferenceKey.self) {
            updatePageHeights($0)
        }
        .onPreferenceChange(TradeAggregationQuickMenuTopPreferenceKey.self) {
            quickMenuTopPositions.merge($0) { _, newValue in newValue }
        }
    }

    private var categoryPager: some View {
        TabView(selection: $selectedCategory) {
            ForEach(AssetCategory.allCases) { category in
                TradeAggregationCategoryPage(
                    category: category,
                    isNumberHidden: isNumberHidden
                )
                .tag(category)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: selectedPageHeight)
    }

    private var selectedPageHeight: CGFloat {
        pageHeights[selectedCategory]
            ?? TradeAggregationLayout.initialPageHeight
    }

    private var isQuickMenuPinned: Bool {
        guard let top = quickMenuTopPositions[selectedCategory] else {
            return false
        }
        return top <= TradeAggregationLayout.categoryTabHeight
    }

    private func updatePageHeights(_ heights: [AssetCategory: CGFloat]) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            pageHeights.merge(heights) { _, newValue in newValue }
        }
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
}

private enum TradeAggregationLayout {
    static let viewportWidth: CGFloat = 402
    static let topInset: CGFloat = 12
    static let totalAssetBottomSpacing: CGFloat = 12
    static let categoryTabHeight: CGFloat = 48
    static let cardToQuickMenuSpacing: CGFloat = 22
    static let quickMenuHeight: CGFloat = 74
    static let quickMenuToTitleSpacing: CGFloat = 22
    static let holdingsTitleHeight: CGFloat = 28
    static let titleToHoldingsSpacing: CGFloat = 22
    static let bottomSpacing: CGFloat = 20
    static let initialPageHeight: CGFloat = 1_213
    static let scrollCoordinateSpace = "TradeAggregationScroll"
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
        .fixedSize(horizontal: false, vertical: true)
        .background(pageHeightReader)
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
                        in: .named(TradeAggregationLayout.scrollCoordinateSpace)
                    ).minY
                ]
            )
        }
    }

    private var pageHeightReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: TradeAggregationPageHeightPreferenceKey.self,
                value: [category: proxy.size.height]
            )
        }
    }
}

private struct TradeAggregationPageHeightPreferenceKey: PreferenceKey {
    static var defaultValue: [AssetCategory: CGFloat] = [:]

    static func reduce(
        value: inout [AssetCategory: CGFloat],
        nextValue: () -> [AssetCategory: CGFloat]
    ) {
        value.merge(nextValue()) { _, newValue in newValue }
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
