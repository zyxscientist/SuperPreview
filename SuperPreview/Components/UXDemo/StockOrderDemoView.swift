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
    @AppStorage(StockOrderAdvancedTradingPreferences.enabledKey)
    private var isHighFrequencyTradingEnabled = false
    @StateObject private var viewModel: StockOrderDemoViewModel
    @State private var confirmationSide: StockOrderConfirmationSide?
    @State private var confirmationConfirmCount = 0
    @State private var isPriceTargetMenuPresented = false
    @State private var isShowingDebugPanel = false
    @State private var focusedInput: StockOrderFormInputFocus?
    @State private var selectedAdvancedTradingSection: StockOrderAdvancedTradingSection = .trade
    @State private var visitedAdvancedTradingSections: Set<StockOrderAdvancedTradingSection> = [.trade]
    @State private var advancedTradingShuffleRequestID = 0

    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(initialSelection: StockOrderSymbol? = nil) {
        _ = StockOrderAdvancedTradingPreferences.prepareForUITesting
        _viewModel = StateObject(
            wrappedValue: StockOrderDemoViewModel(initialSelection: initialSelection)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            advancedTradingRoot(viewportWidth: proxy.size.width)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                // Match the quote page's screen-bottom coordinate space.
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color("color-base-1"))
        .toolbar(.hidden, for: .navigationBar)
        .navigationBackSwipe(
            navigationBackSwipePolicy,
            prioritizesEdgeOverHorizontalContent: true,
            refreshID: selectedAdvancedTradingSection.navigationBackSwipeRefreshID
        )
        .interactiveBottomCard(item: $confirmationSide) { side in
            StockOrderConfirmationSheet(
                data: viewModel.confirmationData(for: side, language: activeLanguage),
                onCancel: {
                    confirmationSide = nil
                },
                onConfirm: {
                    confirmationConfirmCount += 1
                    confirmationSide = nil
                }
            )
            .environment(\.demoLanguage, activeLanguage)
        }
        .sheet(isPresented: $isShowingDebugPanel) {
            StockOrderDebugPanel(
                language: debugLanguageBinding,
                isHighFrequencyTradingEnabled: $isHighFrequencyTradingEnabled
            )
                .environment(\.demoLanguage, activeLanguage)
        }
        .onChange(of: viewModel.selection) { _, _ in
            dismissInput()
            viewModel.synchronizeSelection()

            if viewModel.selection == nil {
                withAnimation(StockOrderMotion.expansion(reduceMotion: reduceMotion)) {
                    selectedAdvancedTradingSection = .trade
                    visitedAdvancedTradingSections = [.trade]
                }
            }
        }
        .onChange(of: selectedAdvancedTradingSection) { _, section in
            if section != .trade {
                dismissInput()
            }
        }
        .onChange(of: isHighFrequencyTradingEnabled) { _, isEnabled in
            if !isEnabled {
                selectedAdvancedTradingSection = .trade
                visitedAdvancedTradingSections = [.trade]
            }
        }
        .onChange(of: viewModel.priceTarget) { _, target in
            viewModel.updatePriceTarget(target)
        }
        .onChange(of: viewModel.orderType) { _, _ in
            dismissInput()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.demo")
        .overlay(alignment: .topLeading) {
            if PreviewRuntime.isUITesting {
                HStack(spacing: 0) {
                    Text(viewModel.selection?.id ?? "--")
                        .accessibilityIdentifier("stockOrder.debug.status.symbol")
                    Text(viewModel.selection?.fallbackName ?? "--")
                        .accessibilityIdentifier("stockOrder.debug.status.name")
                    Text(viewModel.price)
                        .accessibilityIdentifier("stockOrder.debug.status.price")
                    Text(viewModel.selection?.quote.miniKPoints.map { String(Double($0)) }.joined(separator: ",") ?? "")
                        .accessibilityIdentifier("stockOrder.debug.status.miniKPoints")
                    Text("\(confirmationConfirmCount)")
                        .accessibilityIdentifier("stockOrder.confirmation.confirmCount")
                }
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityElement(children: .contain)
            }
        }
        .environment(\.demoLanguage, activeLanguage)
    }

    private func advancedTradingRoot(viewportWidth: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Each visited peer keeps its identity, scroll position and local
            // state. Only the selected layer receives touch and accessibility.
            ForEach(StockOrderAdvancedTradingSection.allCases) { section in
                if visitedAdvancedTradingSections.contains(section) {
                    advancedTradingPage(section, viewportWidth: viewportWidth)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("color-base-1"))
                        .animation(
                            StockOrderAdvancedTradingLayout.pageSwitchAnimation(
                                reduceMotion: reduceMotion
                            )
                        ) { content in
                            content.opacity(selectedAdvancedTradingSection == section ? 1 : 0)
                        }
                        .allowsHitTesting(selectedAdvancedTradingSection == section)
                        .accessibilityHidden(selectedAdvancedTradingSection != section)
                        .zIndex(selectedAdvancedTradingSection == section ? 1 : 0)
                        .transition(
                            .opacity.animation(
                                StockOrderAdvancedTradingLayout.pageSwitchAnimation(
                                    reduceMotion: reduceMotion
                                )
                            )
                        )
                }
            }

            if showsAdvancedTradingToolBar {
                StockOrderAdvancedTradingToolBar(
                    selection: Binding(
                        get: { selectedAdvancedTradingSection },
                        set: { selectAdvancedTradingSection($0) }
                    )
                )
                .padding(.bottom, StockOrderAdvancedTradingLayout.toolBarBottomInset)
                .transition(
                    .move(edge: .bottom)
                        .combined(with: .opacity)
                )
                .zIndex(2)
            }

            // Bottom actions must be siblings of (and above) the switcher;
            // a zIndex inside an embedded page cannot escape that page's layer.
            advancedTradingBottomActions
                .zIndex(3)
        }
        .animation(
            StockOrderMotion.expansion(reduceMotion: reduceMotion),
            value: showsAdvancedTradingToolBar
        )
    }

    @ViewBuilder
    private func advancedTradingPage(
        _ section: StockOrderAdvancedTradingSection,
        viewportWidth: CGFloat
    ) -> some View {
        switch section {
        case .trade:
            transactionPage(viewportWidth: viewportWidth)
        case .market:
            if let selection = viewModel.selection {
                StockDetailPage(
                    instrument: selection.advancedTradingInstrument,
                    presentationMode: .advancedTrading,
                    showsBottomActionBar: false,
                    shuffleRequestID: advancedTradingShuffleRequestID,
                    onBack: exitAdvancedTrading,
                    onTrade: returnToTrade
                )
                .id(selection.id)
            }
        case .orders:
            TodayOrdersPageView(
                orders: viewModel.todayOrders(language: activeLanguage),
                showsNavbar: true,
                onBack: exitAdvancedTrading,
                navigationBackSwipePolicy: nil,
                bottomContentInset: StockOrderAdvancedTradingLayout.contentBottomInset
            )
        case .positions:
            positionsPage
        }
    }

    private func transactionPage(viewportWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            StockOrderNavbar(
                accountTitle: accountTitle,
                buyingPower: viewModel.buyingPower,
                onBack: exitAdvancedTrading,
                onDebug: {
                    dismissInput()
                    isShowingDebugPanel = true
                }
            )

            ScrollView(.vertical, showsIndicators: false) {
                pageContent(viewportWidth: viewportWidth)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(
                        .bottom,
                        showsAdvancedTradingToolBar
                            ? StockOrderAdvancedTradingLayout.contentBottomInset
                            : StockTradingBottomLayout.containerHeight + 16
                    )
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    @ViewBuilder
    private var advancedTradingBottomActions: some View {
        switch selectedAdvancedTradingSection {
        case .trade:
            bottomTradeBar
        case .market:
            StockDetailBottomActionBar(
                onTrade: returnToTrade,
                onShuffle: { advancedTradingShuffleRequestID &+= 1 }
            )
            .frame(height: StockTradingBottomLayout.actionBarHeight)
            .padding(.bottom, StockTradingBottomLayout.homeIndicatorAreaHeight)
            .accessibilityIdentifier("stockDetail.page.fixedBottomActionBar")
        case .orders, .positions:
            EmptyView()
        }
    }

    private var positionsPage: some View {
        VStack(spacing: 0) {
            StockOrderNavbar(
                accountTitle: activeLanguage.text(.positions),
                showsDebugButton: false,
                onBack: exitAdvancedTrading
            )

            TradeAggregationDemoView(
                showsMainTabBar: false,
                showsNavigationBarTitle: false,
                onTrade: returnToTrade,
                onTodayOrders: { selectAdvancedTradingSection(.orders) }
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: StockOrderAdvancedTradingLayout.contentBottomInset)
            }
        }
        .accessibilityIdentifier("stockOrder.advancedTrading.positions")
    }

    private var navigationBackSwipePolicy: NavigationBackSwipePolicy {
        confirmationSide == nil ? .system : .disabled
    }

    private var showsAdvancedTradingToolBar: Bool {
        isHighFrequencyTradingEnabled && viewModel.selection != nil
    }

    private func selectAdvancedTradingSection(
        _ section: StockOrderAdvancedTradingSection
    ) {
        guard showsAdvancedTradingToolBar,
              selectedAdvancedTradingSection != section else { return }

        dismissInput()
        // Each visual owns its animation. A global transaction here would
        // also retime the switcher's selection capsule and rebuild layout.
        visitedAdvancedTradingSections.insert(section)
        selectedAdvancedTradingSection = section
    }

    private func exitAdvancedTrading() {
        dismissInput()
        dismiss()
    }

    private func returnToTrade() {
        selectAdvancedTradingSection(.trade)
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
                    currentPrice: viewModel.currentPrice,
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
        VStack(spacing: 0) {
            StockOrderTradeActionBar(
                status: .unlocked,
                onBuy: { presentConfirmation(for: .buy) },
                onSell: { presentConfirmation(for: .sell) }
            )
            .frame(height: StockTradingBottomLayout.actionBarHeight)

            Color.clear
                .frame(height: StockTradingBottomLayout.homeIndicatorAreaHeight)
        }
        .frame(height: StockTradingBottomLayout.containerHeight)
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

        confirmationSide = side
    }

    private func dismissInput() {
        focusedInput = nil
        isPriceTargetMenuPresented = false
    }

    private var activeLanguage: DemoLanguage {
        demoLanguageStore.language
    }

    private var debugLanguageBinding: Binding<DemoLanguage> {
        Binding(
            get: { demoLanguageStore.language },
            set: { demoLanguageStore.language = $0 }
        )
    }
}

