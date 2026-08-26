//
//  StockOrderOrdersAndPositions.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderOrdersAndPositionsTab: Hashable {
    case positions
    case todayOrders
}

enum StockOrderOrdersAndPositionsContentState: Hashable {
    case content
    case empty
    case unavailable
}

/// The product family shown by the virtual-asset order page.
///
/// It intentionally lives with the orders-and-positions component: this is the
/// only page section that renders the segmented control, while the demo view
/// model uses the type to choose the corresponding holdings data.
enum StockOrderProductCategory: String, CaseIterable, Hashable, Identifiable {
    case stocks
    case crypto

    var id: String { rawValue }

    func title(language: DemoLanguage) -> String {
        switch self {
        case .stocks:
            language.text(.stocks)
        case .crypto:
            language.text(.cryptocurrency)
        }
    }
}

/// Custom product selector kept in this compilation unit so Canvas can compile
/// the orders-and-positions preview independently of the complete app target.
private struct StockOrderProductCategoryPicker: View {
    @Binding var selection: StockOrderProductCategory

    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StockOrderProductCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    Text(category.title(language: language))
                        .modifier(
                            CustomFontModifier(
                                size: 14,
                                font: selection == category ? .medium : .regular,
                                lineHeight: 20
                            )
                        )
                        .foregroundColor(
                            selection == category
                                ? Color("color-text-30")
                                : Color("color-text-60")
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 26, maxHeight: 26)
                        .background(
                            selection == category
                                ? Color("color-base-1")
                                : Color.clear
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityAddTraits(selection == category ? .isSelected : [])
                .accessibilityLabel(category.title(language: language))
                .accessibilityIdentifier(
                    "stockOrder.productCategory.\(category.rawValue)"
                )
            }
        }
        .padding(2)
        .background(Color("color-scale-2"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .frame(height: 30)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.productCategory")
    }
}

/// A stock-order-page section that switches between positions and today's orders.
///
/// Position rows are intentionally rendered by `StockHoldingListGroup`, keeping
/// their horizontal table, market grouping, and quick-action expansion behavior
/// consistent with the trade aggregation demo.
struct StockOrderOrdersAndPositions: View {
    @Binding var selectedTab: StockOrderOrdersAndPositionsTab

    let viewportWidth: CGFloat
    let todayOrders: [StockOrderTodayOrderItem]
    let holdingSections: [StockHoldingMarketSection]
    let virtualAssetHoldingSections: [VirtualAssetHoldingSection]
    let showsProductCategoryPicker: Bool
    @Binding var productCategory: StockOrderProductCategory
    let isNumberHidden: Bool
    let todayOrdersState: StockOrderOrdersAndPositionsContentState
    let positionsState: StockOrderOrdersAndPositionsContentState
    let onHistoryOrders: (() -> Void)?
    let onRefresh: () -> Void
    let onOrderAction: (StockOrderTodayOrderItem, StockOrderTodayOrderAction) -> Void
    let onQuote: (StockHoldingItem) -> Void
    let onOrder: (StockHoldingItem) -> Void
    let onDetails: (StockHoldingItem) -> Void
    let onVirtualAssetAction: (VirtualAssetHoldingAction, VirtualAssetHoldingItem) -> Void

    @Environment(\.demoLanguage) private var language
    @State private var expandedOrderID: StockOrderTodayOrderItem.ID?

    init(
        selectedTab: Binding<StockOrderOrdersAndPositionsTab>,
        viewportWidth: CGFloat,
        todayOrders: [StockOrderTodayOrderItem] = [],
        holdingSections: [StockHoldingMarketSection] = [],
        virtualAssetHoldingSections: [VirtualAssetHoldingSection] = [],
        showsProductCategoryPicker: Bool = false,
        productCategory: Binding<StockOrderProductCategory> = .constant(.stocks),
        isNumberHidden: Bool = false,
        todayOrdersState: StockOrderOrdersAndPositionsContentState = .content,
        positionsState: StockOrderOrdersAndPositionsContentState = .content,
        onHistoryOrders: (() -> Void)? = nil,
        onRefresh: @escaping () -> Void = {},
        onOrderAction: @escaping (StockOrderTodayOrderItem, StockOrderTodayOrderAction) -> Void = { _, _ in },
        onQuote: @escaping (StockHoldingItem) -> Void = { _ in },
        onOrder: @escaping (StockHoldingItem) -> Void = { _ in },
        onDetails: @escaping (StockHoldingItem) -> Void = { _ in },
        onVirtualAssetAction: @escaping (
            VirtualAssetHoldingAction,
            VirtualAssetHoldingItem
        ) -> Void = { _, _ in }
    ) {
        _selectedTab = selectedTab
        _productCategory = productCategory
        self.viewportWidth = viewportWidth
        self.todayOrders = todayOrders
        self.holdingSections = holdingSections
        self.virtualAssetHoldingSections = virtualAssetHoldingSections
        self.showsProductCategoryPicker = showsProductCategoryPicker
        self.isNumberHidden = isNumberHidden
        self.todayOrdersState = todayOrdersState
        self.positionsState = positionsState
        self.onHistoryOrders = onHistoryOrders
        self.onRefresh = onRefresh
        self.onOrderAction = onOrderAction
        self.onQuote = onQuote
        self.onOrder = onOrder
        self.onDetails = onDetails
        self.onVirtualAssetAction = onVirtualAssetAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsProductCategoryPicker {
                StockOrderProductCategoryPicker(selection: $productCategory)
            }

            tabBar

            content
        }
        .frame(width: viewportWidth, alignment: .topLeading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.ordersAndPositions")
    }

