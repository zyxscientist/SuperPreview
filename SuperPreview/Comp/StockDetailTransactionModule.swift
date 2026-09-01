//
//  StockDetailTransactionModule.swift
//  SuperPreview
//

import SwiftUI

/// The destinations represented by the transaction module's top-level tabs.
///
/// The tab bar is intentionally independent from the module content so the
/// subsequent trade, position, order, and history views can share this state.
enum StockDetailTransactionModuleTab: CaseIterable, Hashable, Identifiable {
    case trade
    case positions
    case orders
    case history

    var id: Self { self }

    fileprivate func title(for language: DemoLanguage) -> String {
        switch (self, language) {
        case (.trade, .simplifiedChinese):
            return "交易"
        case (.trade, .traditionalChinese):
            return "交易"
        case (.trade, .english):
            return "Trade"
        case (.positions, .simplifiedChinese):
            return "持仓"
        case (.positions, .traditionalChinese):
            return "持倉"
        case (.positions, .english):
            return "Position"
        case (.orders, .simplifiedChinese):
            return "订单"
        case (.orders, .traditionalChinese):
            return "訂單"
        case (.orders, .english):
            return "Orders"
        case (.history, .simplifiedChinese):
            return "历史"
        case (.history, .traditionalChinese):
            return "歷史"
        case (.history, .english):
            return "History"
        }
    }

    fileprivate func iconAssetName(isSelected: Bool) -> String {
        switch (self, isSelected) {
        case (.trade, false):
            return "stock_detail_transaction_trade"
        case (.trade, true):
            return "stock_detail_transaction_trade_selected"
        case (.positions, false):
            return "stock_detail_transaction_position"
        case (.positions, true):
            return "stock_detail_transaction_position_selected"
        case (.orders, false):
            return "stock_detail_transaction_order"
        case (.orders, true):
            return "stock_detail_transaction_order_selected"
        case (.history, false):
            return "stock_detail_transaction_history"
        case (.history, true):
            return "stock_detail_transaction_history_selected"
        }
    }

    fileprivate var accessibilityIdentifier: String {
        switch self {
        case .trade:
            return "trade"
        case .positions:
            return "positions"
        case .orders:
            return "orders"
        case .history:
            return "history"
        }
    }
}

/// The single entry point for the stock-detail transaction feature.
///
/// The module owns only the selected tab and the wiring between shared page
/// data and the four focused content views. Each content view keeps its own
/// local interaction state, such as the trade confirmation sheet or order
/// quick actions.
struct StockDetailTransactionModule: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let symbol: StockOrderSymbol
    let positionState: StockDetailTransactionPositionState
    let orders: [StockOrderTodayOrderItem]
    let historyOrders: [StockDetailTransactionHistoryOrderData]
    let onRefresh: () -> Void
    let onOrderConfirmed: (StockOrderConfirmationSide) -> Void
    let onOrderAction: (StockOrderTodayOrderItem, StockOrderTodayOrderAction) -> Void
    let onLoadMore: () -> Void

    @State private var selection: StockDetailTransactionModuleTab?
    @State private var displayedSelection: StockDetailTransactionModuleTab?

    init(
        symbol: StockOrderSymbol,
        positionState: StockDetailTransactionPositionState = .empty,
        orders: [StockOrderTodayOrderItem] = [],
        historyOrders: [StockDetailTransactionHistoryOrderData] = [],
        initialSelection: StockDetailTransactionModuleTab? = nil,
        onRefresh: @escaping () -> Void = {},
        onOrderConfirmed: @escaping (StockOrderConfirmationSide) -> Void = { _ in },
        onOrderAction: @escaping (
            StockOrderTodayOrderItem,
            StockOrderTodayOrderAction
        ) -> Void = { _, _ in },
        onLoadMore: @escaping () -> Void = {}
    ) {
        self.symbol = symbol
        self.positionState = positionState
        self.orders = orders
        self.historyOrders = historyOrders
        self.onRefresh = onRefresh
        self.onOrderConfirmed = onOrderConfirmed
        self.onOrderAction = onOrderAction
        self.onLoadMore = onLoadMore
        _selection = State(initialValue: initialSelection)
        _displayedSelection = State(initialValue: initialSelection)
    }

    var body: some View {
        VStack(spacing: 0) {
            StockDetailTransactionModuleTabBar(selection: tabSelection)
            revealedContent
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionModule")
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch displayedSelection {
        case .trade:
            StockDetailTransactionTrade(
                symbol: symbol,
                onRefresh: onRefresh,
                onOrderConfirmed: onOrderConfirmed
            )

        case .positions:
            StockDetailTransactionPosition(state: positionState)

        case .orders:
            StockDetailTransactionOrders(
                symbol: symbol.id,
                orders: orders,
                onOrderAction: onOrderAction
            )

        case .history:
            StockDetailTransactionHistory(
                symbol: symbol.id,
                orders: historyOrders,
                onLoadMore: onLoadMore
            )

        case nil:
            EmptyView()
        }
    }

    private var revealedContent: some View {
        selectedContent
            .subAssetExpansion(
                isExpanded: selection != nil,
                blurRadius: selection == nil ? 5 : 0
            )
    }

    private var tabSelection: Binding<StockDetailTransactionModuleTab?> {
        Binding(
            get: { selection },
            set: updateSelection
        )
    }

    private func updateSelection(_ newSelection: StockDetailTransactionModuleTab?) {
        let isCurrentlyExpanded = selection != nil
        let shouldBeExpanded = newSelection != nil
        let shouldAnimateExpansionState = isCurrentlyExpanded != shouldBeExpanded

        if shouldAnimateExpansionState {
            withAnimation(
                SubAssetCardMotion.expansion(
                    reduceMotion: accessibilityReduceMotion
                )
            ) {
                if let newSelection {
                    displayedSelection = newSelection
                }
                selection = newSelection
            }
            return
        }

        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            if let newSelection {
                displayedSelection = newSelection
            }
            selection = newSelection
        }
    }
}

