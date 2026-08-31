//
//  StockDetailTransactionHistory.swift
//  SuperPreview
//

import SwiftUI

/// The stock-detail history tab.
///
/// The caller supplies historical (terminal) orders for all products. This
/// view narrows them to the symbol being displayed, then renders the shared
/// non-expandable history-order row.
struct StockDetailTransactionHistory: View {
    let symbol: String
    let orders: [StockDetailTransactionHistoryOrderData]
    let onLoadMore: (() -> Void)?

    @Environment(\.demoLanguage) private var language

    init(
        symbol: String,
        orders: [StockDetailTransactionHistoryOrderData],
        onLoadMore: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.orders = orders
        self.onLoadMore = onLoadMore
    }

    var body: some View {
        VStack(spacing: 0) {
            if filteredOrders.isEmpty {
                emptyState
            } else {
                tableHeader

                ForEach(filteredOrders) { order in
                    StockDetailTransactionHistoryOrder(order: order)
                }

                moreButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color("color-base-1"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("color-separator-10"))
                .frame(height: StockDetailTransactionHistoryLayout.separatorHeight)
                .padding(.horizontal, StockDetailTransactionHistoryLayout.horizontalPadding)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionHistory")
    }

    private var tableHeader: some View {
        GeometryReader { geometry in
            let sectionWidth = geometry.size.width / 2

            HStack(spacing: 0) {
                HStack(spacing: StockDetailTransactionHistoryLayout.headerColumnSpacing) {
                    Text(historyStatusHeaderTitle)
                        .modifier(headerTextModifier)
                        .frame(
                            width: StockDetailTransactionHistoryLayout.headerStatusWidth,
                            alignment: .leading
                        )

                    Text(language.text(.symbolHeader))
                        .modifier(headerTextModifier)
                        .frame(
                            width: StockDetailTransactionHistoryLayout.headerNameWidth,
                            alignment: .leading
                        )
                }
                .foregroundColor(Color("color-text-60"))
                .padding(.leading, StockDetailTransactionHistoryLayout.horizontalPadding)
                .frame(width: sectionWidth, alignment: .leading)

                HStack(spacing: StockDetailTransactionHistoryLayout.headerColumnSpacing) {
                    Text(historyPriceQuantityHeaderTitle)
                        .modifier(headerTextModifier)
                        .frame(
                            width: StockDetailTransactionHistoryLayout.headerPriceWidth,
                            alignment: .trailing
                        )

                    Text(historyOrderTimeHeaderTitle)
                        .modifier(headerTextModifier)
                        .frame(
                            width: StockDetailTransactionHistoryLayout.headerTimeWidth,
                            alignment: .trailing
                        )
                }
                .foregroundColor(Color("color-text-60"))
                .padding(.trailing, StockDetailTransactionHistoryLayout.horizontalPadding)
                .frame(width: sectionWidth, alignment: .trailing)
            }
        }
        .frame(height: StockDetailTransactionHistoryLayout.headerHeight)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionHistory.header")
    }

    private var moreButton: some View {
        Button {
            onLoadMore?()
        } label: {
            HStack(spacing: StockDetailTransactionHistoryLayout.moreContentSpacing) {
                Text(moreTitle)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailTransactionHistoryLayout.moreFontSize,
                            font: .regular,
                            lineHeight: StockDetailTransactionHistoryLayout.moreLineHeight
                        )
                    )
                    .foregroundColor(Color("color-text-90"))

                Image("subasset_expand_chevron")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: StockDetailTransactionHistoryLayout.moreIconSize,
                        height: StockDetailTransactionHistoryLayout.moreIconSize
                    )
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: StockDetailTransactionHistoryLayout.moreRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(moreTitle)
        .accessibilityIdentifier("stockDetail.transactionHistory.more")
    }

    private var emptyState: some View {
        VStack(spacing: StockDetailTransactionHistoryLayout.emptyStateSpacing) {
            Image("empty_portfolio")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockDetailTransactionHistoryLayout.emptyStateImageWidth,
                    height: StockDetailTransactionHistoryLayout.emptyStateImageHeight
                )
                .accessibilityHidden(true)

            Text(emptyTitle)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionHistoryLayout.emptyStateFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionHistoryLayout.emptyStateLineHeight
                    )
                )
                .foregroundColor(Color("color-text-60"))
        }
        .frame(
            maxWidth: .infinity,
            minHeight: StockDetailTransactionHistoryLayout.emptyStateHeight,
            maxHeight: StockDetailTransactionHistoryLayout.emptyStateHeight
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.transactionHistory.empty")
    }

    private var filteredOrders: [StockDetailTransactionHistoryOrderData] {
        let normalizedSymbol = normalized(symbol)

        return orders.filter { order in
            normalized(order.symbol) == normalizedSymbol
        }
    }

    private var moreTitle: String {
        switch language {
        case .simplifiedChinese:
            "查看更多"
        case .traditionalChinese:
            "查看更多"
        case .english:
            "View More"
        }
    }

    private var emptyTitle: String {
        switch language {
        case .simplifiedChinese:
            "暂无历史订单"
        case .traditionalChinese:
            "暫無歷史訂單"
        case .english:
            "No historical orders"
        }
    }

    private var historyStatusHeaderTitle: String {
        switch language {
        case .simplifiedChinese:
            "交易状态"
        case .traditionalChinese:
            "交易狀態"
        case .english:
            "Status"
        }
    }

    private var historyPriceQuantityHeaderTitle: String {
        switch language {
        case .simplifiedChinese:
            "价格/数量"
        case .traditionalChinese:
            "價格/數量"
        case .english:
            "Price/Qty"
        }
    }

    private var historyOrderTimeHeaderTitle: String {
        switch language {
        case .simplifiedChinese:
            "下单时间"
        case .traditionalChinese:
            "下單時間"
        case .english:
            "Order Time"
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private var headerTextModifier: CustomFontModifier {
        CustomFontModifier(
            size: StockDetailTransactionHistoryLayout.headerFontSize,
            font: .regular,
            lineHeight: StockDetailTransactionHistoryLayout.headerLineHeight
        )
    }
}

private enum StockDetailTransactionHistoryLayout {
    static let horizontalPadding: CGFloat = 16
    static let separatorHeight: CGFloat = 0.5

    static let headerHeight: CGFloat = 32
    static let headerFontSize: CGFloat = 12
    static let headerLineHeight: CGFloat = 16
    static let headerStatusWidth: CGFloat = 85
    static let headerNameWidth: CGFloat = 92
    static let headerPriceWidth: CGFloat = 90
    static let headerTimeWidth: CGFloat = 87
    static let headerColumnSpacing: CGFloat = 8

    static let moreRowHeight: CGFloat = 52
    static let moreContentSpacing: CGFloat = 4
    static let moreFontSize: CGFloat = 14
    static let moreLineHeight: CGFloat = 20
    static let moreIconSize: CGFloat = 16

    static let emptyStateHeight: CGFloat = 180
    static let emptyStateImageWidth: CGFloat = 64
    static let emptyStateImageHeight: CGFloat = 56
    static let emptyStateSpacing: CGFloat = 12
    static let emptyStateFontSize: CGFloat = 14
    static let emptyStateLineHeight: CGFloat = 20
}

private struct StockDetailTransactionHistoryPreviewHarness: View {
    let symbol: String
    let orders: [StockDetailTransactionHistoryOrderData]

    @State private var selection: StockDetailTransactionModuleTab? = .history
    @State private var hasLoadedMore = false

    var body: some View {
        VStack(spacing: 0) {
            StockDetailTransactionModuleTabBar(selection: $selection)
                .allowsHitTesting(false)

            StockDetailTransactionHistory(
                symbol: symbol,
                orders: orders,
                onLoadMore: { hasLoadedMore = true }
            )
        }
        .background(Color("color-base-1"))
        .overlay(alignment: .bottomTrailing) {
            Text(hasLoadedMore ? "loaded" : "")
                .font(.caption2)
                .foregroundColor(.clear)
                .accessibilityHidden(true)
        }
    }
}

private enum StockDetailTransactionHistoryPreviewData {
    static func orders(productName: String) -> [StockDetailTransactionHistoryOrderData] {
        let statuses: [(StockOrderTodayOrderStatus, String, String, String)] = [
            (.pending, "2,000", "26/04/23", "14:37:06"),
            (.submitted, "2,000", "26/08/28", "14:37:06"),
            (.partiallyFilled, "1,000", "26/08/28", "14:37:06"),
            (.filled, "2,000", "26/08/28", "14:37:06"),
            (.failed, "2,000", "26/08/28", "14:37:06"),
            (.expired, "0", "26/08/28", "14:37:06"),
            (.cancelled, "0", "26/08/28", "14:37:06")
        ]

        let matchingOrders = statuses.enumerated().map { index, item in
            StockDetailTransactionHistoryOrderData(
                id: "history-tsla-\(index)",
                side: .buy,
                status: item.0,
                productName: productName,
                symbol: "TSLA",
                price: "16.390",
                quantity: item.1,
                orderDate: item.2,
                orderTime: item.3
            )
        }

        let unrelatedOrder = StockDetailTransactionHistoryOrderData(
            id: "history-nvda",
            side: .sell,
            status: .filled,
            productName: "NVIDIA",
            symbol: "NVDA",
            price: "131.70",
            quantity: "500",
            orderDate: "26/08/28",
            orderTime: "14:37:06"
        )

        return matchingOrders + [unrelatedOrder]
    }
}

struct StockDetailTransactionHistory_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionHistoryPreviewHarness(
                symbol: "TSLA",
                orders: StockDetailTransactionHistoryPreviewData.orders(productName: "特斯拉")
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("简体中文 · 历史订单")
            .previewLayout(.fixed(width: 402, height: 582))

            StockDetailTransactionHistoryPreviewHarness(
                symbol: "TSLA",
                orders: StockDetailTransactionHistoryPreviewData.orders(productName: "Tesla")
            )
            .environment(\.demoLanguage, .english)
            .previewDisplayName("English · History")
            .previewLayout(.fixed(width: 402, height: 582))

            StockDetailTransactionHistoryPreviewHarness(
                symbol: "AAPL",
                orders: StockDetailTransactionHistoryPreviewData.orders(productName: "特斯拉")
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("暂无当前标的历史订单")
            .previewLayout(.fixed(width: 402, height: 244))
        }
    }
}