    private var tabBar: some View {
        HStack(spacing: StockOrderOrdersAndPositionsLayout.tabSpacing) {
            tabButton(.positions, count: holdingCount)
            tabButton(.todayOrders, count: todayOrders.count)

            Spacer(minLength: 0)

            if selectedTab == .todayOrders, let onHistoryOrders {
                Button {
                    onHistoryOrders()
                } label: {
                    HStack(spacing: 2) {
                        Text(language.text(.historyOrders))
                            .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Color("color-brand-blue"))
                    .frame(height: StockOrderOrdersAndPositionsLayout.tabHeight)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(language.text(.historyOrders))
            }
        }
        .padding(.horizontal, StockOrderOrdersAndPositionsLayout.horizontalPadding)
        .padding(.vertical, StockOrderOrdersAndPositionsLayout.tabVerticalPadding)
        .frame(height: StockOrderOrdersAndPositionsLayout.tabBarHeight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.ordersAndPositions.tabs")
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .positions:
            positionsContent
        case .todayOrders:
            todayOrdersContent
        }
    }

    @ViewBuilder
    private var positionsContent: some View {
        switch resolvedPositionsState {
        case .content:
            if productCategory == .crypto {
                VirtualAssetHoldingListGroup(
                    viewportWidth: viewportWidth,
                    sections: virtualAssetHoldingSections,
                    isNumberHidden: isNumberHidden,
                    showsCategoryHeaders: false,
                    sortsHoldingsByMarketValueDescending: true,
                    onAction: onVirtualAssetAction
                )
            } else {
                StockHoldingListGroup(
                    viewportWidth: viewportWidth,
                    sections: holdingSections,
                    isNumberHidden: isNumberHidden,
                    showsMarketHeaders: false,
                    sortsHoldingsByMarketValueDescending: true,
                    onQuote: onQuote,
                    onOrder: onOrder,
                    onDetails: onDetails
                )
            }
        case .empty:
            emptyState(message: language.text(.noPositions))
        case .unavailable:
            unavailableState
        }
    }

    @ViewBuilder
    private var todayOrdersContent: some View {
        switch resolvedTodayOrdersState {
        case .content:
            VStack(spacing: 0) {
                todayOrdersTableHeader

                // Today's orders are a small, fixed demo list. Keep the rows in a
                // regular stack so an animated section above does not cause a
                // lazy list to re-measure and visibly jump.
                VStack(spacing: 0) {
                    ForEach(todayOrders) { item in
                        StockOrderTodayOrder(
                            isActionGroupExpanded: orderExpansionBinding(for: item.id),
                            side: item.side,
                            status: item.status,
                            productName: item.productName,
                            symbol: item.symbol,
                            price: item.price,
                            quantity: item.quantity,
                            filledQuantity: item.filledQuantity,
                            tag: item.tag,
                            showsStatusIcon: item.showsStatusIcon,
                            actions: item.actions
                        ) { action in
                            onOrderAction(item, action)
                        }
                    }
                }
            }
        case .empty:
            emptyState(message: language.text(.noTodayOrders))
        case .unavailable:
            unavailableState
        }
    }

    private var todayOrdersTableHeader: some View {
        HStack(spacing: 0) {
            HStack(spacing: StockOrderOrdersAndPositionsLayout.headerColumnSpacing) {
                HStack(spacing: StockOrderOrdersAndPositionsLayout.headerStatusSpacing) {
                    Text(language.text(.orderStatusHeader))
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)

                    Image("stock_order_chevron_down")
                        .scaledToFit()
                        .frame(
                            width: StockOrderOrdersAndPositionsLayout.headerSortIconWidth,
                            height: StockOrderOrdersAndPositionsLayout.headerSortIconHeight
                        )
                        .accessibilityHidden(true)
                }
                .frame(
                    width: StockOrderOrdersAndPositionsLayout.headerStatusWidth,
                    alignment: .leading
                )

                Text(language.text(.symbolHeader))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .frame(
                        width: StockOrderOrdersAndPositionsLayout.headerNameWidth,
                        alignment: .leading
                    )
            }
            .padding(.leading, StockOrderOrdersAndPositionsLayout.horizontalPadding)
            .frame(
                width: StockOrderOrdersAndPositionsLayout.headerLeftWidth,
                alignment: .leading
            )

            HStack(spacing: StockOrderOrdersAndPositionsLayout.headerColumnSpacing) {
                Text(language.text(.orderPriceHeader))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .frame(
                        width: StockOrderOrdersAndPositionsLayout.headerPriceWidth,
                        alignment: .trailing
                    )

                Text(language.text(.quantityFilledHeader))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .frame(
                        width: StockOrderOrdersAndPositionsLayout.headerQuantityWidth,
                        alignment: .trailing
                    )
            }
            .padding(.trailing, StockOrderOrdersAndPositionsLayout.horizontalPadding)
            .frame(
                width: StockOrderOrdersAndPositionsLayout.headerRightWidth,
                alignment: .leading
            )
        }
        .frame(
            width: viewportWidth,
            height: StockOrderOrdersAndPositionsLayout.headerHeight,
            alignment: .center
        )
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.ordersAndPositions.todayOrdersHeader")
    }

