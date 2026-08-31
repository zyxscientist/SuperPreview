//
//  StockDetailTransactionHistoryOrder.swift
//  SuperPreview
//

import SwiftUI

/// Presentation-ready data for one completed order in a history list.
///
/// The history endpoint is expected to provide terminal orders. Keeping this
/// model separate from today's order data makes the different right-hand
/// columns explicit and gives other history entry points a reusable row.
struct StockDetailTransactionHistoryOrderData: Identifiable, Equatable {
    let id: String
    let side: StockOrderTodayOrderSide
    let status: StockOrderTodayOrderStatus
    let productName: String
    let symbol: String
    let price: String
    let quantity: String
    let orderDate: String
    let orderTime: String
    let tag: String?
    let showsStatusIcon: Bool

    init(
        id: String,
        side: StockOrderTodayOrderSide,
        status: StockOrderTodayOrderStatus,
        productName: String,
        symbol: String,
        price: String,
        quantity: String,
        orderDate: String,
        orderTime: String,
        tag: String? = nil,
        showsStatusIcon: Bool = true
    ) {
        self.id = id
        self.side = side
        self.status = status
        self.productName = productName
        self.symbol = symbol
        self.price = price
        self.quantity = quantity
        self.orderDate = orderDate
        self.orderTime = orderTime
        self.tag = tag
        self.showsStatusIcon = showsStatusIcon
    }
}

/// A non-expandable history-order row shared by stock-detail history lists.
struct StockDetailTransactionHistoryOrder: View {
    let order: StockDetailTransactionHistoryOrderData

    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: StockDetailTransactionHistoryOrderLayout.majorColumnSpacing) {
                sideAndStatus
                productInformation
            }
            .frame(
                width: StockDetailTransactionHistoryOrderLayout.leftAreaWidth,
                alignment: .leading
            )

            HStack(spacing: StockDetailTransactionHistoryOrderLayout.majorColumnSpacing) {
                priceAndQuantity
                orderDate
            }
            .frame(
                width: StockDetailTransactionHistoryOrderLayout.rightAreaWidth,
                alignment: .leading
            )
        }
        .frame(
            width: StockDetailTransactionHistoryOrderLayout.rowWidth,
            height: StockDetailTransactionHistoryOrderLayout.rowHeight,
            alignment: .leading
        )
        .background(Color("color-base-1"))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.transactionHistory.order")
    }

    private var sideAndStatus: some View {
        VStack(alignment: .leading, spacing: StockDetailTransactionHistoryOrderLayout.rowSpacing) {
            HStack(spacing: StockDetailTransactionHistoryOrderLayout.sideTagSpacing) {
                Text(language.text(order.side.titleKey))
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailTransactionHistoryOrderLayout.primaryFontSize,
                            font: .regular,
                            lineHeight: StockDetailTransactionHistoryOrderLayout.primaryLineHeight
                        )
                    )
                    .foregroundColor(order.side.color)
                    .lineLimit(1)

                if let tag = order.tag, !tag.isEmpty {
                    Text(tag)
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailTransactionHistoryOrderLayout.tagFontSize,
                                font: .regular,
                                lineHeight: StockDetailTransactionHistoryOrderLayout.tagLineHeight
                            )
                        )
                        .foregroundColor(Color("color-brand-blue"))
                        .padding(.horizontal, StockDetailTransactionHistoryOrderLayout.tagHorizontalPadding)
                        .padding(.vertical, StockDetailTransactionHistoryOrderLayout.tagVerticalPadding)
                        .background(Color("color-brand-blue").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                }
            }

            HStack(spacing: StockDetailTransactionHistoryOrderLayout.statusIconSpacing) {
                if order.showsStatusIcon {
                    Image(order.status.iconAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockDetailTransactionHistoryOrderLayout.statusIconSize,
                            height: StockDetailTransactionHistoryOrderLayout.statusIconSize
                        )
                        .accessibilityHidden(true)
                }

                Text(language.text(order.status.titleKey))
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailTransactionHistoryOrderLayout.statusFontSize,
                            font: .regular,
                            lineHeight: StockDetailTransactionHistoryOrderLayout.statusLineHeight
                        )
                    )
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.leading, StockDetailTransactionHistoryOrderLayout.horizontalPadding)
        .padding(.vertical, StockDetailTransactionHistoryOrderLayout.rowVerticalPadding)
        .frame(
            width: StockDetailTransactionHistoryOrderLayout.sideAndStatusWidth,
            alignment: .leading
        )
    }

    private var productInformation: some View {
        VStack(alignment: .leading, spacing: StockDetailTransactionHistoryOrderLayout.rowSpacing) {
            Text(order.productName)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionHistoryOrderLayout.primaryFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionHistoryOrderLayout.primaryLineHeight
                    )
                )
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(order.symbol)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionHistoryOrderLayout.secondaryFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionHistoryOrderLayout.secondaryLineHeight
                    )
                )
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(
            width: StockDetailTransactionHistoryOrderLayout.productWidth,
            alignment: .leading
        )
    }

    private var priceAndQuantity: some View {
        VStack(alignment: .trailing, spacing: StockDetailTransactionHistoryOrderLayout.rowSpacing) {
            Text(order.price)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionHistoryOrderLayout.primaryFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionHistoryOrderLayout.primaryLineHeight
                    )
                )
                .monospacedDigit()
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(order.quantity)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionHistoryOrderLayout.secondaryFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionHistoryOrderLayout.secondaryLineHeight
                    )
                )
                .monospacedDigit()
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(
            width: StockDetailTransactionHistoryOrderLayout.priceAndQuantityWidth,
            height: StockDetailTransactionHistoryOrderLayout.informationHeight,
            alignment: .trailing
        )
    }

    private var orderDate: some View {
        VStack(alignment: .trailing, spacing: StockDetailTransactionHistoryOrderLayout.rowSpacing) {
            Text(order.orderDate)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionHistoryOrderLayout.primaryFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionHistoryOrderLayout.primaryLineHeight
                    )
                )
                .monospacedDigit()
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(order.orderTime)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionHistoryOrderLayout.secondaryFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionHistoryOrderLayout.secondaryLineHeight
                    )
                )
                .monospacedDigit()
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(.trailing, StockDetailTransactionHistoryOrderLayout.horizontalPadding)
        .frame(
            width: StockDetailTransactionHistoryOrderLayout.orderDateWidth,
            height: StockDetailTransactionHistoryOrderLayout.informationHeight,
            alignment: .trailing
        )
    }
}

