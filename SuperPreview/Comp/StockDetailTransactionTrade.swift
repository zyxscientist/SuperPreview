//
//  StockDetailTransactionTrade.swift
//  SuperPreview
//

import SwiftUI

/// The trade content displayed beneath the stock-detail transaction tabs.
///
/// It shares the stock-order page's market profiles and form logic while
/// deliberately omitting that page's navigation, symbol picker, order book,
/// and legacy floating action bar. The selected symbol determines which order
/// inputs are visible (for example, extended-hours trading for US stocks and
/// decimal quantities for virtual assets).
struct StockDetailTransactionTrade: View {
    let symbol: StockOrderSymbol
    let onRefresh: () -> Void
    let onOrderConfirmed: (StockOrderConfirmationSide) -> Void

    @StateObject private var viewModel: StockOrderDemoViewModel
    @State private var confirmationSide: StockOrderConfirmationSide?
    @State private var focusedInput: StockOrderFormInputFocus?
    @State private var isPriceTargetMenuPresented = false

    @Environment(\.demoLanguage) private var language

    init(
        symbol: StockOrderSymbol,
        onRefresh: @escaping () -> Void = {},
        onOrderConfirmed: @escaping (StockOrderConfirmationSide) -> Void = { _ in }
    ) {
        self.symbol = symbol
        self.onRefresh = onRefresh
        self.onOrderConfirmed = onOrderConfirmed
        _viewModel = StateObject(
            wrappedValue: StockOrderDemoViewModel(initialSelection: symbol)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            accountHeader
            orderForm
            quantityAvailability
            actionButtons
        }
        .background(Color("color-base-1"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("color-separator-10"))
                .frame(height: StockDetailTransactionTradeLayout.separatorHeight)
                .padding(.horizontal, StockDetailTransactionTradeLayout.horizontalPadding)
                .accessibilityHidden(true)
        }
        .interactiveBottomCard(item: $confirmationSide) { side in
            StockOrderConfirmationSheet(
                data: viewModel.confirmationData(for: side, language: language),
                onCancel: {
                    confirmationSide = nil
                },
                onConfirm: {
                    onOrderConfirmed(side)
                    confirmationSide = nil
                }
            )
            .environment(\.demoLanguage, language)
        }
        .onChange(of: symbol) { _, newSymbol in
            guard viewModel.selection != newSymbol else { return }

            viewModel.selection = newSymbol
            viewModel.synchronizeSelection()
            dismissInput()
        }
        .onChange(of: viewModel.orderType) { _, _ in
            dismissInput()
        }
        .onChange(of: viewModel.priceTarget) { _, target in
            viewModel.updatePriceTarget(target)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionTrade")
    }

    private var accountHeader: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: StockDetailTransactionTradeLayout.accountToBuyingPowerSpacing) {
                Text(accountTitle)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailTransactionTradeLayout.accountFontSize,
                            font: .medium,
                            lineHeight: StockDetailTransactionTradeLayout.accountLineHeight
                        )
                    )
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let buyingPower = viewModel.buyingPower {
                    HStack(spacing: StockDetailTransactionTradeLayout.buyingPowerSpacing) {
                        Text("\(language.text(.maximumBuyingPower)):")
                        Text(buyingPower.displayValue)
                    }
                    .foregroundColor(Color("color-text-30"))
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailTransactionTradeLayout.buyingPowerFontSize,
                            font: .regular,
                            lineHeight: StockDetailTransactionTradeLayout.buyingPowerLineHeight
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
            .frame(width: StockDetailTransactionTradeLayout.accountContentWidth, alignment: .leading)

            Spacer(minLength: 0)

            Button(action: onRefresh) {
                Image("refresh-Right")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: StockDetailTransactionTradeLayout.refreshGlyphSize,
                        height: StockDetailTransactionTradeLayout.refreshGlyphSize
                    )
                    .accessibilityHidden(true)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(
                width: StockDetailTransactionTradeLayout.refreshTapSize,
                height: StockDetailTransactionTradeLayout.accountHeaderHeight
            )
            .contentShape(Rectangle())
            .accessibilityLabel(language.text(.refresh))
            .accessibilityIdentifier("stockDetail.transactionTrade.refresh")
        }
        .padding(.horizontal, StockDetailTransactionTradeLayout.horizontalPadding)
        .frame(height: StockDetailTransactionTradeLayout.accountHeaderHeight)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionTrade.account")
    }

    private var orderForm: some View {
        VStack(spacing: StockDetailTransactionTradeLayout.formRowSpacing) {
            StockOrderOrderTypeInput(
                selection: $viewModel.orderType,
                supportedOrderTypes: viewModel.profile.supportedOrderTypes
            )

            if !viewModel.isMarketOrder {
                StockOrderPriceInput(
                    price: $viewModel.price,
                    priceTarget: $viewModel.priceTarget,
                    focusedInput: $focusedInput,
                    isTargetMenuPresented: $isPriceTargetMenuPresented,
                    currentPrice: viewModel.currentPrice,
                    supportedPriceTargets: viewModel.profile.supportedPriceTargets,
                    areNudgeButtonsEnabled: true,
                    onDecrease: viewModel.decreasePrice,
                    onIncrease: viewModel.increasePrice
                )
            }

            StockOrderQuantityInput(
                quantity: $viewModel.quantity,
                quickInputColumns: viewModel.quickInputColumns(language: language),
                focusedInput: $focusedInput,
                inputMode: quantityInputMode,
                areNudgeButtonsEnabled: true,
                showsQuickInputValues: true,
                onDecrease: {
                    dismissInput()
                    viewModel.decreaseQuantity()
                },
                onIncrease: {
                    dismissInput()
                    viewModel.increaseQuantity()
                },
                onQuickInput: { _ in
                    dismissInput()
                }
            )

            StockOrderAmountField(
                price: viewModel.price.isEmpty ? "0" : viewModel.price,
                quantity: viewModel.quantity.isEmpty ? "0" : viewModel.quantity,
                currencyCode: viewModel.profile.currencyCode,
                orderType: viewModel.orderType,
                fractionDigits: 2,
                usesMargin: viewModel.profile.usesMargin && !viewModel.isMarketOrder
            )

            if viewModel.showsExtendedHours {
                StockOrderExtendedHoursInput(selection: $viewModel.extendedHours)
            }

            StockOrderEffectPeriodInput(selection: $viewModel.effectPeriod)
        }
        .padding(.top, StockDetailTransactionTradeLayout.formTopPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionTrade.form")
    }

    private var quantityAvailability: some View {
        StockOrderQuantityAvailability(
            quantity: $viewModel.quantity,
            cashPurchasable: viewModel.profile.cashPurchasable,
            maximumPurchasable: viewModel.profile.maximumPurchasable,
            positionSellable: viewModel.profile.positionSellable,
            onSelect: { _ in
                dismissInput()
            }
        )
        .padding(.top, StockDetailTransactionTradeLayout.availabilityTopPadding)
    }

    private var actionButtons: some View {
        HStack(spacing: StockDetailTransactionTradeLayout.actionButtonSpacing) {
            actionButton(.buy)
            actionButton(.sell)
        }
        .padding(.horizontal, StockDetailTransactionTradeLayout.horizontalPadding)
        .padding(.top, StockDetailTransactionTradeLayout.actionButtonsTopPadding)
        .padding(.bottom, StockDetailTransactionTradeLayout.actionButtonsBottomPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionTrade.actions")
    }

    private func actionButton(_ side: StockOrderConfirmationSide) -> some View {
        let title = language.text(side.titleKey)

        return Button {
            dismissInput()
            confirmationSide = side
        } label: {
            Text(title)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionTradeLayout.actionFontSize,
                        font: .bold,
                        lineHeight: StockDetailTransactionTradeLayout.actionLineHeight
                    )
                )
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, StockDetailTransactionTradeLayout.actionHorizontalPadding)
                .frame(maxWidth: .infinity)
                .frame(height: StockDetailTransactionTradeLayout.actionButtonHeight)
                .background(actionColor(for: side), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityIdentifier("stockDetail.transactionTrade.action.\(side.rawValue)")
    }

    private var accountTitle: String {
        "\(language.text(viewModel.profile.accountTitleKey))(\(viewModel.profile.accountNumber))"
    }

    private var quantityInputMode: StockOrderQuantityInputMode {
        switch viewModel.profile.quantityInputMode {
        case .wholeNumber:
            return .wholeNumber
        case let .decimal(maxFractionDigits, _):
            return .decimal(
                maxFractionDigits: maxFractionDigits,
                placeholder: String(
                    format: language.text(.minimumQuantity),
                    "0.00001"
                )
            )
        }
    }

    private func actionColor(for side: StockOrderConfirmationSide) -> Color {
        side == .buy ? Color("color-utility3-red") : Color("color-utility3-green")
    }

    private func dismissInput() {
        focusedInput = nil
        isPriceTargetMenuPresented = false
    }
}

