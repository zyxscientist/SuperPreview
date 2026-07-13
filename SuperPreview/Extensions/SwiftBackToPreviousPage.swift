//
//  SwiftBackToPreviousPage.swift
//  SuperPreview
//
//  Created by admin on 2023/1/9.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import Foundation
import SwiftUI
// 自定义Navigationbar经常需要隐藏系统提供的返回按钮，
// 隐藏系统的返回按钮需要使用到 .navigationBarBackButtonHidden(true)，但是这将使得滑动返回也失效，所以在这个页面要添加以下拓展保留滑动返回
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
// END
