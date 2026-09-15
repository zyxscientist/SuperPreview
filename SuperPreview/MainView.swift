//
//  MainView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/28.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct MainView: View {
    
    @State var selectedTab: AppTab = .tab1
    @State var marketOpen = true
    @StateObject private var demoLanguageStore = DemoLanguageStore()
    @StateObject private var demoAppearanceStore = DemoAppearanceStore()
    @State private var isShowingWatchlistDebugPanel = false
    @State private var isShowingTradeDebugPanel = false
    @State private var isShowingMarketDebugPanel = false
    private let isPreview = PreviewRuntime.isRunning || PreviewRuntime.isUITesting
    
    @ViewBuilder
    var body: some View {
        #if DEBUG
        if PreviewRuntime.isBackSwipeHarnessTesting {
            NavigationBackSwipeHarnessView()
        } else {
            mainContent
        }
        #else
        mainContent
        #endif
    }

    private var mainContent: some View {
        NavigationView {
            if #available(iOS 14.0, *) {
                ZStack {
                    tabLayer(.tab1) {
                        WatchlistRedesignDemoView(
                            showsMainTabBar: false,
                            showsNavigationBarTitle: false,
                            debugPresentation: $isShowingWatchlistDebugPanel
                        )
                    }
                    tabLayer(.tab2) {
                        TradeAggregationDemoView(
                            showsMainTabBar: false,
                            showsNavigationBarTitle: false,
                            debugPresentation: $isShowingTradeDebugPanel
                        )
                    }
                    tabLayer(.tab3) {
                        MarketView(debugPresentation: $isShowingMarketDebugPanel)
                    }
                    tabLayer(.tab4) {
                        WealthView()
                    }
                    tabLayer(.tab5) {
                        NewsView()
                    }
                    tabLayer(.tab6) {
                        CompareView()
                    }
                }
                .mainTabBar(selectedTab: $selectedTab)
                .background(NavigationBackSwipeInstaller(defaultPolicy: .edge))
                // iOS 26 的系统 UITabBar 会自动使用 Liquid Glass。
                // 旧系统继续保留原有的 TabBar 背景兼容设置。
                .onAppear {
                    guard !isPreview else { return }
                    if #available(iOS 26.0, *) {
                        // Do not override the system-provided Liquid Glass appearance.
                    } else if #available(iOS 15.0, *) {
                        let appearance = UITabBarAppearance()
                        UITabBar.appearance().scrollEdgeAppearance = appearance
                    }
                }
                
                .navigationBarColor(backgroundColor: UIColor(SwiftUI.Color("color-base-1")), titleColor: UIColor(SwiftUI.Color("color-text-30")))
                .navigationBarTitle(
                    navigationBarTitle(
                        selectedTab: self.selectedTab,
                        language: demoLanguageStore.language
                    ),
                    displayMode: .inline
                )
                .modifier(
                    MainViewToolbarModifier(
                        selectedTab: selectedTab,
                        language: demoLanguageStore.language,
                        watchlistDebugPresentation: $isShowingWatchlistDebugPanel,
                        tradeDebugPresentation: $isShowingTradeDebugPanel,
                        marketDebugPresentation: $isShowingMarketDebugPanel
                    )
                )
            } else {
                // Fallback on earlier versions
            }
        }
        // Inject above NavigationView so every NavigationLink destination gets
        // the same language store as the source page.
        .environmentObject(demoLanguageStore)
        .environmentObject(demoAppearanceStore)
        .environment(\.demoLanguage, demoLanguageStore.language)
        .overlay {
            if !isPreview {
                LaunchScreen()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private func tabLayer<Content: View>(
        _ tab: AppTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
            .zIndex(selectedTab == tab ? 1 : 0)
    }

    func navigationBarTitle(selectedTab: AppTab, language: DemoLanguage) -> String {
        switch selectedTab {
        case .tab1: return language.text(.watchlist)
        case .tab2: return language.text(.trade)
        case .tab3: return language.text(.markets)
        case .tab4: return language.text(.wealth)
        case .tab5: return language.text(.news)
        case .tab6: return language.text(.me)
        }
    }
}

private struct MainViewToolbarModifier: ViewModifier {
    let selectedTab: AppTab
    let language: DemoLanguage
    @Binding var watchlistDebugPresentation: Bool
    @Binding var tradeDebugPresentation: Bool
    @Binding var marketDebugPresentation: Bool

    func body(content: Content) -> some View {
        // Keep the content (including UITabBar and all tab pages) at the same
        // structural identity when only the trailing toolbar item changes.
        content.toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if selectedTab == .tab1 || selectedTab == .tab2 || selectedTab == .tab3 {
                    debugButton(
                        identifier: debugIdentifier,
                        action: {
                            if selectedTab == .tab1 {
                                watchlistDebugPresentation = true
                            } else if selectedTab == .tab2 {
                                tradeDebugPresentation = true
                            } else {
                                marketDebugPresentation = true
                            }
                        }
                    )
                } else {
                    Image("search-Right")
                }
            }
        }
    }

    private var debugIdentifier: String {
        switch selectedTab {
        case .tab1: return "watchlist.debug.open"
        case .tab2: return "trade.debug.open"
        case .tab3: return "market.debug.open"
        default: return "main.debug.open"
        }
    }

    private func debugButton(
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(language.text(.debug))
                .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                .foregroundColor(Color("color-text-30"))
        }
        .accessibilityIdentifier(identifier)
    }
}

struct MainViewPreviews: PreviewProvider {
    static var previews: some View {
            MainView()
    }
}

// 实现改变特定角圆角的方法

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
