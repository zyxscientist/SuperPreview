//
//  WatchlistRedesignDemoView.swift
//  SuperPreview
//
//  Created by Codex on 2026/07/01.
//  Copyright © 2026 PeterZ. All rights reserved.
//

import SwiftUI

struct WatchlistRedesignDemoView: View {
    @StateObject private var viewModel = WatchlistRedesignViewModel()
    @State private var isShowingDebugPanel = false
    @State private var shouldNavigateOnRowTap = true
    @State private var isMiniKVisible = true
    @State private var tabBarFontSize: CGFloat = 14
    @State private var isPriceSimulationEnabled = false
    @State private var priceSimulationSpeed: WatchlistRedesignPriceSimulationSpeed = .medium
    @State private var isInAppNotificationSimulationEnabled = false
    @State private var isMultipleInAppNotificationSimulationEnabled = false
    @State private var selectedMainTab: AppTab = .tab1
    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore

    private var priceSimulationTaskID: String {
        "\(isPriceSimulationEnabled)-\(priceSimulationSpeed.rawValue)"
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                WatchlistRedesignTabs(
                    tabs: viewModel.tabs,
                    selectedTab: $viewModel.selectedTab,
                    fontSize: tabBarFontSize
                )
                WatchlistRedesignTableHeader(isMiniKVisible: $isMiniKVisible)

                TabView(selection: $viewModel.selectedTab) {
                    ForEach(viewModel.tabs, id: \.self) { tab in
                        WatchlistRedesignListPage(
                            items: viewModel.items(for: tab),
                            shouldNavigateOnRowTap: shouldNavigateOnRowTap,
                            isMiniKVisible: isMiniKVisible,
                            bottomContentClearance: geometry.safeAreaInsets.bottom + 28
                        )
                        .tag(tab)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color("color-base-1").edgesIgnoringSafeArea(.all))
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .overlay(alignment: .topLeading) {
            if PreviewRuntime.isUITesting {
                HStack(spacing: 0) {
                    Text(demoLanguage.rawValue)
                        .accessibilityIdentifier("watchlist.debug.status.language")
                    Text(demoLanguage.text(.changePercent))
                        .accessibilityIdentifier("watchlist.debug.status.changeHeader")
                }
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .contain)
                .allowsHitTesting(false)
            }
        }
        .mainTabBar(selectedTab: $selectedMainTab)
        .inAppNotificationSimulation(
            isEnabled: isInAppNotificationSimulationEnabled && !isShowingDebugPanel,
            isMultipleMessages: isMultipleInAppNotificationSimulationEnabled
        )
        .accessibilityIdentifier("watchlist.root")
        .navigationBarTitle(demoLanguage.text(.newWatchlist), displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                isShowingDebugPanel = true
            }) {
                Text(demoLanguage.text(.debug))
                    .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                    .foregroundColor(Color("color-text-30"))
            }
            .accessibilityIdentifier("watchlist.debug.open")
        )
        .sheet(isPresented: $isShowingDebugPanel) {
            WatchlistRedesignDebugPanel(
                language: demoLanguageBinding,
                shouldNavigateOnRowTap: $shouldNavigateOnRowTap,
                tabBarFontSize: $tabBarFontSize,
                isPriceSimulationEnabled: $isPriceSimulationEnabled,
                priceSimulationSpeed: $priceSimulationSpeed,
                isInAppNotificationSimulationEnabled: $isInAppNotificationSimulationEnabled,
                isMultipleInAppNotificationSimulationEnabled: $isMultipleInAppNotificationSimulationEnabled
            )
        }
        .task(id: priceSimulationTaskID) {
            guard isPriceSimulationEnabled else { return }
            let symbols = viewModel.priceSimulationSymbols

            await withTaskGroup(of: Void.self) { group in
                for symbol in symbols {
                    group.addTask {
                        do {
                            try await Task.sleep(nanoseconds: UInt64(priceSimulationSpeed.initialDelay * 1_000_000_000))
                        } catch {
                            return
                        }

                        while !Task.isCancelled {
                            await MainActor.run {
                                viewModel.simulatePriceRefresh(for: symbol)
                            }

                            do {
                                try await Task.sleep(nanoseconds: UInt64(priceSimulationSpeed.nextInterval * 1_000_000_000))
                            } catch {
                                return
                            }
                        }
                    }
                }
            }
        }
        .environment(\.demoLanguage, demoLanguage)
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
}

