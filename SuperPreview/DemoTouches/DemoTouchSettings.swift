import SwiftUI
import Combine

/// Shared by every debug panel and every app scene.
@MainActor
final class DemoTouchSettings: ObservableObject {
    static let shared = DemoTouchSettings()
    private static let storageKey = "demoTouches.showTouches"

    static var isAvailable: Bool {
        #if DEBUG || DEMO_TOUCHES
        return !PreviewRuntime.isUITesting && !PreviewRuntime.isRunning
        #else
        return false
        #endif
    }

    @Published var isEnabled: Bool {
        didSet {
            guard Self.isAvailable else { return }
            UserDefaults.standard.set(isEnabled, forKey: Self.storageKey)
        }
    }

    private init() {
        isEnabled = Self.isAvailable && (
            UserDefaults.standard.bool(forKey: Self.storageKey)
                || ProcessInfo.processInfo.arguments.contains("-ShowTouches")
        )
    }
}

struct DemoTouchToggle: View {
    @ObservedObject private var settings = DemoTouchSettings.shared

    var body: some View {
        if DemoTouchSettings.isAvailable {
            Toggle("Show Touch", isOn: $settings.isEnabled)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("color-text-30"))
                .accessibilityIdentifier("debug.showTouch")
        }
    }
}
