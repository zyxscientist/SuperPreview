//
//  SceneDelegate.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/8/30.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var hasUpdatedAppIconForCurrentSession = false


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = MainView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            #if DEBUG || DEMO_TOUCHES
            let window = DemoTouchWindow(windowScene: windowScene)
            #else
            let window = UIWindow(windowScene: windowScene)
            #endif
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        #if DEBUG || DEMO_TOUCHES
        (window as? DemoTouchWindow)?.clearTouchIndicators()
        #endif
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        DispatchQueue.main.async { [weak self] in
            self?.updateAppIconForCurrentSystem()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        #if DEBUG || DEMO_TOUCHES
        (window as? DemoTouchWindow)?.clearTouchIndicators()
        #endif
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func updateAppIconForCurrentSystem() {
        guard !hasUpdatedAppIconForCurrentSession, !PreviewRuntime.isUITesting else { return }

        let application = UIApplication.shared
        guard application.supportsAlternateIcons else { return }

        let desiredIconName: String?
        if #available(iOS 27.0, *) {
            desiredIconName = "logo"
        } else {
            desiredIconName = nil
        }

        guard application.alternateIconName != desiredIconName else {
            hasUpdatedAppIconForCurrentSession = true
            return
        }
        hasUpdatedAppIconForCurrentSession = true

        application.setAlternateIconName(desiredIconName) { error in
            if let error {
                print("Unable to update the app icon: \(error.localizedDescription)")
            }
        }
    }


}
