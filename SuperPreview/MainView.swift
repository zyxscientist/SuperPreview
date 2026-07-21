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
    private let isPreview = PreviewRuntime.isRunning
    
    var body: some View {
        
        NavigationView {
            if #available(iOS 14.0, *) {
                ZStack {
                    tabLayer(.tab1) {
                        CompareView()
                    }
                    tabLayer(.tab2) {
                        TradeView()
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
                        Color("color-base-1")
                            .ignoresSafeArea()
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MainTabBar(selectedTab: $selectedTab)
                        .frame(height: 49)
                }
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
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if navigationBarTitle(selectedTab: self.selectedTab) == "" {
                            Image("navbar_logo_sc")
                        } else {
                            EmptyView()
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Image("search-Right")
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
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