struct WatchlistRedesignListPage: View {
    let items: [WatchlistRedesignItem]
    let shouldNavigateOnRowTap: Bool
    let isMiniKVisible: Bool
    let bottomContentClearance: CGFloat

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(items) { item in
                    WatchlistRedesignNavigableRow(
                        item: item,
                        shouldNavigateOnTap: shouldNavigateOnRowTap,
                        isMiniKVisible: isMiniKVisible
                    )
                }

                WatchlistRedesignActions()
                    .padding(.top, 4)

                Color.clear
                    .frame(height: bottomContentClearance)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct WatchlistRedesignNavigableRow: View {
    let item: WatchlistRedesignItem
    let shouldNavigateOnTap: Bool
    let isMiniKVisible: Bool

    var body: some View {
        if shouldNavigateOnTap {
            NavigationLink(destination: destination) {
                WatchlistRedesignRow(item: item, isMiniKVisible: isMiniKVisible)
            }
            .buttonStyle(WatchlistRedesignRowPressStyle(baseColor: item.backgroundColor))
        } else {
            Button(action: {}) {
                WatchlistRedesignRow(item: item, isMiniKVisible: isMiniKVisible)
            }
            .buttonStyle(WatchlistRedesignRowPressStyle(baseColor: item.backgroundColor))
        }
    }

    @ViewBuilder
    private var destination: some View {
        if item.instrumentKind == .fund || item.market == .fund {
            WatchlistRedesignDetailPlaceholder()
        } else {
            StockDetailPage(instrument: item.stockDetailInstrument)
        }
    }
}

struct WatchlistRedesignRowPressStyle: ButtonStyle {
    let baseColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color("color-scale-2") : baseColor)
        .contentShape(Rectangle())
    }
}

struct WatchlistRedesignActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        WatchlistRedesignActionPressButton(configuration: configuration)
    }
}

private struct WatchlistRedesignActionPressButton: View {
    let configuration: ButtonStyle.Configuration

    @State private var isHoldingFeedback = false
    @State private var releaseWorkItem: DispatchWorkItem?

    private var isScaled: Bool {
        configuration.isPressed || isHoldingFeedback
    }

    var body: some View {
        configuration.label
            .scaleEffect(isScaled ? 0.96 : 1)
            .animation(.easeInOut(duration: isScaled ? 0.06 : 0.12), value: isScaled)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    releaseWorkItem?.cancel()
                    isHoldingFeedback = true
                } else {
                    let workItem = DispatchWorkItem {
                        isHoldingFeedback = false
                    }
                    releaseWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
                }
            }
    }
}

private struct WatchlistRedesignActionButtonLabel: View {
    let title: String
    let leftRadius: CGFloat
    let rightRadius: CGFloat

    var body: some View {
        Text(title)
            .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 24))
            .foregroundColor(Color("color-text-30"))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color("color-scale-2"))
            .cornerRadius(leftRadius, corners: [.topLeft, .bottomLeft])
            .cornerRadius(rightRadius, corners: [.topRight, .bottomRight])
    }
}

struct WatchlistRedesignDetailPlaceholder: View {
    var body: some View {
        Color("color-base-1")
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("", displayMode: .inline)
    }
}

struct WatchlistRedesignDebugPanel: View {
    @Binding var language: DemoLanguage
    @Binding var shouldNavigateOnRowTap: Bool
    @Binding var tabBarFontSize: CGFloat
    @Binding var isPriceSimulationEnabled: Bool
    @Binding var priceSimulationSpeed: WatchlistRedesignPriceSimulationSpeed
    @Binding var isInAppNotificationSimulationEnabled: Bool
    @Binding var isMultipleInAppNotificationSimulationEnabled: Bool
    @Environment(\.demoLanguage) private var interfaceLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(interfaceLanguage.text(.debug))
                .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                .foregroundColor(Color("color-text-30"))

            DemoLanguagePicker(language: $language)

