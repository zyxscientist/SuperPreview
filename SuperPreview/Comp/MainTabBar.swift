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

    func title(language: DemoLanguage) -> String {
        switch self {
        case .tab1: return language.text(.watchlist)
        case .tab2: return language.text(.trade)
        case .tab3: return language.text(.wealth)
        case .tab4: return language.text(.news)
        case .tab5: return language.text(.markets)
        case .tab6: return language.text(.me)
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
    static let height: CGFloat = 49

    @Binding var selectedTab: AppTab
    @Environment(\.demoLanguage) private var language

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITabBar {
        let tabBar = UITabBar()
        tabBar.isTranslucent = true
        tabBar.delegate = context.coordinator
        tabBar.itemPositioning = .fill
        tabBar.items = AppTab.allCases.map(makeItem)
        tabBar.selectedItem = tabBar.items?.first(where: { $0.tag == selectedTab.rawValue })
        return tabBar
    }

    func updateUIView(_ tabBar: UITabBar, context: Context) {
        context.coordinator.parent = self
        if tabBar.items?.count != AppTab.allCases.count {
            tabBar.items = AppTab.allCases.map(makeItem)
        } else {
            for (item, tab) in zip(tabBar.items ?? [], AppTab.allCases) {
                let title = tab.title(language: language)
                if item.title != title {
                    item.title = title
                }
            }
        }
        let selectedItem = tabBar.items?.first(where: { $0.tag == selectedTab.rawValue })
        // UIKit already selects the tapped item before the Binding update.
        // Leave that selection untouched so its native animation can finish.
        if tabBar.selectedItem !== selectedItem {
            tabBar.selectedItem = selectedItem
        }
    }

    private func makeItem(for tab: AppTab) -> UITabBarItem {
        let item = UITabBarItem(
            title: tab.title(language: language),
            image: UIImage(named: tab.inactiveImageName),
            selectedImage: UIImage(named: tab.activeImageName)
        )
        item.tag = tab.rawValue
        item.accessibilityIdentifier = "mainTab.tab\(tab.rawValue + 1)"
        return item
    }

    final class Coordinator: NSObject, UITabBarDelegate {
        var parent: MainTabBar

        init(parent: MainTabBar) {
            self.parent = parent
        }

        func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            guard let tab = AppTab(rawValue: item.tag), parent.selectedTab != tab else { return }
            parent.selectedTab = tab
        }
    }
}

private struct MainTabBarContainerModifier: ViewModifier {
    @Binding var selectedTab: AppTab

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .bottom, spacing: 0) {
                    MainTabBar(selectedTab: $selectedTab)
                        .frame(height: MainTabBar.height)
                }
                .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    MainTabBar(selectedTab: $selectedTab)
                        .frame(height: MainTabBar.height)
                }
        }
    }
}

extension View {
    func mainTabBar(selectedTab: Binding<AppTab>) -> some View {
        modifier(MainTabBarContainerModifier(selectedTab: selectedTab))
    }

    func mainTabBar(if isEnabled: Bool, selectedTab: Binding<AppTab>) -> some View {
        modifier(ConditionalMainTabBarModifier(isEnabled: isEnabled, selectedTab: selectedTab))
    }

    func navigationBarDebugItem(
        isEnabled: Bool,
        title: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            ConditionalNavigationBarDebugItemModifier(
                isEnabled: isEnabled,
                title: title,
                identifier: identifier,
                action: action
            )
        )
    }

    func navigationBarTitleIfEnabled(_ title: String, isEnabled: Bool) -> some View {
        modifier(
            ConditionalNavigationBarTitleModifier(
                isEnabled: isEnabled,
                title: title
            )
        )
    }
}

private struct ConditionalMainTabBarModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var selectedTab: AppTab

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.mainTabBar(selectedTab: $selectedTab)
        } else {
            content
        }
    }
}

private struct ConditionalNavigationBarDebugItemModifier: ViewModifier {
    let isEnabled: Bool
    let title: String
    let identifier: String
    let action: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.navigationBarItems(
                trailing: Button(action: action) {
                    Text(title)
                        .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                        .foregroundColor(Color("color-text-30"))
                }
                .accessibilityIdentifier(identifier)
            )
        } else {
            content
        }
    }
}

private struct ConditionalNavigationBarTitleModifier: ViewModifier {
    let isEnabled: Bool
    let title: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.navigationBarTitle(title, displayMode: .inline)
        } else {
            content
        }
    }
}
