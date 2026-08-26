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
    @State private var confirmationSide: StockOrderConfirmationSide?
    @State private var isPriceTargetMenuPresented = false
    @State private var isShowingDebugPanel = false
    @State private var debugLanguage: DemoLanguage?
    @State private var focusedInput: StockOrderFormInputFocus?

    @AppStorage(DemoLanguage.storageKey) private var storedDemoLanguage = DemoLanguage.simplifiedChinese
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
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    StockOrderNavbar(
                        accountTitle: accountTitle,
                        buyingPower: viewModel.buyingPower,
                        onBack: {
                            dismissInput()
                            dismiss()
                        },
                        onDebug: {
                            dismissInput()
                            isShowingDebugPanel = true
                        }
                    )

                    ScrollView(.vertical, showsIndicators: false) {
                        pageContent(viewportWidth: proxy.size.width)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(
                                .bottom,
                                StockOrderDemoViewLayout.bottomTradeBarHeight + 16
                            )
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.immediately)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { _ in dismissInput() }
                    )
                }

                // Keep the trade bar in the page viewport. A safe-area inset is
                // re-laid out while a search sheet is dismissed, which makes the
                // bar visibly move even though it should remain pinned.
                bottomTradeBar
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color("color-base-1"))
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $confirmationSide) { side in
            StockOrderConfirmationSheet(
                data: viewModel.confirmationData(for: side, language: activeLanguage)
            )
            .environment(\.demoLanguage, activeLanguage)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $isShowingDebugPanel) {
            StockOrderDebugPanel(language: debugLanguageBinding)
                .environment(\.demoLanguage, activeLanguage)
        }
        .onChange(of: viewModel.selection) { _, _ in
            dismissInput()
            viewModel.synchronizeSelection()
        }
        .onChange(of: viewModel.priceTarget) { _, target in
            viewModel.updatePriceTarget(target)
        }
        .onChange(of: viewModel.orderType) { _, _ in
            dismissInput()
        }
        .onChange(of: language) { _, newLanguage in
            debugLanguage = newLanguage
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.demo")
        .environment(\.demoLanguage, activeLanguage)
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
            .simultaneousGesture(TapGesture().onEnded { dismissInput() })

            if viewModel.showsOrderBook, let depth = viewModel.profile.orderBookDepth {
                StockOrderBook(
                    depth: depth,
                    distribution: viewModel.profile.orderBookDistribution,
                    bidLevels: viewModel.profile.bidLevels,
                    askLevels: viewModel.profile.askLevels,
                    isExpanded: $viewModel.isOrderBookExpanded
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                .simultaneousGesture(TapGesture().onEnded { dismissInput() })
            }

            orderForm

            StockOrderQuantityAvailability(
                quantity: $viewModel.quantity,
                cashPurchasable: viewModel.profile.cashPurchasable,
                maximumPurchasable: viewModel.profile.maximumPurchasable,
                positionSellable: viewModel.profile.positionSellable
            )
            .simultaneousGesture(TapGesture().onEnded { dismissInput() })

            StockOrderOrdersAndPositions(
                selectedTab: $viewModel.selectedOrdersTab,
                viewportWidth: viewportWidth,
                todayOrders: viewModel.todayOrders(language: activeLanguage),
                holdingSections: stockHoldingSections,
                virtualAssetHoldingSections: virtualAssetHoldingSections,
                showsProductCategoryPicker: viewModel.selection?.market == .crypto,
                productCategory: productCategoryBinding,
                todayOrdersState: .content,
                positionsState: .content,
                onHistoryOrders: {}
            )
            .simultaneousGesture(TapGesture().onEnded { dismissInput() })
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture().onEnded { dismissInput() },
            including: .gesture
        )
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
            .simultaneousGesture(TapGesture().onEnded { dismissInput() })

            if !viewModel.isMarketOrder {
                StockOrderPriceInput(
                    price: $viewModel.price,
                    priceTarget: $viewModel.priceTarget,
                    focusedInput: $focusedInput,
                    isTargetMenuPresented: $isPriceTargetMenuPresented,
                    currentPrice: viewModel.profile.currentPrice,
                    supportedPriceTargets: viewModel.profile.supportedPriceTargets,
                    areNudgeButtonsEnabled: viewModel.selection != nil,
                    onDecrease: viewModel.decreasePrice,
                    onIncrease: viewModel.increasePrice
                )
            }

            StockOrderQuantityInput(
                quantity: $viewModel.quantity,
                quickInputColumns: viewModel.quickInputColumns(language: activeLanguage),
                focusedInput: $focusedInput,
                inputMode: quantityInputMode,
                areNudgeButtonsEnabled: viewModel.selection != nil,
                showsQuickInputValues: viewModel.selection != nil,
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
            .simultaneousGesture(TapGesture().onEnded { dismissInput() })

            StockOrderAmountField(
                price: viewModel.price.isEmpty ? "0" : viewModel.price,
                quantity: viewModel.quantity.isEmpty ? "0" : viewModel.quantity,
                currencyCode: viewModel.profile.currencyCode,
                orderType: viewModel.orderType,
                fractionDigits: viewModel.profile.isCrypto ? 2 : 2,
                usesMargin: viewModel.profile.usesMargin && viewModel.orderType != .market
            )
            .simultaneousGesture(TapGesture().onEnded { dismissInput() })

            if viewModel.showsExtendedHours {
                StockOrderExtendedHoursInput(
                    selection: $viewModel.extendedHours
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                .simultaneousGesture(TapGesture().onEnded { dismissInput() })
            }

            StockOrderEffectPeriodInput(
                selection: $viewModel.effectPeriod
            )
            .simultaneousGesture(TapGesture().onEnded { dismissInput() })
        }
    }

    private var bottomTradeBar: some View {
        ZStack(alignment: .bottom) {
            StockOrderTradeActionBar(
                status: .unlocked,
                onBuy: { presentConfirmation(for: .buy) },
                onSell: { presentConfirmation(for: .sell) }
            )
            .padding(.bottom, 8)
        }
        .frame(height: StockOrderDemoViewLayout.bottomTradeBarHeight)
        .background(.clear)
    }

    private var accountTitle: String {
        "\(activeLanguage.text(viewModel.profile.accountTitleKey))(\(viewModel.profile.accountNumber))"
    }

    private var quantityInputMode: StockOrderQuantityInputMode {
        switch viewModel.profile.quantityInputMode {
        case .wholeNumber:
            return .wholeNumber
        case let .decimal(maxFractionDigits, _):
            let placeholder = String(
                format: activeLanguage.text(.minimumQuantity),
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

    private func presentConfirmation(for side: StockOrderConfirmationSide) {
        dismissInput()

        guard viewModel.selection != nil else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            confirmationSide = side
        }
    }

    private func dismissInput() {
        focusedInput = nil
        isPriceTargetMenuPresented = false
    }

    private var activeLanguage: DemoLanguage {
        debugLanguage ?? language
    }

    private var debugLanguageBinding: Binding<DemoLanguage> {
        Binding(
            get: { activeLanguage },
            set: { newLanguage in
                debugLanguage = newLanguage
                storedDemoLanguage = newLanguage
            }
        )
    }
}

private struct StockOrderDebugPanel: View {
    @Binding var language: DemoLanguage

    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var interfaceLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(interfaceLanguage.text(.debug))
                    .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))
                    .accessibilityIdentifier("stockOrder.debug.title")

                Spacer()

                Button(interfaceLanguage.text(.done)) {
                    dismiss()
                }
                .accessibilityIdentifier("stockOrder.debug.close")
            }

            DemoLanguagePicker(language: $language)
                .accessibilityIdentifier("stockOrder.debug.language")

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .background(Color("color-base-1").ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.debug.panel")
    }
}

private enum StockOrderDemoViewLayout {
    static let bottomTradeBarHeight: CGFloat = 94
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