            Toggle(isOn: $shouldNavigateOnRowTap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(interfaceLanguage.text(.navigateOnTap))
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(interfaceLanguage.text(shouldNavigateOnRowTap ? .navigateOnTapOn : .navigateOnTapOff))
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(interfaceLanguage.text(.tabBarFontSize))
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))

                Picker(interfaceLanguage.text(.tabBarFontSize), selection: $tabBarFontSize) {
                    Text("14").tag(CGFloat(14))
                    Text("16").tag(CGFloat(16))
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $isPriceSimulationEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(interfaceLanguage.text(.simulateQuoteUpdates))
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Text(interfaceLanguage.text(isPriceSimulationEnabled ? .quoteUpdatesOn : .quoteUpdatesOff))
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(interfaceLanguage.text(.updateSpeed))
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))

                Picker(interfaceLanguage.text(.updateSpeed), selection: $priceSimulationSpeed) {
                    ForEach(WatchlistRedesignPriceSimulationSpeed.allCases) { speed in
                        Text(interfaceLanguage.speedTitle(speed)).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
            }

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
            .accessibilityIdentifier("watchlist.debug.inAppNotification")

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
            .accessibilityIdentifier("watchlist.debug.inAppNotificationMultiple")

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .background(Color("color-base-1").edgesIgnoringSafeArea(.all))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("watchlist.debug.panel")
    }
}

struct WatchlistRedesignTabs: View {
    let tabs: [String]
    @Binding var selectedTab: String
    let fontSize: CGFloat
    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.32, extraBounce: 0)
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                tabButtons
                    .padding(.leading, 10)
                    .padding(.trailing, 48)
                    .padding(.vertical, 8)
                    .animation(selectionAnimation, value: selectedTab)
            }

            ZStack(alignment: .trailing) {
                LinearGradient(
                    gradient: Gradient(colors: [Color("color-transparent"), Color("color-base-1")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                Image("headertab_sort")
                    .padding(.trailing, 12)
            }
            .frame(width: 50, height: 48)
        }
        .frame(height: 48)
        .background(Color("color-base-1"))
    }

    private var tabButtons: some View {
        // There is one persistent selection surface rather than a group of glass
        // surfaces. Keeping it outside GlassEffectContainer preserves the normal
        // background-to-foreground order: glass first, then the tab labels.
        tabButtonRow
    }

    private var tabButtonRow: some View {
        HStack(spacing: 2) {
            ForEach(tabs, id: \.self) { tab in
                let isSelected = selectedTab == tab

                Button {
                    guard selectedTab != tab else { return }
                    selectedTab = tab
                } label: {
                    Text(language.watchlistTabTitle(tab))
                        .modifier(CustomFontModifier(size: fontSize, font: isSelected ? .bold : .regular, lineHeight: 24))
                        .foregroundColor(isSelected ? Color("color-text-30") : Color("color-text-60"))
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                        .anchorPreference(
                            key: WatchlistRedesignTabFramePreferenceKey.self,
                            value: .bounds
                        ) { anchor in
                            [tab: anchor]
                        }
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("watchlist.tab.\(tab)")
            }
        }
        .backgroundPreferenceValue(WatchlistRedesignTabFramePreferenceKey.self) { anchors in
            GeometryReader { proxy in
                if let selectedAnchor = anchors[selectedTab] {
                    let selectedFrame = proxy[selectedAnchor]

                    selectionGlassBackground
                        .frame(width: selectedFrame.width, height: selectedFrame.height)
                        .position(x: selectedFrame.midX, y: selectedFrame.midY)
                }
            }
        }
    }

    @ViewBuilder
    private var selectionGlassBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Capsule())
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            Capsule()
                .fill(Color("color-base-r"))
        }
    }
}

private struct WatchlistRedesignTabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

struct WatchlistRedesignTableHeader: View {
    @Binding var isMiniKVisible: Bool
    @Environment(\.demoLanguage) private var language

