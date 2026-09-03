//
//  TradeAggregationDemoView.swift
//  SuperPreview
//

import SwiftUI

struct TradeAggregationDemoView: View {
    private let showsMainTabBar: Bool
    private let showsNavigationBarTitle: Bool
    private let externalDebugPresentation: Binding<Bool>?
    @StateObject private var viewModel = TradeAggregationDemoViewModel()
    @State private var selectedCategory: AssetCategory = .stocks
    @State private var isNumberHidden = false
    @State private var quickMenuTopPositions: [AssetCategory: CGFloat] = [:]
    @State private var isShowingDebugPanel = false
    @State private var isLiveDataEnabled = false
    @State private var isMRTestingEnabled = false
    @State private var isSummerAdvertisementEnabled = false
    @State private var isInAppNotificationSimulationEnabled = false
    @State private var isMultipleInAppNotificationSimulationEnabled = false
    @State private var selectedMainTab: AppTab = .tab2
    @State private var isShowingStockOrder = false
    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore
    @EnvironmentObject private var demoAppearanceStore: DemoAppearanceStore

    init(
        showsMainTabBar: Bool = true,
        showsNavigationBarTitle: Bool = true,
        debugPresentation: Binding<Bool>? = nil
    ) {
        self.showsMainTabBar = showsMainTabBar
        self.showsNavigationBarTitle = showsNavigationBarTitle
        self.externalDebugPresentation = debugPresentation
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(
                        alignment: .leading,
                        spacing: 0
                    ) {
                        if isMRTestingEnabled {
                            TradeAggregationMRNoticeBar()
                        }

                        Color.clear
                            .frame(height: TradeAggregationLayout.topInset)

                        TotalAsset(
                            currency: "USD",
                            totalAmount: viewModel.snapshot.totalAmount,
                            totalProfitLoss: viewModel.snapshot.totalProfitLoss,
                            isDataAvailable: !isMRTestingEnabled,
                            isNumberHidden: $isNumberHidden
                        )

                        Color.clear
                            .frame(height: TradeAggregationLayout.totalAssetBottomSpacing)

                        if isSummerAdvertisementEnabled {
                            TradeAggregationSummerAdvertisement()

                            Color.clear
                                .frame(height: TradeAggregationLayout.standardVerticalSpacing)
                        }

                        AssetCategoryTabBar(
                            selection: $selectedCategory,
                            isReducedLiquidGlassUsageEnabled: demoAppearanceStore.isReducedLiquidGlassUsageEnabled
                        )

                        selectedCategoryPage(viewportWidth: geometry.size.width)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("trade.scroll")

                if isQuickMenuPinned {
                    pinnedQuickMenu(
                        for: selectedCategory,
                        viewportWidth: geometry.size.width,
                        onTrade: { isShowingStockOrder = true }
                    )
                    .transition(.identity)
                    .zIndex(2)
                }

                if PreviewRuntime.isUITesting {
                    HStack(spacing: 0) {
                        Text(isMRTestingEnabled ? "MR_ENABLED" : "MR_DISABLED")
                            .accessibilityIdentifier("trade.debug.status.mr")
                        Text(isSummerAdvertisementEnabled ? "SUMMER_ENABLED" : "SUMMER_DISABLED")
                            .accessibilityIdentifier("trade.debug.status.summerAd")
                        Text(isLiveDataEnabled ? "LIVE_ENABLED" : "LIVE_DISABLED")
                            .accessibilityIdentifier("trade.debug.status.liveData")
                        Text(demoLanguage.rawValue)
                            .accessibilityIdentifier("trade.debug.status.language")
                        Text(demoLanguage.text(.marketValueQuantityHeader))
                            .accessibilityIdentifier("trade.debug.status.marketValueHeader")
                        Text(
                            isInAppNotificationSimulationEnabled
                                ? "INAPP_ENABLED"
                                : "INAPP_DISABLED"
                        )
                        .accessibilityIdentifier("trade.debug.status.inAppNotification")
                        Text(
                            isMultipleInAppNotificationSimulationEnabled
                                ? "INAPP_MULTIPLE_ENABLED"
                                : "INAPP_MULTIPLE_DISABLED"
                        )
                        .accessibilityIdentifier("trade.debug.status.inAppNotificationMultiple")
                    }
                    .frame(width: 1, height: 1)
                    .accessibilityElement(children: .contain)
                    .allowsHitTesting(false)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("trade.root")
        }
        .coordinateSpace(name: TradeAggregationLayout.stickyCoordinateSpace)
        .background(Color("color-base-1").ignoresSafeArea())
        .background(
            NavigationLink(
                destination: StockOrderDemoView(),
                isActive: $isShowingStockOrder
            ) {
                EmptyView()
            }
            .hidden()
            .accessibilityIdentifier("trade.stockOrder.navigation")
        )
        .mainTabBar(if: showsMainTabBar, selectedTab: $selectedMainTab)
        .inAppNotificationSimulation(
            isEnabled: isInAppNotificationSimulationEnabled && !isShowingDebugPanel,
            isMultipleMessages: isMultipleInAppNotificationSimulationEnabled
        )
        .navigationBarTitleIfEnabled(
            demoLanguage.text(.newTrade),
            isEnabled: showsNavigationBarTitle
        )
        .navigationBarDebugItem(
            isEnabled: externalDebugPresentation == nil,
            title: demoLanguage.text(.debug),
            identifier: "trade.debug.open",
            action: {
                isShowingDebugPanel = true
            }
        )
        .toolbarBackground(Color("color-base-1"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(
            isPresented: $isShowingDebugPanel,
            onDismiss: {
                externalDebugPresentation?.wrappedValue = false
            }
        ) {
            TradeAggregationDebugPanel(
                language: demoLanguageBinding,
                isLiveDataEnabled: $isLiveDataEnabled,
                isMRTestingEnabled: $isMRTestingEnabled,
                isSummerAdvertisementEnabled: $isSummerAdvertisementEnabled,
                isInAppNotificationSimulationEnabled: $isInAppNotificationSimulationEnabled,
                isMultipleInAppNotificationSimulationEnabled: $isMultipleInAppNotificationSimulationEnabled,
                isReducedLiquidGlassUsageEnabled: reducedLiquidGlassUsageBinding
            )
        }
        .onChange(of: externalDebugPresentation?.wrappedValue ?? false) { _, isPresented in
            guard isPresented != isShowingDebugPanel else { return }
            isShowingDebugPanel = isPresented
        }
        .onPreferenceChange(TradeAggregationQuickMenuTopPreferenceKey.self) {
            quickMenuTopPositions.merge($0) { _, newValue in newValue }
        }
        .onChange(of: isQuickMenuPinned) { wasPinned, isPinned in
            guard !wasPinned, isPinned else { return }
            HapticManager.instance.impactHaptic(type: .light)
        }
        .task(id: isLiveDataEnabled) {
            guard isLiveDataEnabled else { return }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(
                            Double.random(in: 4.5...5.5) * 1_000_000_000
                        )
                    )
                } catch {
                    return
                }

                await MainActor.run {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        viewModel.simulateRandomRefresh()
                    }
                }
            }
        }
        .environment(\.demoLanguage, demoLanguage)
    }

    private func selectedCategoryPage(viewportWidth: CGFloat) -> some View {
        Group {
            if isMRTestingActive {
                TradeAggregationMRMaintenanceStateView(viewportWidth: viewportWidth)
            } else {
                TradeAggregationCategoryPage(
                    category: selectedCategory,
                    isNumberHidden: isNumberHidden,
                    snapshot: viewModel.snapshot,
                    viewportWidth: viewportWidth,
                    onTrade: { isShowingStockOrder = true }
                )
            }
        }
        .id("\(selectedCategory.rawValue)-\(isMRTestingActive)")
    }

    private var demoLanguage: DemoLanguage {
        demoLanguageStore.language
    }

    private var demoLanguageBinding: Binding<DemoLanguage> {
        Binding(
            get: { demoLanguageStore.language },
            set: { demoLanguageStore.language = $0 }
        )
    }

    private var reducedLiquidGlassUsageBinding: Binding<Bool> {
        Binding(
            get: { demoAppearanceStore.isReducedLiquidGlassUsageEnabled },
            set: { demoAppearanceStore.isReducedLiquidGlassUsageEnabled = $0 }
        )
    }

    private var isQuickMenuPinned: Bool {
        guard !isMRTestingActive else { return false }
        guard let top = quickMenuTopPositions[selectedCategory] else {
            return false
        }
        return top <= 0
    }

    private var isMRTestingActive: Bool {
        isMRTestingEnabled && selectedCategory != .virtualAssets
    }

    @ViewBuilder
    private func quickMenu(
        for category: AssetCategory,
        onTrade: @escaping () -> Void = {}
    ) -> some View {
        switch category {
        case .stocks:
            StockAssetQuickMenu(onTrade: onTrade)
        case .funds:
            FundAssetQuickMenu()
        case .virtualAssets:
            VirtualAssetsQuickMenu()
        }
    }

    private func pinnedQuickMenu(
        for category: AssetCategory,
        viewportWidth: CGFloat,
        onTrade: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            quickMenu(for: category, onTrade: onTrade)
                .frame(width: viewportWidth, height: TradeAggregationLayout.quickMenuHeight)

            Color.clear
                .frame(height: TradeAggregationLayout.quickMenuSeparatorAreaHeight)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color("color-separator-10"))
                        .frame(height: TradeAggregationLayout.quickMenuSeparatorLineHeight)
                }
                .accessibilityHidden(true)
        }
        .frame(width: viewportWidth)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trade.quickMenu.pinned")
    }

}

