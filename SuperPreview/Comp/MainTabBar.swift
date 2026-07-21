//
//  MainTabBar.swift
//  SuperPreview
//
//  Created by Codex on 2026/7/21.
//

import SwiftUI
import UIKit

enum AppTab: Int, CaseIterable {
    case tab1
    case tab2
    case tab3
    case tab4
    case tab5
    case tab6

    var title: String {
        switch self {
        case .tab1: return "自选"
        case .tab2: return "交易"
        case .tab3: return "理财"
        case .tab4: return "资讯"
        case .tab5: return "市场"
        case .tab6: return "我的"
        }
    }

    var activeImageName: String {
        switch self {
        case .tab1: return "warchlist_active"
        case .tab2: return "trade_active"
        case .tab3: return "wealth_active"
        case .tab4: return "bookmark_active"
        case .tab5: return "market_active"
        case .tab6: return "me_active"
        }
    }

    var inactiveImageName: String {
        switch self {
        case .tab1: return "warchlist_inactive"
        case .tab2: return "trade_inactive"
        case .tab3: return "wealth_inactive"
        case .tab4: return "bookmark_inactive"
        case .tab5: return "market_inactive"
        case .tab6: return "me_inactive"
        }
    }
}

struct MainTabBar: UIViewRepresentable {
    @Binding var selectedTab: AppTab

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITabBar {
        let tabBar = UITabBar()
        tabBar.delegate = context.coordinator
        tabBar.itemPositioning = .fill
        tabBar.items = AppTab.allCases.map(makeItem)
        tabBar.selectedItem = tabBar.items?.first(where: { $0.tag == selectedTab.rawValue })
        return tabBar
    }

    func updateUIView(_ tabBar: UITabBar, context: Context) {
        context.coordinator.parent = self
        tabBar.selectedItem = tabBar.items?.first(where: { $0.tag == selectedTab.rawValue })
    }

    private func makeItem(for tab: AppTab) -> UITabBarItem {
        let item = UITabBarItem(
            title: tab.title,
            image: UIImage(named: tab.inactiveImageName),
            selectedImage: UIImage(named: tab.activeImageName)
        )
        item.tag = tab.rawValue
        return item
    }

    final class Coordinator: NSObject, UITabBarDelegate {
        var parent: MainTabBar

        init(parent: MainTabBar) {
            self.parent = parent
        }

        func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            guard let tab = AppTab(rawValue: item.tag) else { return }
            parent.selectedTab = tab
        }
    }
}