    var body: some View {
        GeometryReader { proxy in
            let nameWidth = max(CGFloat(110), proxy.size.width - 252)

            ZStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Text(language.text(.name))
                        .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                        .foregroundColor(Color("color-text-90"))
                        .accessibilityIdentifier("watchlist.header.name")
                    Rectangle()
                        .fill(Color("color-separator-20"))
                        .frame(width: 1, height: 11)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isMiniKVisible.toggle()
                        }
                        HapticManager.instance.impactHaptic(type: .medium)
                    }) {
                        Image(isMiniKVisible ? "sparkline_on" : "sparkline_off")
                            .resizable()
                            .frame(width: 14, height: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: nameWidth, alignment: .leading)
                .padding(.leading, 16)
                .position(x: nameWidth / 2, y: 18)

                HStack(spacing: 2) {
                    Text(language.text(.price))
                        .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                        .accessibilityIdentifier("watchlist.header.price")
                    Image("Glyph_Sort")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 16)
                }
                .foregroundColor(Color("color-text-90"))
                .frame(width: 90, alignment: .trailing)
                .position(x: proxy.size.width - 110 - 45, y: 18)

                HStack(spacing: 2) {
                    Text(language.text(.changePercent))
                        .accessibilityLabel(language == .english ? "Percentage Change" : language.text(.changePercent))
                        .accessibilityIdentifier("watchlist.header.changePercent")
                        .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                    Image("Glyph_Sort")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 16)
                }
                .foregroundColor(Color("color-text-90"))
                .frame(width: 90, alignment: .trailing)
                .padding(.trailing, 10)
                .position(x: proxy.size.width - 47, y: 18)
            }
        }
        .frame(height: 36)
        .background(Color("color-base-1"))
        .overlay(
            Rectangle()
                .fill(Color("color-separator-10"))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

struct WatchlistRedesignRow: View {
    let item: WatchlistRedesignItem
    let isMiniKVisible: Bool

    @State private var flashColor = Color.clear
    @State private var isFlashVisible = false
    @State private var flashWorkItem: DispatchWorkItem?

    var body: some View {
        GeometryReader { proxy in
            let nameWidth = max(CGFloat(110), proxy.size.width - 252)

            ZStack(alignment: .leading) {
                WatchlistRedesignNameCell(item: item)
                    .frame(width: nameWidth, height: 66, alignment: .leading)
                    .clipped()
                    .position(x: nameWidth / 2, y: 33)

                if isMiniKVisible && item.supportsMiniK {
                    WatchlistRedesignMiniKLine(
                        points: item.miniKPoints,
                        trend: item.trend
                    )
                    .frame(width: 52, height: 28)
                    .position(x: proxy.size.width - 200 - 26, y: 33)
                    .transition(.opacity)
                }

                WatchlistRedesignPriceCell(item: item)
                    .frame(width: 90, height: 66)
                    .position(x: proxy.size.width - 110 - 45, y: 33)

                WatchlistRedesignChangeCell(item: item)
                    .frame(width: 90, height: 66)
                    .position(x: proxy.size.width - 45, y: 33)
            }
            .frame(width: proxy.size.width, height: 66, alignment: .leading)
        }
        .frame(height: 66)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: flashColor.opacity(0), location: 0),
                    .init(color: flashColor.opacity(0.08), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
                .opacity(isFlashVisible ? 1 : 0)
                .allowsHitTesting(false)
        )
        .onChange(of: item.price) { oldPrice, newPrice in
            playPriceFlash(oldPrice: oldPrice, newPrice: newPrice)
        }
        .onDisappear {
            flashWorkItem?.cancel()
        }
    }

    private func playPriceFlash(oldPrice: String, newPrice: String) {
        let oldValue = oldPrice.numericWatchlistPrice
        let newValue = newPrice.numericWatchlistPrice

        guard oldValue != newValue else { return }

        flashWorkItem?.cancel()
        flashColor = oldValue < newValue ? Color("color-utility3-red") : Color("color-utility3-green")
        isFlashVisible = true

        let workItem = DispatchWorkItem {
            isFlashVisible = false
        }

        flashWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
}

private extension WatchlistRedesignItem {
    var backgroundColor: Color {
        isPinned ? Color("color-scale-1") : Color("color-base-1")
    }

    var supportsMiniK: Bool {
        market != .fund
    }
}

private extension String {
    var numericWatchlistPrice: Double {
        Double(replacingOccurrences(of: ",", with: "")) ?? 0
    }
}

struct WatchlistRedesignNameCell: View {
    let item: WatchlistRedesignItem
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 4) {
                marketBadge
                    .frame(width: 12, height: 10)

                Text(language.watchlistName(symbol: item.symbol, fallback: item.name))
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
            }

            HStack(spacing: 2) {
                Text(item.symbol)
                    .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)

                ForEach(item.tagAssets, id: \.self) { asset in
                    Image(asset)
                        .resizable()
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.leading, 16)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var marketBadge: some View {
        switch item.market {
        case .hk:
            Image("Glyph_HK").resizable()
        case .cn:
            Image("Glyph_SZ").resizable()
        case .us:
            Image("Glyph_US").resizable()
        case .crypto:
            Image("market_crypto").resizable()
        case .fund:
            Image("market_MF").resizable()
        }
    }
}

struct WatchlistRedesignPriceCell: View {
    let item: WatchlistRedesignItem