private enum TradeAggregationLayout {
    static let topInset: CGFloat = 12
    static let totalAssetBottomSpacing: CGFloat = 12
    static let standardVerticalSpacing: CGFloat = 12
    static let cardToQuickMenuSpacing: CGFloat = 22
    static let quickMenuHeight: CGFloat = 74
    static let quickMenuSeparatorAreaHeight: CGFloat = 1
    static let quickMenuSeparatorLineHeight: CGFloat = 0.5
    static let quickMenuToTitleSpacing: CGFloat = 22
    static let holdingsTitleHeight: CGFloat = 28
    static let titleToHoldingsSpacing: CGFloat = 22
    static let bottomSpacing: CGFloat = 20
    static let stickyCoordinateSpace = "TradeAggregationStickyViewport"
}

private struct TradeAggregationSummerAdvertisement: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        ZStack(alignment: .leading) {
            Image("summeradv")
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)

            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.87, green: 0.96, blue: 1), location: 0),
                    .init(color: Color(red: 0.87, green: 0.96, blue: 1), location: 0.58),
                    .init(color: Color(red: 0.87, green: 0.96, blue: 1).opacity(0), location: 0.74)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(language.text(.limitedTime))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(red: 1, green: 0.34, blue: 0.38), in: Capsule())

                Text(language.text(.summerCampaignHeadline))
                    .font(.system(size: language == .english ? 15 : 20, weight: .heavy))
                    .foregroundColor(Color(red: 0.04, green: 0.47, blue: 0.87))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(language.text(.summerCampaignPeriod))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(red: 0.12, green: 0.35, blue: 0.56))
            }
            .padding(.leading, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: 238, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 92, maxHeight: 92)
        .clipShape(RoundedRectangle(cornerRadius: TradeAggregationSummerAdvertisementStyle.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(
                cornerRadius: TradeAggregationSummerAdvertisementStyle.cornerRadius,
                style: .continuous
            )
                .stroke(Color("color-separator-10"), lineWidth: 0.5)
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("trade.summerAd")
        .accessibilityLabel(
            language.actionAccessibilityLabel(
                name: language.text(.summerCampaignAccessibility),
                action: language.text(.summerCampaignPeriod)
            )
        )
    }
}

