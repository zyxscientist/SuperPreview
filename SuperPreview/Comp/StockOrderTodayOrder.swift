//
//  StockOrderTodayOrder.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderTodayOrderSide: String, Hashable {
    case buy
    case sell

    fileprivate var titleKey: DemoCopyKey {
        self == .buy ? .buy : .sell
    }

    fileprivate var color: Color {
        self == .buy ? Color("color-utility3-red") : Color("color-utility3-green")
    }
}

enum StockOrderTodayOrderStatus: String, CaseIterable, Hashable {
    case pending
    case submitted
    case partiallyFilled
    case filled
    case failed
    case expired
    case cancelled

    fileprivate var titleKey: DemoCopyKey {
        switch self {
        case .pending: .orderPendingSubmission
        case .submitted: .orderPendingFill
        case .partiallyFilled: .orderPartiallyFilled
        case .filled: .orderFilled
        case .failed: .orderFailed
        case .expired: .orderExpired
        case .cancelled: .orderCancelled
        }
    }

    fileprivate var iconAssetName: String {
        switch self {
        case .pending, .submitted: "stock_order_today_pending"
        case .partiallyFilled: "stock_order_today_processing"
        case .filled: "stock_order_today_filled"
        case .failed: "stock_order_today_failed"
        case .expired: "stock_order_today_invalid"
        case .cancelled: "stock_order_today_revoke"
        }
    }
}

enum StockOrderTodayOrderAction: String, CaseIterable, Hashable, Identifiable {
    case quote
    case amend
    case cancel
    case details

    var id: String { rawValue }

    fileprivate var titleKey: DemoCopyKey {
        switch self {
        case .quote: .quote
        case .amend: .amendOrder
        case .cancel: .cancelOrder
        case .details: .details
        }
    }
}

/// Formatted order data displayed by `StockOrderOrdersAndPositions`.
///
/// All values are presentation-ready so the container stays independent from
/// quote, order-status, and number-formatting services.
struct StockOrderTodayOrderItem: Identifiable {
    let id: String
    let side: StockOrderTodayOrderSide
    let status: StockOrderTodayOrderStatus
    let productName: String
    let symbol: String
    let price: String
    let quantity: String
    let filledQuantity: String
    let tag: String?
    let showsStatusIcon: Bool
    let actions: [StockOrderTodayOrderAction]

    init(
        id: String,
        side: StockOrderTodayOrderSide,
        status: StockOrderTodayOrderStatus,
        productName: String,
        symbol: String,
        price: String,
        quantity: String,
        filledQuantity: String,
        tag: String? = nil,
        showsStatusIcon: Bool = true,
        actions: [StockOrderTodayOrderAction] = StockOrderTodayOrderAction.allCases
    ) {
        self.id = id
        self.side = side
        self.status = status
        self.productName = productName
        self.symbol = symbol
        self.price = price
        self.quantity = quantity
        self.filledQuantity = filledQuantity
        self.tag = tag
        self.showsStatusIcon = showsStatusIcon
        self.actions = actions
    }
}

/// A single row in the stock-order page's Today Orders section.
///
/// The parent provides all formatted market data. This demo currently exposes
/// every action for every status; action availability will be refined later.
struct StockOrderTodayOrder: View {
    @Binding var isActionGroupExpanded: Bool

