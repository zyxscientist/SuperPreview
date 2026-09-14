//
//  PreviewRuntime.swift
//  SuperPreview
//
//  组件名称：预览运行环境检测
//  简介：识别 SwiftUI Preview、UI 测试和普通应用运行环境。
//  用于：让 Demo 的调试交互在不同运行环境下采用正确行为。
//

import Foundation

enum PreviewRuntime {
    static var isRunning: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static var isUITesting: Bool {
        let processInfo = ProcessInfo.processInfo
        return processInfo.arguments.contains("-UITesting")
            || processInfo.environment["UITEST_MODE"] == "1"
    }

    #if DEBUG
    static var isBackSwipeHarnessTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-BackSwipeHarness")
    }
    #endif
}