private enum TradeAggregationSummerAdvertisementStyle {
    static let cornerRadius: CGFloat = 16
}

private struct TradeAggregationCategoryPage: View {
    let category: AssetCategory
    let isNumberHidden: Bool
    let snapshot: TradeAggregationDemoSnapshot
    let viewportWidth: CGFloat
    let onTrade: () -> Void
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            subAssetCard
                .padding(.horizontal, 16)

            Color.clear
                .frame(height: TradeAggregationLayout.cardToQuickMenuSpacing)

            quickMenu
                .frame(width: viewportWidth)
                .frame(height: TradeAggregationLayout.quickMenuHeight)
                .background(quickMenuPositionReader)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("trade.quickMenu.inline")

            Color.clear
                .frame(height: TradeAggregationLayout.quickMenuToTitleSpacing)

            holdingsTitle

            Color.clear
                .frame(height: TradeAggregationLayout.titleToHoldingsSpacing)

            holdingList

            Color.clear
                .frame(height: TradeAggregationLayout.bottomSpacing)
        }
        .frame(
            width: viewportWidth,
            alignment: .topLeading
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trade.categoryPage")
    }

    @ViewBuilder
    private var subAssetCard: some View {
        switch category {
        case .stocks:
            StockSubAssetCard(
                model: snapshot.stockCard,
                isNumberHidden: isNumberHidden
            )
        case .funds:
            FundSubAssetCard(
                model: snapshot.fundCard,
                isNumberHidden: isNumberHidden
            )
        case .virtualAssets:
            VirtualAssetsSubAssetCard(
                model: snapshot.virtualAssetCard,
                isNumberHidden: isNumberHidden
            )
        }
    }

    @ViewBuilder
    private var quickMenu: some View {
        switch category {
        case .stocks:
            StockAssetQuickMenu(onTrade: onTrade)
        case .funds:
            FundAssetQuickMenu()
        case .virtualAssets:
            VirtualAssetsQuickMenu()
        }
    }

    private var holdingsTitle: some View {
        Text(language.text(.positionDetails))
            .font(
                .custom(
                    "PlusJakartaSans-SemiBold",
                    size: 18,
                    relativeTo: .headline
                )
            )
            .foregroundColor(Color("color-text-30"))
            .frame(maxWidth: .infinity, minHeight: TradeAggregationLayout.holdingsTitleHeight, maxHeight: TradeAggregationLayout.holdingsTitleHeight, alignment: .leading)
            .padding(.leading, 16)
            .accessibilityIdentifier("trade.positionDetails")
    }

    @ViewBuilder
    private var holdingList: some View {
        switch category {
        case .stocks:
            StockHoldingListGroup(
                viewportWidth: viewportWidth,
                sections: snapshot.stockSections,
                isNumberHidden: isNumberHidden
            )
        case .funds:
            FundHoldingListGroup(
                viewportWidth: viewportWidth,
                sections: snapshot.fundSections,
                isNumberHidden: isNumberHidden
            )
        case .virtualAssets:
            VirtualAssetHoldingListGroup(
                viewportWidth: viewportWidth,
                sections: snapshot.virtualAssetSections,
                isNumberHidden: isNumberHidden
            )
        }
    }

    private var quickMenuPositionReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: TradeAggregationQuickMenuTopPreferenceKey.self,
                value: [
                    category: proxy.frame(
                        in: .named(TradeAggregationLayout.stickyCoordinateSpace)
                    ).minY
                ]
            )
        }
    }

}