private enum StockDetailTransactionTradeLayout {
    static let horizontalPadding: CGFloat = 16
    static let accountHeaderHeight: CGFloat = 42
    static let accountContentWidth: CGFloat = 240
    static let accountFontSize: CGFloat = 16
    static let accountLineHeight: CGFloat = 24
    static let accountToBuyingPowerSpacing: CGFloat = 2
    static let buyingPowerSpacing: CGFloat = 2
    static let buyingPowerFontSize: CGFloat = 12
    static let buyingPowerLineHeight: CGFloat = 16
    static let refreshGlyphSize: CGFloat = 24
    static let refreshTapSize: CGFloat = 24
    static let formTopPadding: CGFloat = 8
    static let formRowSpacing: CGFloat = 8
    static let availabilityTopPadding: CGFloat = 16
    static let actionButtonsTopPadding: CGFloat = 16
    static let actionButtonsBottomPadding: CGFloat = 24
    static let actionButtonSpacing: CGFloat = 12
    static let actionButtonHeight: CGFloat = 36
    static let actionHorizontalPadding: CGFloat = 14
    static let actionFontSize: CGFloat = 16
    static let actionLineHeight: CGFloat = 16
    static let separatorHeight: CGFloat = 0.5
}

private struct StockDetailTransactionTradePreviewHarness: View {
    let symbol: StockOrderSymbol

