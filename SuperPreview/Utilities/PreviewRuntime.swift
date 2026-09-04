//
//  PreviewRuntime.swift
//  SuperPreview
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