private struct TradeAggregationQuickMenuTopPreferenceKey: PreferenceKey {
    static var defaultValue: [AssetCategory: CGFloat] = [:]

    static func reduce(
        value: inout [AssetCategory: CGFloat],
        nextValue: () -> [AssetCategory: CGFloat]
    ) {
        value.merge(nextValue()) { _, newValue in newValue }
    }
}

private struct TradeAggregationMRNoticeBar: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        Text(language.text(.mrNotice))
            .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
            .foregroundColor(Color("color-utility6-orange"))
            .frame(maxWidth: .infinity, minHeight: 36, maxHeight: 36, alignment: .leading)
            .padding(.horizontal, 16)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .background(Color(red: 1, green: 243 / 255, blue: 231 / 255))
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("trade.mrNotice")
            .accessibilityLabel(language.text(.mrNoticeAccessibility))
    }
}

private struct TradeAggregationMRMaintenanceStateView: View {
    let viewportWidth: CGFloat
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(spacing: 12) {
            Image("mr_testing")
                .resizable()
                .frame(width: 70, height: 70)

            Text(language.text(.systemUpgrade))
                .modifier(CustomFontModifier(size: 18, font: .medium, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))
                .frame(maxWidth: .infinity)

            Text(language.text(.maintenanceDetails))
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 60)
        .frame(width: viewportWidth, alignment: .top)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("trade.mrMaintenance")
    }
}