    private func tabButton(
        _ tab: StockOrderOrdersAndPositionsTab,
        count: Int
    ) -> some View {
        let isSelected = selectedTab == tab
        let title = tab == .positions ? language.text(.positions) : language.text(.todayOrders)

        return Button {
            selectedTab = tab
            expandedOrderID = nil
        } label: {
            Text("\(title)(\(count))")
                .modifier(
                    CustomFontModifier(
                        size: 14,
                        font: isSelected ? .bold : .regular,
                        lineHeight: 20
                    )
                )
                .foregroundColor(isSelected ? Color("color-brand-blue") : Color("color-text-60"))
                .lineLimit(1)
                .padding(.horizontal, StockOrderOrdersAndPositionsLayout.tabHorizontalPadding)
                .frame(height: StockOrderOrdersAndPositionsLayout.tabHeight)
                .background(isSelected ? Color("color-brand-blue").opacity(0.08) : Color("color-scale-2"))
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(isSelected ? Color("color-brand-blue") : Color.clear, lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue("\(count)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(
            "stockOrder.ordersAndPositions.tab.\(tab == .positions ? "positions" : "todayOrders")"
        )
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: StockOrderOrdersAndPositionsLayout.emptyStateSpacing) {
            Image("empty_portfolio")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockOrderOrdersAndPositionsLayout.emptyStateImageWidth,
                    height: StockOrderOrdersAndPositionsLayout.emptyStateImageHeight
                )
                .accessibilityHidden(true)

            Text(message)
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))
        }
        .frame(
            width: viewportWidth,
            height: StockOrderOrdersAndPositionsLayout.emptyStateHeight,
            alignment: .center
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockOrder.ordersAndPositions.empty")
    }

    private var unavailableState: some View {
        VStack(spacing: StockOrderOrdersAndPositionsLayout.emptyStateSpacing) {
            Image("stock_order_network_error")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockOrderOrdersAndPositionsLayout.emptyStateImageWidth,
                    height: StockOrderOrdersAndPositionsLayout.emptyStateImageHeight
                )
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(language.text(.networkUnavailable))
                    .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                    .foregroundColor(Color("color-text-60"))

                Button(language.text(.refreshNow), action: onRefresh)
                    .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                    .foregroundColor(Color("color-brand-blue"))
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("stockOrder.ordersAndPositions.refresh")
            }
        }
        .frame(
            width: viewportWidth,
            height: StockOrderOrdersAndPositionsLayout.emptyStateHeight,
            alignment: .center
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.ordersAndPositions.unavailable")
    }

    private var holdingCount: Int {
        if productCategory == .crypto {
            return virtualAssetHoldingSections.reduce(0) { $0 + $1.holdings.count }
        }

        return holdingSections.reduce(0) { $0 + $1.holdings.count }
    }

    private var resolvedTodayOrdersState: StockOrderOrdersAndPositionsContentState {
        todayOrdersState == .content && todayOrders.isEmpty ? .empty : todayOrdersState
    }

    private var resolvedPositionsState: StockOrderOrdersAndPositionsContentState {
        let hasHoldings = productCategory == .crypto
            ? !virtualAssetHoldingSections.isEmpty
            : !holdingSections.isEmpty

        return positionsState == .content && !hasHoldings ? .empty : positionsState
    }

    private func orderExpansionBinding(
        for id: StockOrderTodayOrderItem.ID
    ) -> Binding<Bool> {
        Binding(
            get: { expandedOrderID == id },
            set: { isExpanded in
                expandedOrderID = isExpanded ? id : nil
            }
        )
    }
}