    @State private var selectedTab: StockDetailTransactionModuleTab? = .trade

    var body: some View {
        VStack(spacing: 0) {
            StockDetailTransactionModuleTabBar(selection: $selectedTab)
                .allowsHitTesting(false)

            StockDetailTransactionTrade(symbol: symbol)
        }
        .background(Color("color-base-1"))
    }
}

private enum StockDetailTransactionTradePreviewData {
    static let hongKong = symbol(for: .hk)
    static let unitedStates = symbol(for: .us)
    static let chinaA = symbol(for: .china)
    static let crypto = symbol(for: .crypto)

    private static func symbol(for market: StockOrderMarket) -> StockOrderSymbol {
        guard let symbol = StockOrderDemoViewModel.searchableSymbols.first(where: { $0.market == market }) else {
            preconditionFailure("Missing \(market.rawValue) preview symbol")
        }

        return symbol
    }
}

struct StockDetailTransactionTrade_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionTradePreviewHarness(symbol: StockDetailTransactionTradePreviewData.hongKong)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("港股 · 已解锁")
                .previewLayout(.fixed(width: 402, height: 498))

            StockDetailTransactionTradePreviewHarness(symbol: StockDetailTransactionTradePreviewData.unitedStates)
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("US · Extended Hours")
                .previewLayout(.fixed(width: 402, height: 560))

            StockDetailTransactionTradePreviewHarness(symbol: StockDetailTransactionTradePreviewData.chinaA)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("A股 · 已解锁")
                .previewLayout(.fixed(width: 402, height: 498))

            StockDetailTransactionTradePreviewHarness(symbol: StockDetailTransactionTradePreviewData.crypto)
                .environment(\.demoLanguage, .english)
                .previewDisplayName("Crypto · Decimal Quantity")
                .previewLayout(.fixed(width: 402, height: 498))
        }
    }
}
