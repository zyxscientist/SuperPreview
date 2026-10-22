//
//  MarketView.swift
//  SuperPreview
//
//  组件名称：市场页
//  简介：承载市场 HeaderTab、共享地球仪与指数卡片。
//  用于：主 Tab 的市场入口。
//

import SwiftUI
import UIKit

struct MarketView: View {
    private static let marketTabs = ["港股", "美股", "沪深港通", "加密货币", "RWA"]

    private let externalDebugPresentation: Binding<Bool>?
    private let isActive: Bool
    @State private var selectedTab = "港股"
    @State private var isShowingDebugPanel = false
    @State private var isShaderOnly = false
    @State private var marketGlobeOrientation = MarketGlobeOrientation()
    @State private var globeRotation: MarketGlobeRotation?
    @State private var pageContentHeights: [String: CGFloat] = [:]
    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore
    @EnvironmentObject private var demoAppearanceStore: DemoAppearanceStore

    init(debugPresentation: Binding<Bool>? = nil, isActive: Bool = true) {
        self.externalDebugPresentation = debugPresentation
        self.isActive = isActive
    }

    var body: some View {
        VStack(spacing: 0) {
            WatchlistRedesignTabs(
                tabs: Self.marketTabs,
                selectedTab: $selectedTab,
                fontSize: 14,
                isReducedLiquidGlassUsageEnabled: demoAppearanceStore.isReducedLiquidGlassUsageEnabled,
                titleProvider: demoLanguage.marketTabTitle,
                accessibilityPrefix: "market",
                showsSortMenu: false,
                leadingPadding: 16
            )

            marketContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("color-base-1").ignoresSafeArea())
        .accessibilityIdentifier("market.root")
        .sheet(
            isPresented: $isShowingDebugPanel,
            onDismiss: {
                externalDebugPresentation?.wrappedValue = false
            }
        ) {
            MarketDebugPanel(
                language: demoLanguageBinding,
                isReducedLiquidGlassUsageEnabled: reducedLiquidGlassUsageBinding,
                isShaderOnly: $isShaderOnly,
                globeOrientation: { globeRotation?.value(at: Date()) ?? marketGlobeOrientation },
                selectedTab: selectedTab
            )
            .environment(\.demoLanguage, demoLanguage)
            .presentationDragIndicator(.visible)
        }
        .onChange(of: externalDebugPresentation?.wrappedValue ?? false) { _, isPresented in
            guard isPresented != isShowingDebugPanel else { return }
            isShowingDebugPanel = isPresented
        }
        .environment(\.demoLanguage, demoLanguage)
        .onChange(of: selectedTab) { _, tab in
            let current = globeRotation?.value(at: Date()) ?? marketGlobeOrientation
            if tab == "加密货币" {
                marketGlobeOrientation = current
                globeRotation = .spinning(from: current)
                return
            }
            let target: MarketGlobeOrientation
            switch tab {
            case "港股", "沪深港通": target = MarketGlobeOrientation()
            case "美股": target = .unitedStates
            default:
                marketGlobeOrientation = current
                globeRotation = nil
                return
            }
            globeRotation = MarketGlobeRotation(from: current, to: target)
            marketGlobeOrientation = target
        }
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
            set: { demoAppearanceStore.setReducedLiquidGlassUsageEnabled($0) }
        )
    }

    private var marketContent: some View {
        GeometryReader { viewport in
            // The shared globe and horizontal pager have one vertical scroll
            // owner. The globe keeps its identity while categories page past it.
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    MarketGlobeView(
                        isActive: isActive && showsGlobe,
                        isCrypto: selectedTab == "加密货币",
                        orientation: $marketGlobeOrientation,
                        rotation: $globeRotation
                    )
                    .opacity(showsGlobe ? 1 : 0)
                    .allowsHitTesting(showsGlobe)
                    .accessibilityHidden(!showsGlobe)

                    TabView(selection: $selectedTab) {
                        ForEach(Self.marketTabs, id: \.self) { tab in
                            marketPage(for: tab)
                                .tag(tab)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    // TabView has no intrinsic height inside a ScrollView.
                    // Measure each page's content before filling the pager.
                    .frame(height: max(
                        viewport.size.height - 108,
                        pageContentHeights[selectedTab] ?? 0
                    ))
                    .opacity(isShaderOnly ? 0 : 1)
                    .allowsHitTesting(!isShaderOnly)
                    .accessibilityHidden(isShaderOnly)
                    // Cards overlap the lower globe, as in the original layout.
                    .padding(.top, 108)
                }
                .frame(minHeight: viewport.size.height, alignment: .top)
            }
            .accessibilityIdentifier("market.scroll")
            .onPreferenceChange(MarketPageContentHeightKey.self) { heights in
                pageContentHeights.merge(heights, uniquingKeysWith: { _, new in new })
            }
        }
    }

    private func marketPage(for tab: String) -> some View {
        let indices = MarketIndexQuote.previews(for: tab)

        return VStack(spacing: 32) {
            if !indices.isEmpty {
                MarketIndexCards(
                    indices: indices,
                    reducesGlass: demoAppearanceStore.isReducedLiquidGlassUsageEnabled
                )
                .padding(.horizontal, 16)

                MarketBreadthDistributionView()

                if tab == "港股" {
                    MarketQuickMenu()
                    MarketIPOCenterView()
                }
            }
        }
        .padding(.bottom, 32)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            GeometryReader { content in
                Color.clear.preference(
                    key: MarketPageContentHeightKey.self,
                    value: [tab: content.size.height]
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityIdentifier("market.content.\(tab)")
    }

    private var showsGlobe: Bool {
        selectedTab == "港股" || selectedTab == "美股" || selectedTab == "沪深港通" || selectedTab == "加密货币"
    }
}

private struct MarketPageContentHeightKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct MarketDebugPanel: View {
    @Binding var language: DemoLanguage
    @Binding var isReducedLiquidGlassUsageEnabled: Bool
    @Binding var isShaderOnly: Bool
    let globeOrientation: () -> MarketGlobeOrientation
    let selectedTab: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var interfaceLanguage
    @Environment(\.colorScheme) private var colorScheme
    @State private var shareFile: MarketGlobeShareFile?
    @State private var isShowingExportError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(interfaceLanguage.text(.debug))
                        .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                        .foregroundColor(Color("color-text-30"))

                    Spacer()

                    Button(interfaceLanguage.text(.done)) {
                        dismiss()
                    }
                    .accessibilityIdentifier("market.debug.close")
                }

                DemoLanguagePicker(language: $language)

                DemoTouchToggle()

                DemoLiquidGlassUsageToggle(
                    isReducedLiquidGlassUsageEnabled: $isReducedLiquidGlassUsageEnabled
                )
                .accessibilityIdentifier("market.debug.reduceLiquidGlass")

                Toggle(interfaceLanguage.text(.showShaderOnly), isOn: $isShaderOnly)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("color-text-30"))
                    .accessibilityIdentifier("market.debug.showShaderOnly")

                Button(action: exportGlobeParameters) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")

                        Text(interfaceLanguage.text(.exportMarketGlobeParameters))
                            .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, 16)
                    .foregroundColor(Color("color-brand-blue"))
                    .background(Color("color-brand-blue").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("market.debug.exportParameters")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color("color-base-1").ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.debug.panel")
        .sheet(item: $shareFile) { file in
            MarketActivityView(activityItems: [file.url]) {
                try? FileManager.default.removeItem(at: file.url)
            }
        }
        .alert(isPresented: $isShowingExportError) {
            Alert(
                title: Text(interfaceLanguage.text(.marketGlobeExportFailedTitle)),
                message: Text(interfaceLanguage.text(.marketGlobeExportFailedMessage)),
                dismissButton: .default(Text(interfaceLanguage.text(.done)))
            )
        }
    }

    private func exportGlobeParameters() {
        do {
            let url = try MarketGlobeParameterExporter.makeFile(
                orientation: globeOrientation(),
                language: interfaceLanguage,
                colorScheme: colorScheme,
                selectedTab: selectedTab
            )
            shareFile = MarketGlobeShareFile(url: url)
        } catch {
            isShowingExportError = true
        }
    }
}

private struct MarketGlobeShareFile: Identifiable {
    let url: URL

    var id: String { url.absoluteString }
}

private struct MarketActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onCompletion: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            onCompletion()
        }

        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(
                x: controller.view.bounds.midX,
                y: controller.view.bounds.midY,
                width: 1,
                height: 1
            )
        }

        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MarketView()
                .navigationBarTitle("市场", displayMode: .inline)
        }
        .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
        .environmentObject(DemoAppearanceStore())
    }
}