    var body: some View {
        VStack(alignment: .trailing, spacing: 7) {
            Text(item.price)
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                .monospacedDigit()
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let secondaryPrice = item.secondaryPrice {
                Text(secondaryPrice)
                    .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                    .monospacedDigit()
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}

struct WatchlistRedesignChangeCell: View {
    let item: WatchlistRedesignItem
    @Environment(\.demoLanguage) private var language

    var body: some View {
        switch item.session {
        case .regular:
            regularTile
        case .preMarket(let label, let change), .afterHours(let label, let change):
            extendedHoursTile(label: label, change: change)
        }
    }

    private var regularTile: some View {
        HStack(spacing: 2) {
            changeIcon(contrast: .white)
                .frame(width: 12, height: 12)
            Text(item.changePercent)
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 20))
                .monospacedDigit()
                .foregroundColor(regularForegroundColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 82, height: 28)
        .background(regularBackgroundColor)
        .cornerRadius(8)
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }

    private func extendedHoursTile(label: String, change: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 2) {
                changeIcon(contrast: .tinted)
                    .frame(width: 12, height: 12)
                Text(item.changePercent)
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 20))
                    .monospacedDigit()
                    .foregroundColor(tileColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 82, height: 26)
            .background(tileColor.opacity(0.15))
            .cornerRadius(8)

            HStack(spacing: 4) {
                Text(change)
                    .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                    .monospacedDigit()
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                    .allowsTightening(true)

                Spacer(minLength: 4)

                Text(language.sessionTitle(label))
                    .accessibilityLabel(
                        language == .english
                            ? (label == "盘前" ? "Pre-market" : "After-hours")
                            : language.sessionTitle(label)
                    )
                    .modifier(CustomFontModifier(size: 8, font: .regular, lineHeight: 8))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                    .allowsTightening(true)
                    .padding(.horizontal, 4)
                    .frame(height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color("color-separator-20"), lineWidth: 0.5)
                    )
            }
            .frame(width: 82, alignment: .leading)
        }
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func changeIcon(contrast: WatchlistRedesignIconContrast) -> some View {
        switch (item.trend, contrast) {
        case (.up, .white):
            Image("watchlistItem_up_white").resizable()
        case (.down, .white):
            Image("watchlistItem_down_white").resizable()
        case (.flat, .white):
            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)
        case (.up, .tinted):
            Image("watchlistItem_up_red").resizable()
        case (.down, .tinted):
            Image("watchlistItem_down_green").resizable()
        case (.flat, .tinted):
            Circle()
                .fill(Color("color-text-90"))
                .frame(width: 5, height: 5)
        }
    }

    private var regularForegroundColor: Color {
        .white
    }

    private var regularBackgroundColor: Color {
        item.trend == .flat ? Color("color-text-90") : tileColor
    }

    private var tileColor: Color {
        switch item.trend {
        case .up:
            return Color("color-utility3-red")
        case .down:
            return Color("color-utility3-green")
        case .flat:
            return Color("color-text-90")
        }
    }
}

enum WatchlistRedesignIconContrast {
    case white
    case tinted
}

struct WatchlistRedesignMiniKLine: View {
    let points: [CGFloat]
    let trend: WatchlistRedesignTrend

    var body: some View {
        ZStack {
            WatchlistRedesignReferenceLine()
                .stroke(Color("color-separator-20"), style: StrokeStyle(lineWidth: 0.5, dash: [1.5, 2]))
                .frame(height: 1)

            MiniLineGraph(dataPoints: points)
                .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 52, height: 28)
    }

    private var lineColor: Color {
        switch trend {
        case .up:
            return Color("color-utility3-red")
        case .down:
            return Color("color-utility3-green")
        case .flat:
            return Color("color-text-90")
        }
    }
}

struct WatchlistRedesignReferenceLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

struct WatchlistRedesignActions: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 2) {
            Button(action: {}) {
                WatchlistRedesignActionButtonLabel(
                    title: language.text(.addToWatchlist),
                    leftRadius: 12,
                    rightRadius: 4
                )
            }
            .buttonStyle(WatchlistRedesignActionPressStyle())

            Button(action: {}) {
                WatchlistRedesignActionButtonLabel(
                    title: language.text(.editWatchlist),
                    leftRadius: 4,
                    rightRadius: 12
                )
            }
            .buttonStyle(WatchlistRedesignActionPressStyle())
        }
        .padding(.horizontal, 16)
    }
}

struct WatchlistRedesignDemoViewPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WatchlistRedesignDemoView()
        }
        .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
    }
}