    let side: StockOrderTodayOrderSide
    let status: StockOrderTodayOrderStatus
    let productName: String
    let symbol: String
    let price: String
    let quantity: String
    let filledQuantity: String
    let tag: String?
    let showsStatusIcon: Bool
    let actions: [StockOrderTodayOrderAction]
    let onAction: (StockOrderTodayOrderAction) -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        isActionGroupExpanded: Binding<Bool> = .constant(false),
        side: StockOrderTodayOrderSide,
        status: StockOrderTodayOrderStatus,
        productName: String,
        symbol: String,
        price: String,
        quantity: String,
        filledQuantity: String,
        tag: String? = nil,
        showsStatusIcon: Bool = true,
        actions: [StockOrderTodayOrderAction] = StockOrderTodayOrderAction.allCases,
        onAction: @escaping (StockOrderTodayOrderAction) -> Void = { _ in }
    ) {
        _isActionGroupExpanded = isActionGroupExpanded
        self.side = side
        self.status = status
        self.productName = productName
        self.symbol = symbol
        self.price = price
        self.quantity = quantity
        self.filledQuantity = filledQuantity
        self.tag = tag
        self.showsStatusIcon = showsStatusIcon
        self.actions = actions
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: 0) {
            orderSummary

            actionGroup
                .subAssetExpansion(
                    isExpanded: isActionGroupExpanded,
                    blurRadius: isActionGroupExpanded ? 0 : 5
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .animation(
            SubAssetCardMotion.expansion(reduceMotion: reduceMotion),
            value: isActionGroupExpanded
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.todayOrder")
    }

    private var orderSummary: some View {
        Button(action: toggleActionGroup) {
            HStack(spacing: 0) {
                HStack(spacing: StockOrderTodayOrderLayout.majorColumnSpacing) {
                    sideAndStatus
                    productInformation
                }
                .frame(width: StockOrderTodayOrderLayout.leftAreaWidth, alignment: .leading)

                HStack(spacing: StockOrderTodayOrderLayout.majorColumnSpacing) {
                    Text(price)
                        .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                        .monospacedDigit()
                        .foregroundColor(Color("color-text-30"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(
                            width: StockOrderTodayOrderLayout.priceWidth,
                            height: StockOrderTodayOrderLayout.informationHeight,
                            alignment: .trailing
                        )

                    quantityInformation
                }
                .frame(width: StockOrderTodayOrderLayout.rightAreaWidth, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderTodayOrderLayout.summaryHeight,
            maxHeight: StockOrderTodayOrderLayout.summaryHeight,
            alignment: .leading
        )
        .accessibilityLabel(accessibilitySummary)
        .accessibilityValue(
            language.text(isActionGroupExpanded ? .expanded : .collapsed)
        )
        .accessibilityHint(
            language.text(
                isActionGroupExpanded ? .collapseQuickActions : .expandQuickActions
            )
        )
        .accessibilityIdentifier("stockOrder.todayOrder.summary")
    }

    private var sideAndStatus: some View {
        VStack(alignment: .leading, spacing: StockOrderTodayOrderLayout.rowSpacing) {
            HStack(spacing: StockOrderTodayOrderLayout.sideTagSpacing) {
                Text(language.text(side.titleKey))
                    .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                    .foregroundColor(side.color)
                    .lineLimit(1)

                if let tag, !tag.isEmpty {
                    Text(tag)
                        .modifier(CustomFontModifier(size: 10, font: .regular, lineHeight: 12))
                        .foregroundColor(Color("color-brand-blue"))
                        .padding(.horizontal, StockOrderTodayOrderLayout.tagHorizontalPadding)
                        .padding(.vertical, StockOrderTodayOrderLayout.tagVerticalPadding)
                        .background(Color("color-brand-blue").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                }
            }

            HStack(spacing: StockOrderTodayOrderLayout.statusIconSpacing) {
                if showsStatusIcon {
                    Image(status.iconAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockOrderTodayOrderLayout.statusIconSize,
                            height: StockOrderTodayOrderLayout.statusIconSize
                        )
                        .accessibilityHidden(true)
                }

                Text(language.text(status.titleKey))
                    .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.leading, StockOrderTodayOrderLayout.horizontalPadding)
        .padding(.vertical, StockOrderTodayOrderLayout.summaryVerticalPadding)
        .frame(width: StockOrderTodayOrderLayout.sideAndStatusWidth, alignment: .leading)
    }

    private var productInformation: some View {
        VStack(alignment: .leading, spacing: StockOrderTodayOrderLayout.rowSpacing) {
            Text(productName)
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(symbol)
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(width: StockOrderTodayOrderLayout.productWidth, alignment: .leading)
    }

    private var quantityInformation: some View {
        VStack(alignment: .trailing, spacing: StockOrderTodayOrderLayout.rowSpacing) {
            Text(quantity)
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .monospacedDigit()
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(filledQuantity)
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .monospacedDigit()
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(.trailing, StockOrderTodayOrderLayout.horizontalPadding)
        .frame(width: StockOrderTodayOrderLayout.quantityWidth, alignment: .trailing)
    }

    private var actionGroup: some View {
        HStack(spacing: StockOrderTodayOrderLayout.actionSpacing) {
            ForEach(Array(displayedActions.enumerated()), id: \.element.id) { index, action in
                actionButton(action, position: actionPosition(index: index))
            }
        }
        .padding(.horizontal, StockOrderTodayOrderLayout.horizontalPadding)
        .padding(.top, StockOrderTodayOrderLayout.actionTopPadding)
        .padding(.bottom, StockOrderTodayOrderLayout.actionBottomPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.todayOrder.actions")
    }

    private func actionButton(
        _ action: StockOrderTodayOrderAction,
        position: StockOrderTodayOrderActionPosition
    ) -> some View {
        Button {
            onAction(action)
        } label: {
            Text(language.text(action.titleKey))
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderTodayOrderLayout.actionHeight,
                    maxHeight: StockOrderTodayOrderLayout.actionHeight
                )
                .background(Color("color-scale-2"))
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: position.cornerRadii,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(
            language.actionAccessibilityLabel(name: productName, action: language.text(action.titleKey))
        )
        .accessibilityIdentifier("stockOrder.todayOrder.action.\(action.rawValue)")
    }

    private var accessibilitySummary: String {
        [
            language.text(side.titleKey),
            language.text(status.titleKey),
            productName,
            symbol,
            price,
            quantity,
            filledQuantity
        ].joined(separator: ", ")
    }

    private var displayedActions: [StockOrderTodayOrderAction] {
        actions.isEmpty ? StockOrderTodayOrderAction.allCases : actions
    }

    private func actionPosition(index: Int) -> StockOrderTodayOrderActionPosition {
        guard displayedActions.count > 1 else { return .only }
        if index == 0 { return .leading }
        if index == displayedActions.count - 1 { return .trailing }
        return .middle
    }

    private func toggleActionGroup() {
        withAnimation(SubAssetCardMotion.expansion(reduceMotion: reduceMotion)) {
            isActionGroupExpanded.toggle()
        }
    }
}

private enum StockOrderTodayOrderActionPosition {
    case only
    case leading
    case middle
    case trailing

    var cornerRadii: RectangleCornerRadii {
        switch self {
        case .only:
            RectangleCornerRadii(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12)
        case .leading:
            RectangleCornerRadii(topLeading: 12, bottomLeading: 12, bottomTrailing: 4, topTrailing: 4)
        case .middle:
            RectangleCornerRadii(topLeading: 4, bottomLeading: 4, bottomTrailing: 4, topTrailing: 4)
        case .trailing:
            RectangleCornerRadii(topLeading: 4, bottomLeading: 4, bottomTrailing: 12, topTrailing: 12)
        }
    }
}

private enum StockOrderTodayOrderLayout {
    static let horizontalPadding: CGFloat = 16
    static let summaryHeight: CGFloat = 62
    static let summaryVerticalPadding: CGFloat = 8
    static let informationHeight: CGFloat = 46
    static let leftAreaWidth: CGFloat = 201
    static let rightAreaWidth: CGFloat = 201
    static let sideAndStatusWidth: CGFloat = 91
    static let productWidth: CGFloat = 102
    static let priceWidth: CGFloat = 90
    static let quantityWidth: CGFloat = 103
    static let majorColumnSpacing: CGFloat = 8
    static let rowSpacing: CGFloat = 2
    static let sideTagSpacing: CGFloat = 4
    static let statusIconSpacing: CGFloat = 2
    static let statusIconSize: CGFloat = 12
    static let tagHorizontalPadding: CGFloat = 6
    static let tagVerticalPadding: CGFloat = 2
    static let actionSpacing: CGFloat = 2
    static let actionHeight: CGFloat = 64
    static let actionTopPadding: CGFloat = 8
    static let actionBottomPadding: CGFloat = 16
}

private struct StockOrderTodayOrderPreviewHarness: View {
    @State private var latestAction = ""
    @State private var isSubmittedOrderExpanded = true

    var body: some View {
        VStack(spacing: 12) {
            StockOrderTodayOrder(
                isActionGroupExpanded: $isSubmittedOrderExpanded,
                side: .buy,
                status: .submitted,
                productName: "英伟达",
                symbol: "NVDA",
                price: "16.390",
                quantity: "2,000",
                filledQuantity: "0",
                tag: "条件",
                actions: [.quote, .amend, .cancel, .details]
            ) { latestAction = $0.rawValue }

            StockOrderTodayOrder(
                side: .sell,
                status: .partiallyFilled,
                productName: "NVIDIA",
                symbol: "NVDA",
                price: "16.390",
                quantity: "2,000",
                filledQuantity: "1,000"
            )

            Text(latestAction)
                .font(.caption)
        }
    }
}

struct StockOrderTodayOrder_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderTodayOrderPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese · Actions")

            StockOrderTodayOrder(
                side: .buy,
                status: .cancelled,
                productName: "NVIDIA",
                symbol: "NVDA",
                price: "16.390",
                quantity: "2,000",
                filledQuantity: "0"
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Cancelled")
        }
        .previewLayout(.fixed(width: 402, height: 230))
    }
}