private enum StockOrderOrdersAndPositionsLayout {
    static let horizontalPadding: CGFloat = 16
    static let tabBarHeight: CGFloat = 52
    static let tabHeight: CGFloat = 28
    static let tabVerticalPadding: CGFloat = 12
    static let tabHorizontalPadding: CGFloat = 8
    static let tabSpacing: CGFloat = 4
    static let headerHeight: CGFloat = 32
    static let headerLeftWidth: CGFloat = 201
    static let headerRightWidth: CGFloat = 201
    static let headerStatusWidth: CGFloat = 85
    static let headerNameWidth: CGFloat = 92
    static let headerPriceWidth: CGFloat = 90
    static let headerQuantityWidth: CGFloat = 87
    static let headerColumnSpacing: CGFloat = 8
    static let headerStatusSpacing: CGFloat = 4
    static let headerSortIconWidth: CGFloat = 8
    static let headerSortIconHeight: CGFloat = 4
    static let emptyStateHeight: CGFloat = 180
    static let emptyStateImageWidth: CGFloat = 64
    static let emptyStateImageHeight: CGFloat = 56
    static let emptyStateSpacing: CGFloat = 12
}

private struct StockOrderOrdersAndPositionsPreviewHarness: View {
    @State private var selectedTab: StockOrderOrdersAndPositionsTab = .todayOrders

    var body: some View {
        StockOrderOrdersAndPositions(
            selectedTab: $selectedTab,
            viewportWidth: 402,
            todayOrders: [
                StockOrderTodayOrderItem(
                    id: "nvda-pending",
                    side: .buy,
                    status: .pending,
                    productName: "英伟达",
                    symbol: "NVDA",
                    price: "16.390",
                    quantity: "2,000",
                    filledQuantity: "0",
                    actions: StockOrderTodayOrderAction.allCases
                ),
                StockOrderTodayOrderItem(
                    id: "nvda-submitted",
                    side: .buy,
                    status: .submitted,
                    productName: "英伟达",
                    symbol: "NVDA",
                    price: "16.390",
                    quantity: "2,000",
                    filledQuantity: "0",
                    actions: StockOrderTodayOrderAction.allCases
                ),
                StockOrderTodayOrderItem(
                    id: "nvda-partially-filled",
                    side: .sell,
                    status: .partiallyFilled,
                    productName: "英伟达",
                    symbol: "NVDA",
                    price: "16.390",
                    quantity: "2,000",
                    filledQuantity: "1,000",
                    actions: StockOrderTodayOrderAction.allCases
                ),
                StockOrderTodayOrderItem(
                    id: "nvda-filled",
                    side: .buy,
                    status: .filled,
                    productName: "英伟达",
                    symbol: "NVDA",
                    price: "16.390",
                    quantity: "2,000",
                    filledQuantity: "2,000",
                    actions: StockOrderTodayOrderAction.allCases
                ),
                StockOrderTodayOrderItem(
                    id: "nvda-failed",
                    side: .sell,
                    status: .failed,
                    productName: "英伟达",
                    symbol: "NVDA",
                    price: "16.390",
                    quantity: "2,000",
                    filledQuantity: "0",
                    actions: StockOrderTodayOrderAction.allCases
                ),
                StockOrderTodayOrderItem(
                    id: "nvda-expired",
                    side: .buy,
                    status: .expired,
                    productName: "英伟达",
                    symbol: "NVDA",
                    price: "16.390",
                    quantity: "2,000",
                    filledQuantity: "0",
                    actions: StockOrderTodayOrderAction.allCases
                ),
                StockOrderTodayOrderItem(
                    id: "nvda-cancelled",
                    side: .sell,
                    status: .cancelled,
                    productName: "英伟达",
                    symbol: "NVDA",
                    price: "16.390",
                    quantity: "2,000",
                    filledQuantity: "0",
                    actions: StockOrderTodayOrderAction.allCases
                )
            ],
            holdingSections: .preview,
            onHistoryOrders: {}
        )
    }
}

struct StockOrderOrdersAndPositions_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderOrdersAndPositionsPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese · Content")

            StockOrderOrdersAndPositions(
                selectedTab: .constant(.todayOrders),
                viewportWidth: 402
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Empty")
        }
        .previewLayout(.fixed(width: 402, height: 520))
    }
}
