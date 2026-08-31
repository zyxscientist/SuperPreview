//
//  StockDetailTransactionOrders.swift
//  SuperPreview
//

import SwiftUI

/// Today's orders displayed for the selected symbol in the stock-detail
/// transaction module.
///
/// The order-page row remains the single source of truth for order status,
/// quick actions, and their expansion treatment. This detail-page container
/// only scopes that shared data to the symbol currently being viewed.
struct StockDetailTransactionOrders: View {
    let symbol: String
    let orders: [StockOrderTodayOrderItem]
    let onOrderAction: (StockOrderTodayOrderItem, StockOrderTodayOrderAction) -> Void

    @State private var expandedOrderID: StockOrderTodayOrderItem.ID?

    @Environment(\.demoLanguage) private var language

    init(
        symbol: String,
        orders: [StockOrderTodayOrderItem],
        onOrderAction: @escaping (
            StockOrderTodayOrderItem,
            StockOrderTodayOrderAction
        ) -> Void = { _, _ in }
    ) {
        self.symbol = symbol
        self.orders = orders
        self.onOrderAction = onOrderAction
    }

    var body: some View {
        VStack(spacing: 0) {
            if symbolOrders.isEmpty {
                emptyState
                    .padding(.top, StockDetailTransactionOrdersLayout.contentTopPadding)
            } else {
                VStack(spacing: 0) {
                    tableHeader

                    // This list remains intentionally non-lazy. It is small in
                    // the prototype, and a fixed stack avoids remeasurement
                    // jumps while an order exposes its quick actions.
                    ForEach(symbolOrders) { order in
                        StockOrderTodayOrder(
                            isActionGroupExpanded: orderExpansionBinding(for: order.id),
                            side: order.side,
                            status: order.status,
                            productName: order.productName,
                            symbol: order.symbol,
                            price: order.price,
                            quantity: order.quantity,
                            filledQuantity: order.filledQuantity,
                            tag: order.tag,
                            showsStatusIcon: order.showsStatusIcon,
                            actions: order.actions
                        ) { action in
                            onOrderAction(order, action)
                        }
                    }
                }
                .padding(.top, StockDetailTransactionOrdersLayout.contentTopPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color("color-base-1"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("color-separator-10"))
                .frame(height: StockDetailTransactionOrdersLayout.separatorHeight)
                .padding(.horizontal, StockDetailTransactionOrdersLayout.horizontalPadding)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionOrders")
    }

    private var tableHeader: some View {
        GeometryReader { geometry in
            let sectionWidth = geometry.size.width / 2

            HStack(spacing: 0) {
                HStack(spacing: StockDetailTransactionOrdersLayout.headerColumnSpacing) {
                    HStack(spacing: StockDetailTransactionOrdersLayout.headerStatusSpacing) {
                        Text(language.text(.orderStatusHeader))
                            .modifier(
                                CustomFontModifier(
                                    size: StockDetailTransactionOrdersLayout.headerFontSize,
                                    font: .regular,
                                    lineHeight: StockDetailTransactionOrdersLayout.headerLineHeight
                                )
                            )
                            .foregroundColor(Color("color-text-60"))
                            .lineLimit(1)

                        Image("stock_order_chevron_down")
                            .scaledToFit()
                            .frame(
                                width: StockDetailTransactionOrdersLayout.headerSortIconWidth,
                                height: StockDetailTransactionOrdersLayout.headerSortIconHeight
                            )
                            .accessibilityHidden(true)
                    }
                    .frame(
                        width: StockDetailTransactionOrdersLayout.headerStatusWidth,
                        alignment: .leading
                    )

                    Text(language.text(.symbolHeader))
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailTransactionOrdersLayout.headerFontSize,
                                font: .regular,
                                lineHeight: StockDetailTransactionOrdersLayout.headerLineHeight
                            )
                        )
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)
                        .frame(
                            width: StockDetailTransactionOrdersLayout.headerNameWidth,
                            alignment: .leading
                        )
                }
                .padding(.leading, StockDetailTransactionOrdersLayout.horizontalPadding)
                .frame(width: sectionWidth, alignment: .leading)

                HStack(spacing: StockDetailTransactionOrdersLayout.headerColumnSpacing) {
                    Text(language.text(.orderPriceHeader))
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailTransactionOrdersLayout.headerFontSize,
                                font: .regular,
                                lineHeight: StockDetailTransactionOrdersLayout.headerLineHeight
                            )
                        )
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)
                        .frame(
                            width: StockDetailTransactionOrdersLayout.headerPriceWidth,
                            alignment: .trailing
                        )

                    Text(language.text(.quantityFilledHeader))
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailTransactionOrdersLayout.headerFontSize,
                                font: .regular,
                                lineHeight: StockDetailTransactionOrdersLayout.headerLineHeight
                            )
                        )
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)
                        .frame(
                            width: StockDetailTransactionOrdersLayout.headerQuantityWidth,
                            alignment: .trailing
                        )
                }
                .padding(.trailing, StockDetailTransactionOrdersLayout.horizontalPadding)
                .frame(width: sectionWidth, alignment: .trailing)
            }
        }
        .frame(height: StockDetailTransactionOrdersLayout.headerHeight)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionOrders.header")
    }

    private var emptyState: some View {
        VStack(spacing: StockDetailTransactionOrdersLayout.emptyStateSpacing) {
            Image("empty_portfolio")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockDetailTransactionOrdersLayout.emptyStateImageWidth,
                    height: StockDetailTransactionOrdersLayout.emptyStateImageHeight
                )
                .accessibilityHidden(true)

            Text(language.text(.noTodayOrders))
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionOrdersLayout.emptyStateFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionOrdersLayout.emptyStateLineHeight
                    )
                )
                .foregroundColor(Color("color-text-60"))
        }
        .frame(
            maxWidth: .infinity,
            minHeight: StockDetailTransactionOrdersLayout.emptyStateHeight,
            maxHeight: StockDetailTransactionOrdersLayout.emptyStateHeight
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.transactionOrders.empty")
    }

    /// The detail page always receives the complete order data set, then limits
    /// it to the single product represented by this page.
    private var symbolOrders: [StockOrderTodayOrderItem] {
        let normalizedSymbol = normalized(symbol)

        return orders.filter { order in
            normalized(order.symbol) == normalizedSymbol
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
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

private enum StockDetailTransactionOrdersLayout {
    static let horizontalPadding: CGFloat = 16
    static let contentTopPadding: CGFloat = 0
    static let separatorHeight: CGFloat = 0.5

    static let headerHeight: CGFloat = 32
    static let headerFontSize: CGFloat = 12
    static let headerLineHeight: CGFloat = 16
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
    static let emptyStateFontSize: CGFloat = 14
    static let emptyStateLineHeight: CGFloat = 20
}

private struct StockDetailTransactionOrdersPreviewHarness: View {
    let symbol: String
    let orders: [StockOrderTodayOrderItem]

    @State private var selection: StockDetailTransactionModuleTab? = .orders
    @State private var latestAction = ""

    var body: some View {
        VStack(spacing: 0) {
            StockDetailTransactionModuleTabBar(selection: $selection)
                .allowsHitTesting(false)

            StockDetailTransactionOrders(symbol: symbol, orders: orders) { _, action in
                latestAction = action.rawValue
            }
        }
        .background(Color("color-base-1"))
        .overlay(alignment: .bottomTrailing) {
            Text(latestAction)
                .font(.caption2)
                .foregroundColor(.clear)
                .accessibilityHidden(true)
        }
    }
}

private enum StockDetailTransactionOrdersPreviewData {
    static func teslaOrders(productName: String) -> [StockOrderTodayOrderItem] {
        let teslaOrders = StockOrderTodayOrderStatus.allCases.enumerated().map { index, status in
            StockOrderTodayOrderItem(
                id: "tesla-\(status.rawValue)",
                side: .buy,
                status: status,
                productName: productName,
                symbol: "TSLA",
                price: "16.390",
                quantity: "2,000",
                filledQuantity: status == .filled ? "2,000" : (status == .partiallyFilled ? "1,000" : "0"),
                tag: status == .pending ? "条件" : nil
            )
        }

        // It intentionally comes in with the source list, but never reaches
        // the detail page because the page currently represents TSLA only.
        let unrelatedOrder = StockOrderTodayOrderItem(
            id: "nvidia-submitted",
            side: .sell,
            status: .submitted,
            productName: "NVIDIA",
            symbol: "NVDA",
            price: "131.70",
            quantity: "500",
            filledQuantity: "0"
        )

        return teslaOrders + [unrelatedOrder]
    }
}

struct StockDetailTransactionOrders_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionOrdersPreviewHarness(
                symbol: "TSLA",
                orders: StockDetailTransactionOrdersPreviewData.teslaOrders(productName: "特斯拉")
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("简体中文 · 特斯拉订单")
            .previewLayout(.fixed(width: 402, height: 547))

            StockDetailTransactionOrdersPreviewHarness(
                symbol: "TSLA",
                orders: StockDetailTransactionOrdersPreviewData.teslaOrders(productName: "Tesla")
            )
            .environment(\.demoLanguage, .english)
            .previewDisplayName("English · Tesla Orders")
            .previewLayout(.fixed(width: 402, height: 547))

            StockDetailTransactionOrdersPreviewHarness(
                symbol: "AAPL",
                orders: StockDetailTransactionOrdersPreviewData.teslaOrders(productName: "特斯拉")
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("暂无当前标的订单")
            .previewLayout(.fixed(width: 402, height: 260))
        }
    }
}
