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
    private let isPreview = PreviewRuntime.isRunning || PreviewRuntime.isUITesting
    
    var body: some View {
        
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
                        WealthView()
                    }
                    tabLayer(.tab4) {
                        NewsView()
                    }
                    tabLayer(.tab5) {
                        LineChartView()
                    }
                    tabLayer(.tab6) {
                        CompareView()
                    }
                }
                .mainTabBar(selectedTab: $selectedTab)
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
                .navigationBarTitle(navigationBarTitle(selectedTab: self.selectedTab), displayMode: .inline)
                .modifier(
                    MainViewToolbarModifier(
                        selectedTab: selectedTab,
                        language: demoLanguageStore.language,
                        watchlistDebugPresentation: $isShowingWatchlistDebugPanel,
                        tradeDebugPresentation: $isShowingTradeDebugPanel
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

    func navigationBarTitle(selectedTab :AppTab) -> String {
        switch selectedTab {
        case .tab1: return ""
        case .tab2: return "交易"
        case .tab3: return "理财"
        case .tab4: return "资讯"
        case .tab5: return "市场"
        case .tab6: return "我的"
        }
    }
}

private struct MainViewToolbarModifier: ViewModifier {
    let selectedTab: AppTab
    let language: DemoLanguage
    @Binding var watchlistDebugPresentation: Bool
    @Binding var tradeDebugPresentation: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if selectedTab == .tab1 {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Image("navbar_logo_sc")
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    debugButton(
                        identifier: "watchlist.debug.open",
                        action: { watchlistDebugPresentation = true }
                    )
                }
            }
        } else if selectedTab == .tab2 {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    debugButton(
                        identifier: "trade.debug.open",
                        action: { tradeDebugPresentation = true }
                    )
                }
            }
        } else {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Image("search-Right")
                }
            }
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