private struct StockOrderDebugPanel: View {
    @Binding var language: DemoLanguage
    @Binding var isHighFrequencyTradingEnabled: Bool

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

            DemoTouchToggle()

            Toggle(
                interfaceLanguage.text(.highFrequencyTradingTools),
                isOn: $isHighFrequencyTradingEnabled
            )
            .accessibilityIdentifier("stockOrder.debug.highFrequencyTrading")

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .background(Color("color-base-1").ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.debug.panel")
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
                .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
                .previewDisplayName("Empty · Simplified Chinese")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "09988"))
                .environment(\.demoLanguage, .traditionalChinese)
                .environmentObject(DemoLanguageStore(initialLanguage: .traditionalChinese))
                .previewDisplayName("HK · Traditional Chinese")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "NVDA"))
                .environment(\.demoLanguage, .english)
                .environmentObject(DemoLanguageStore(initialLanguage: .english))
                .preferredColorScheme(.dark)
                .previewDisplayName("US · English · Dark")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "600388"))
                .environment(\.demoLanguage, .simplifiedChinese)
                .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
                .previewDisplayName("A Share · Simplified Chinese")

            StockOrderDemoView(initialSelection: .previewSymbol(id: "BTC/USD"))
                .environment(\.demoLanguage, .english)
                .environmentObject(DemoLanguageStore(initialLanguage: .english))
                .previewDisplayName("Crypto · English")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
