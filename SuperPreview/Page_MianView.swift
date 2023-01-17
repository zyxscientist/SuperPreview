//
//  Page_MianView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/28.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Page_MianView: View {
    
    @State var selectedTab: Tabs = .tab1
    
    
    var body: some View {
        
        NavigationView {
            if #available(iOS 14.0, *) {
                TabView(selection: $selectedTab){
                    Page_Compare().tabItem{
                        VStack {
                            if selectedTab == .tab1 {
                                Image("warchlist_active")
                            } else {
                                Image("warchlist_inactive")
                            }
                            Text("自选")
                        }
                    }.tag(Tabs.tab1)
                    
                    Page_Trade().tabItem{
                        VStack {
                            if selectedTab == .tab2 {
                                Image("trade_active")
                            } else {
                                Image("trade_inactive")
                            }
                            Text("交易")
                        }
                    }.tag(Tabs.tab2)
                    
                    Page_Headertab().tabItem{
                        VStack {
                            if selectedTab == .tab3 {
                                Image("wealth_active")
                            } else {
                                Image("wealth_inactive")
                            }
                            Text("理财")
                        }
                    }.tag(Tabs.tab3)
                    
                    
                    Page_News().tabItem{
                        VStack {
                            if selectedTab == .tab4 {
                                Image("bookmark_active")
                            } else {
                                Image("bookmark_inactive")
                            }
                            Text("资讯")
                        }
                    }.tag(Tabs.tab4)
                    
                    Comp_LineChart().tabItem{
                        VStack {
                            if selectedTab == .tab5 {
                                Image("market_active")
                            } else {
                                Image("market_inactive")
                            }
                            Text("市场")
                        }
                    }.tag(Tabs.tab5)
                }
                
                // 解决 iOS 15 TabView 组件背景透明问题
                .onAppear {
                    if #available(iOS 15.0, *) {
                        let appearance = UITabBarAppearance()
                        UITabBar.appearance().scrollEdgeAppearance = appearance
                    }
                }
                
                .navigationBarColor(backgroundColor: UIColor(SwiftUI.Color("color-base-1")), titleColor: UIColor(SwiftUI.Color("color-text-30")))
                .navigationBarTitle(returnNavigationBarTitle(selectedTab: self.selectedTab), displayMode: .inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if returnNavigationBarTitle(selectedTab: self.selectedTab) == "" {
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
        .overlay(LaunchScreen())
        .navigationViewStyle(StackNavigationViewStyle())
    }

enum Tabs {
    case tab1, tab2, tab3, tab4, tab5
}


func returnNavigationBarTitle(selectedTab :Tabs) -> String {
    switch selectedTab {
        case .tab1: return ""
        case .tab2: return "交易"
        case .tab3: return "理财"
        case .tab4: return "资讯"
        case .tab5: return "市场"
        }
    }
}

struct Page_MianView_Previews: PreviewProvider {
    static var previews: some View {
            Page_MianView()
    }
}

