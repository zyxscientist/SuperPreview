//
//  AppDelegate.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/8/30.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import UIKit
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if PreviewRuntime.isUITesting {
            resetPersistedUIStateForUITests()
        } else if !PreviewRuntime.isRunning {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
        }
        return true
    }

    private func resetPersistedUIStateForUITests() {
        var keys = [
            DemoLanguage.storageKey,
            TradeAggregationExpansionStorageKey.stockSubAssetCard,
            TradeAggregationExpansionStorageKey.fundSubAssetCard,
            TradeAggregationExpansionStorageKey.virtualAssetSubAssetCard,
            TradeAggregationExpansionStorageKey.stockHoldingGroups,
            TradeAggregationExpansionStorageKey.fundHoldingGroups,
            TradeAggregationExpansionStorageKey.virtualAssetHoldingGroups,
            StockDetailScrollStorageKey.quoteDataIsExpanded
        ]

        // The high-frequency switches deliberately have a persistence test.
        // Reset them only for launches that explicitly request a clean test
        // fixture; ordinary UI-test relaunches must preserve the preference.
        if ProcessInfo.processInfo.environment["UITEST_RESET_HIGH_FREQUENCY_TRADING"] == "1" {
            UserDefaults.standard.set(
                false,
                forKey: StockOrderAdvancedTradingPreferences.enabledKey
            )
            UserDefaults.standard.set(
                StockOrderAdvancedTradingVersion.v0.rawValue,
                forKey: StockOrderAdvancedTradingPreferences.versionKey
            )
        }

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
