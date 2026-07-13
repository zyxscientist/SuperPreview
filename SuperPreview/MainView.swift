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
                ZStack{
                    TabView(selection: $selectedTab){
                        CompareView().tabItem{
                            VStack {
                                if selectedTab == .tab1 {
                                    Image("warchlist_active")
                                } else {
                                    Image("warchlist_inactive")
                                }
                                Text("自选")
                            }
                        }.tag(AppTab.tab1)
                        
                        TradeView().tabItem{
                            VStack {
                                if selectedTab == .tab2 {
                                    Image("trade_active")
                                } else {
                                    Image("trade_inactive")
                                }
                                Text("交易")
                            }
                        }.tag(AppTab.tab2)
                        
                        WealthView().tabItem{
                            VStack {
                                if selectedTab == .tab3 {
                                    Image("wealth_active")
                                } else {
                                    Image("wealth_inactive")
                                }
                                Text("理财")
                            }
                        }.tag(AppTab.tab3)
                        
                        
                        NewsView().tabItem{
                            VStack {
                                if selectedTab == .tab4 {
                                    Image("bookmark_active")
                                } else {
                                    Image("bookmark_inactive")
                                }
                                Text("资讯")
                            }
                        }.tag(AppTab.tab4)
                        
                        LineChartView().tabItem{
                            VStack {
                                if selectedTab == .tab5 {
                                    Image("market_active")
                                } else {
                                    Image("market_inactive")
                                }
                                Text("市场")
                            }
                        }.tag(AppTab.tab5)
                    }
                }
                // 解决 iOS 15 TabView 组件背景透明问题
                .onAppear {
                    guard !isPreview else { return }
                    if #available(iOS 15.0, *) {
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

enum AppTab {
    case tab1, tab2, tab3, tab4, tab5
}


func navigationBarTitle(selectedTab :AppTab) -> String {
    switch selectedTab {
        case .tab1: return ""
        case .tab2: return "交易"
        case .tab3: return "理财"
        case .tab4: return "资讯"
        case .tab5: return "市场"
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
