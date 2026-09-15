//
//  MarketView.swift
//  SuperPreview
//
//  组件名称：市场空白页
//  简介：承载市场入口的 HeaderTab 和后续市场内容。
//  用于：主 Tab 的市场入口，页面内容暂留空白。
//

import SwiftUI

struct MarketView: View {
    private static let marketTabs = ["港股", "美股", "沪深港通", "加密货币", "RWA"]

    private let externalDebugPresentation: Binding<Bool>?
    @State private var selectedTab = "港股"
    @State private var isShowingDebugPanel = false
    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore
    @EnvironmentObject private var demoAppearanceStore: DemoAppearanceStore

    init(debugPresentation: Binding<Bool>? = nil) {
        self.externalDebugPresentation = debugPresentation
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

            TabView(selection: $selectedTab) {
                ForEach(Self.marketTabs, id: \.self) { tab in
                    Color("color-base-1")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(tab)
                        .accessibilityIdentifier("market.content.\(tab)")
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                isReducedLiquidGlassUsageEnabled: reducedLiquidGlassUsageBinding
            )
            .environment(\.demoLanguage, demoLanguage)
            .presentationDragIndicator(.visible)
        }
        .onChange(of: externalDebugPresentation?.wrappedValue ?? false) { _, isPresented in
            guard isPresented != isShowingDebugPanel else { return }
            isShowingDebugPanel = isPresented
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

    private var reducedLiquidGlassUsageBinding: Binding<Bool> {
        Binding(
            get: { demoAppearanceStore.isReducedLiquidGlassUsageEnabled },
            set: { demoAppearanceStore.setReducedLiquidGlassUsageEnabled($0) }
        )
    }
}

private struct MarketDebugPanel: View {
    @Binding var language: DemoLanguage
    @Binding var isReducedLiquidGlassUsageEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var interfaceLanguage

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

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color("color-base-1").ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.debug.panel")
    }
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