private struct TradeAggregationDebugPanel: View {
    @Binding var language: DemoLanguage
    @Binding var isLiveDataEnabled: Bool
    @Binding var isMRTestingEnabled: Bool
    @Binding var isSummerAdvertisementEnabled: Bool
    @Binding var isInAppNotificationSimulationEnabled: Bool
    @Binding var isMultipleInAppNotificationSimulationEnabled: Bool
    @Binding var isReducedLiquidGlassUsageEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var interfaceLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(interfaceLanguage.text(.debug))
                    .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))
                    .accessibilityIdentifier("trade.debug.title")

                Spacer()

                Button(interfaceLanguage.text(.done)) {
                    dismiss()
                }
                .accessibilityIdentifier("trade.debug.close")
            }

            DemoLanguagePicker(language: $language)

            DemoLiquidGlassUsageToggle(
                isReducedLiquidGlassUsageEnabled: $isReducedLiquidGlassUsageEnabled
            )
            .accessibilityIdentifier("trade.debug.reduceLiquidGlass")

            Toggle(isOn: $isLiveDataEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(interfaceLanguage.text(.simulateLiveData))
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(
                        interfaceLanguage.text(isLiveDataEnabled ? .liveDataOn : .liveDataOff)
                    )
                    .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                }
            }
            .accessibilityIdentifier("trade.debug.liveData")

            Toggle(isOn: $isInAppNotificationSimulationEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("模拟成交站内信")
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(
                        isInAppNotificationSimulationEnabled
                            ? "关闭调试面板后开始循环推送"
                            : "每次显示 5 秒，退场 1 秒后再次推送"
                    )
                    .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                }
            }
            .accessibilityIdentifier("trade.debug.inAppNotification")

            Toggle(isOn: $isMultipleInAppNotificationSimulationEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("模拟多条成交站内信")
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(
                        isMultipleInAppNotificationSimulationEnabled
                            ? "每 2 秒推入一条新信息，当前通知将原地淡出"
                            : "开启后模拟当前通知被新的成交信息打断"
                    )
                    .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                }
            }
            .disabled(!isInAppNotificationSimulationEnabled)
            .accessibilityIdentifier("trade.debug.inAppNotificationMultiple")

            Toggle(isOn: $isMRTestingEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(interfaceLanguage.text(.mrTestMode))
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(interfaceLanguage.text(.mrTestDetails))
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                }
            }
            .accessibilityIdentifier("trade.debug.mr")

            Toggle(isOn: $isSummerAdvertisementEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(interfaceLanguage.text(.showSummerCampaign))
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(interfaceLanguage.text(.summerCampaignDetails))
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                }
            }
            .accessibilityIdentifier("trade.debug.summerAd")

            if PreviewRuntime.isUITesting {
                Button(interfaceLanguage.text(.enableDebugStateMatrix)) {
                    isLiveDataEnabled = true
                    isMRTestingEnabled = true
                    isSummerAdvertisementEnabled = true
                }
                .accessibilityIdentifier("trade.debug.enableStateMatrix")

                Button(interfaceLanguage.text(.restoreNormalAndLiveData)) {
                    isMRTestingEnabled = false
                    isLiveDataEnabled = true
                }
                .accessibilityIdentifier("trade.debug.enableLiveData")
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .background(Color("color-base-1").edgesIgnoringSafeArea(.all))
    }
}

struct TradeAggregationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                TradeAggregationDemoView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
            .environmentObject(DemoAppearanceStore())
            .previewLayout(.fixed(width: 402, height: 874))
            .previewDisplayName("iPhone 17 Pro · 402×874")

            NavigationView {
                TradeAggregationDemoView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
            .environmentObject(DemoAppearanceStore())
            .previewLayout(.fixed(width: 440, height: 956))
            .previewDisplayName("iPhone 17 Pro Max · 440×956")
        }
    }
}