/// The four-button navigation strip at the top of the stock-detail
/// transaction module.
///
/// It only owns tab selection. The complete module owns the selected content.
struct StockDetailTransactionModuleTabBar: View {
    @Binding private var selection: StockDetailTransactionModuleTab?

    @Environment(\.demoLanguage) private var language

    init(selection: Binding<StockDetailTransactionModuleTab?>) {
        _selection = selection
    }

    var body: some View {
        GeometryReader { geometry in
            let tabWidth = max(
                (
                    geometry.size.width
                        - StockDetailTransactionModuleTabBarLayout.horizontalPadding * 2
                        - StockDetailTransactionModuleTabBarLayout.tabSpacing
                            * CGFloat(StockDetailTransactionModuleTab.allCases.count - 1)
                ) / CGFloat(StockDetailTransactionModuleTab.allCases.count),
                0
            )

            HStack(spacing: StockDetailTransactionModuleTabBarLayout.tabSpacing) {
                ForEach(StockDetailTransactionModuleTab.allCases) { tab in
                    tabButton(tab, width: tabWidth)
                }
            }
            .padding(.horizontal, StockDetailTransactionModuleTabBarLayout.horizontalPadding)
            .padding(.vertical, StockDetailTransactionModuleTabBarLayout.verticalPadding)
        }
        .frame(height: StockDetailTransactionModuleTabBarLayout.height)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionModule.tabBar")
    }

    private func tabButton(
        _ tab: StockDetailTransactionModuleTab,
        width: CGFloat
    ) -> some View {
        let isSelected = selection == tab
        let title = tab.title(for: language)

        return Button {
            selection = isSelected ? nil : tab
        } label: {
            HStack(spacing: StockDetailTransactionModuleTabBarLayout.iconToTitleSpacing) {
                Image(tab.iconAssetName(isSelected: isSelected))
                    .resizable()
                    .frame(
                        width: StockDetailTransactionModuleTabBarLayout.iconSize,
                        height: StockDetailTransactionModuleTabBarLayout.iconSize
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailTransactionModuleTabBarLayout.titleFontSize,
                            font: isSelected ? .medium : .regular,
                            lineHeight: StockDetailTransactionModuleTabBarLayout.titleLineHeight
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(StockDetailTransactionModuleTabBarLayout.minimumTitleScale)
            }
            .foregroundColor(isSelected ? Color("color-brand-blue") : Color("color-text-30"))
            .padding(.vertical, StockDetailTransactionModuleTabBarLayout.buttonVerticalPadding)
            .frame(
                width: width,
                height: StockDetailTransactionModuleTabBarLayout.buttonHeight
            )
            .background(
                isSelected
                    ? Color("color-brand-blue").opacity(StockDetailTransactionModuleTabBarLayout.selectedBackgroundOpacity)
                    : Color("color-base-1"),
                in: RoundedRectangle(
                    cornerRadius: StockDetailTransactionModuleTabBarLayout.cornerRadius,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: StockDetailTransactionModuleTabBarLayout.cornerRadius,
                    style: .continuous
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("stockDetail.transactionModule.tab.\(tab.accessibilityIdentifier)")
    }
}

private enum StockDetailTransactionModuleTabBarLayout {
    static let height: CGFloat = 64
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 16
    static let tabSpacing: CGFloat = 8
    static let buttonHeight: CGFloat = 32
    static let buttonVerticalPadding: CGFloat = 6
    static let iconSize: CGFloat = 16
    static let iconToTitleSpacing: CGFloat = 4
    static let titleFontSize: CGFloat = 14
    static let titleLineHeight: CGFloat = 20
    static let minimumTitleScale: CGFloat = 0.5
    static let cornerRadius: CGFloat = 8
    static let selectedBackgroundOpacity: CGFloat = 0.1
}

private struct StockDetailTransactionModuleTabBarPreviewHarness: View {
    @State private var selection: StockDetailTransactionModuleTab?

    init(initialSelection: StockDetailTransactionModuleTab? = nil) {
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        StockDetailTransactionModuleTabBar(selection: $selection)
    }
}

struct StockDetailTransactionModuleTabBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionModuleTabBarPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("简体中文 · 未选择")

            StockDetailTransactionModuleTabBarPreviewHarness(initialSelection: .history)
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("English · History")
        }
        .previewLayout(.fixed(width: 402, height: 64))
    }
}

private struct StockDetailTransactionModulePreviewHarness: View {
    let initialSelection: StockDetailTransactionModuleTab?

