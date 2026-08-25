//
//  StockOrderDemoView.swift
//  SuperPreview
//

import SwiftUI

/// The assembled stock-order UX demo.
///
/// This page intentionally stops at stable mock data and local interaction.
/// Each visual block remains a separately reusable component while the view
/// model owns the market matrix and the bindings that connect those blocks.
struct StockOrderDemoView: View {
    @StateObject private var viewModel: StockOrderDemoViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(initialSelection: StockOrderSymbol? = nil) {
        _viewModel = StateObject(
            wrappedValue: StockOrderDemoViewModel(initialSelection: initialSelection)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                StockOrderNavbar(
                    accountTitle: accountTitle,
                    buyingPower: viewModel.buyingPower,
                    onBack: { dismiss() },
                    onRefresh: {}
                )

                ScrollView(.vertical, showsIndicators: false) {
                    pageContent(viewportWidth: proxy.size.width)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .background(Color("color-base-1"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomTradeBar
        }
        .onChange(of: viewModel.selection) { _, _ in
            viewModel.synchronizeSelection()
        }
        .onChange(of: viewModel.priceTarget) { _, target in
            viewModel.updatePriceTarget(target)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.demo")
    }

    private func pageContent(viewportWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StockOrderSymbolSelector(
                selection: $viewModel.selection,
                isChartExpanded: $viewModel.isChartExpanded,
                recentSymbols: $viewModel.recentSymbols,
                searchableSymbols: StockOrderDemoViewModel.searchableSymbols,
                searchAvailability: .available
            )

            if viewModel.showsOrderBook, let depth = viewModel.profile.orderBookDepth {
                StockOrderBook(
                    depth: depth,
                    distribution: viewModel.profile.orderBookDistribution,
                    bidLevels: viewModel.profile.bidLevels,
                    askLevels: viewModel.profile.askLevels,
                    isExpanded: $viewModel.isOrderBookExpanded
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }

            orderForm

            StockOrderQuantityAvailability(
                quantity: $viewModel.quantity,
                cashPurchasable: viewModel.profile.cashPurchasable,
                maximumPurchasable: viewModel.profile.maximumPurchasable,
                positionSellable: viewModel.profile.positionSellable
            )

            StockOrderOrdersAndPositions(
                selectedTab: $viewModel.selectedOrdersTab,
                viewportWidth: viewportWidth,
                todayOrders: viewModel.todayOrders(language: language),
                holdingSections: stockHoldingSections,
                virtualAssetHoldingSections: virtualAssetHoldingSections,
                showsProductCategoryPicker: viewModel.selection?.market == .crypto,
                productCategory: productCategoryBinding,
                todayOrdersState: .content,
                positionsState: .content
            )
        }
        .animation(
            StockOrderMotion.expansion(reduceMotion: reduceMotion),
            value: viewModel.selection?.id
        )
    }

    private var orderForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            StockOrderOrderTypeInput(
                selection: $viewModel.orderType,
                supportedOrderTypes: viewModel.profile.supportedOrderTypes
            )

            StockOrderPriceInput(
                price: $viewModel.price,
                priceTarget: $viewModel.priceTarget,
                currentPrice: viewModel.profile.currentPrice,
                supportedPriceTargets: viewModel.profile.supportedPriceTargets,
                onDecrease: viewModel.decreasePrice,
                onIncrease: viewModel.increasePrice
            )

            StockOrderQuantityInput(
                quantity: $viewModel.quantity,
                quickInputColumns: viewModel.quickInputColumns(language: language),
                inputMode: quantityInputMode,
                onDecrease: viewModel.decreaseQuantity,
                onIncrease: viewModel.increaseQuantity
            )

            StockOrderAmountField(
                price: viewModel.price.isEmpty ? "0" : viewModel.price,
                quantity: viewModel.quantity.isEmpty ? "0" : viewModel.quantity,
                currencyCode: viewModel.profile.currencyCode,
                orderType: viewModel.orderType,
                fractionDigits: viewModel.profile.isCrypto ? 2 : 2,
                usesMargin: viewModel.profile.usesMargin && viewModel.orderType != .market
            )

            if viewModel.showsExtendedHours {
                StockOrderExtendedHoursInput(
                    selection: $viewModel.extendedHours
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }

            StockOrderEffectPeriodInput(
                selection: $viewModel.effectPeriod
            )
        }
    }

    private var bottomTradeBar: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color("color-base-1").opacity(0),
                    Color("color-base-1").opacity(0.92),
                    Color("color-base-1")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            StockOrderTradeActionBar(
                status: .unlocked,
                onBuy: {},
                onSell: {}
            )
            .padding(.bottom, 8)
        }
        .frame(height: 94)
        .background(.clear)
    }

    private var accountTitle: String {
        "\(language.text(viewModel.profile.accountTitleKey))(\(viewModel.profile.accountNumber))"
    }

    private var quantityInputMode: StockOrderQuantityInputMode {
        switch viewModel.profile.quantityInputMode {
        case .wholeNumber:
            return .wholeNumber
        case let .decimal(maxFractionDigits, _):
            let placeholder = String(
                format: language.text(.minimumQuantity),
                "0.00001"
            )
            return .decimal(
                maxFractionDigits: maxFractionDigits,
                placeholder: placeholder
            )
        }
    }

    private var stockHoldingSections: [StockHoldingMarketSection] {
        viewModel.selection == nil ? [] : .preview
    }

    private var virtualAssetHoldingSections: [VirtualAssetHoldingSection] {
        guard viewModel.selection?.market == .crypto else { return [] }
        return Array(
            Array<VirtualAssetHoldingSection>.virtualAssetHoldingPreview.prefix(1)
        )
    }

    private var productCategoryBinding: Binding<StockOrderProductCategory> {
        Binding(
            get: { viewModel.productCategory },
            set: { viewModel.setProductCategory($0) }
        )
    }
}

private extension StockOrderSymbol {
    static func previewSymbol(id: String) -> StockOrderSymbol? {
        StockOrderDemoViewModel.searchableSymbols.first { $0.id == id }
    }
}

struct StockOrderDemoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderDemoView()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Empty · Simplified Chinese")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "09988"))
                .environment(\.demoLanguage, .traditionalChinese)
                .previewDisplayName("HK · Traditional Chinese")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "NVDA"))
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("US · English · Dark")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "600388"))
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("A Share · Simplified Chinese")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "BTC/USD"))
                .environment(\.demoLanguage, .english)
                .previewDisplayName("Crypto · English")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