private enum StockDetailTransactionHistoryOrderLayout {
    static let rowWidth: CGFloat = 402
    static let rowHeight: CGFloat = 62
    static let horizontalPadding: CGFloat = 16
    static let rowVerticalPadding: CGFloat = 8
    static let leftAreaWidth: CGFloat = 201
    static let rightAreaWidth: CGFloat = 201
    static let sideAndStatusWidth: CGFloat = 101
    static let productWidth: CGFloat = 92
    static let priceAndQuantityWidth: CGFloat = 90
    static let orderDateWidth: CGFloat = 103
    static let informationHeight: CGFloat = 46
    static let majorColumnSpacing: CGFloat = 8
    static let rowSpacing: CGFloat = 2
    static let sideTagSpacing: CGFloat = 4
    static let statusIconSpacing: CGFloat = 2
    static let statusIconSize: CGFloat = 12
    static let tagHorizontalPadding: CGFloat = 6
    static let tagVerticalPadding: CGFloat = 2

    static let primaryFontSize: CGFloat = 16
    static let primaryLineHeight: CGFloat = 24
    static let secondaryFontSize: CGFloat = 14
    static let secondaryLineHeight: CGFloat = 20
    static let statusFontSize: CGFloat = 14
    static let statusLineHeight: CGFloat = 20
    static let tagFontSize: CGFloat = 10
    static let tagLineHeight: CGFloat = 12
}

struct StockDetailTransactionHistoryOrder_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionHistoryOrder(
                order: StockDetailTransactionHistoryOrderData(
                    id: "history-preview",
                    side: .buy,
                    status: .filled,
                    productName: "特斯拉",
                    symbol: "TSLA",
                    price: "16.390",
                    quantity: "2,000",
                    orderDate: "26/08/28",
                    orderTime: "14:37:06"
                )
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("已成交")
            .previewLayout(.fixed(width: 402, height: 62))

            StockDetailTransactionHistoryOrder(
                order: StockDetailTransactionHistoryOrderData(
                    id: "history-preview-english",
                    side: .sell,
                    status: .cancelled,
                    productName: "Tesla",
                    symbol: "TSLA",
                    price: "16.390",
                    quantity: "0",
                    orderDate: "26/08/28",
                    orderTime: "14:37:06"
                )
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Cancelled")
            .previewLayout(.fixed(width: 402, height: 62))
        }
    }
}