    @State private var latestAction = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            StockDetailTransactionModule(
                symbol: StockDetailTransactionModulePreviewData.symbol,
                positionState: .position(StockDetailTransactionModulePreviewData.position),
                orders: StockDetailTransactionModulePreviewData.orders,
                historyOrders: StockDetailTransactionModulePreviewData.historyOrders,
                initialSelection: initialSelection,
                onRefresh: {
                    latestAction = "refresh"
                },
                onOrderConfirmed: { side in
                    latestAction = side == .buy ? "buy-confirmed" : "sell-confirmed"
                },
                onOrderAction: { _, action in
                    latestAction = action.rawValue
                },
                onLoadMore: {
                    latestAction = "load-more"
                }
            )
        }
        .background(Color("color-base-1"))
    }
}

private enum StockDetailTransactionModulePreviewData {
    static let symbol: StockOrderSymbol = {
        guard let symbol = StockOrderDemoViewModel.searchableSymbols.first(where: { $0.id == "NVDA" }) else {
            preconditionFailure("Missing NVDA preview symbol")
        }

        return symbol
    }()

    static let position = StockDetailTransactionPositionData(
        positionProfitLoss: "+6,100.00",
        positionProfitLossRate: "+9.53%",
        todayProfitLoss: "+1,123.01",
        quantity: "1,500",
        marketValue: "70,100.00",
        costPrice: "293.320",
        portfolioWeight: "8.38%",
        positionProfitLossTone: .gain,
        todayProfitLossTone: .gain
    )

    static let orders: [StockOrderTodayOrderItem] = [
        StockOrderTodayOrderItem(
            id: "module-nvda-submitted",
            side: .buy,
            status: .submitted,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "131.700",
            quantity: "500",
            filledQuantity: "0"
        ),
        StockOrderTodayOrderItem(
            id: "module-nvda-partial",
            side: .sell,
            status: .partiallyFilled,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "132.100",
            quantity: "1,000",
            filledQuantity: "500"
        ),
        StockOrderTodayOrderItem(
            id: "module-unrelated-tsla",
            side: .buy,
            status: .pending,
            productName: "Tesla",
            symbol: "TSLA",
            price: "320.000",
            quantity: "200",
            filledQuantity: "0"
        )
    ]

    static let historyOrders: [StockDetailTransactionHistoryOrderData] = [
        StockDetailTransactionHistoryOrderData(
            id: "module-history-nvda-filled",
            side: .buy,
            status: .filled,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "128.500",
            quantity: "500",
            orderDate: "26/08/28",
            orderTime: "14:37:06"
        ),
        StockDetailTransactionHistoryOrderData(
            id: "module-history-nvda-cancelled",
            side: .sell,
            status: .cancelled,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "130.200",
            quantity: "200",
            orderDate: "26/08/27",
            orderTime: "09:42:18"
        ),
        StockDetailTransactionHistoryOrderData(
            id: "module-history-unrelated-tsla",
            side: .buy,
            status: .filled,
            productName: "Tesla",
            symbol: "TSLA",
            price: "318.000",
            quantity: "100",
            orderDate: "26/08/28",
            orderTime: "10:05:12"
        )
    ]
}

struct StockDetailTransactionModule_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionModulePreviewHarness(initialSelection: nil)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("可交互 · 点击 Tab 展开 / 切换")

            StockDetailTransactionModulePreviewHarness(initialSelection: .trade)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("简体中文 · 交易")

            StockDetailTransactionModulePreviewHarness(initialSelection: .positions)
                .environment(\.demoLanguage, .traditionalChinese)
                .previewDisplayName("繁體中文 · 持倉")

            StockDetailTransactionModulePreviewHarness(initialSelection: .orders)
                .environment(\.demoLanguage, .english)
                .previewDisplayName("English · Orders")

            StockDetailTransactionModulePreviewHarness(initialSelection: .history)
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("English · History · Dark")
        }
        .previewLayout(.fixed(width: 402, height: 720))
    }
}
