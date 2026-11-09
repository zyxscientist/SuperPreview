import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .circular)

        Text(message)
            .modifier(CustomFontModifier(size: 16, font: .bold))
            .fontWeight(.bold)
            .foregroundStyle(Color("color-text-30"))
            .lineLimit(1)
            .frame(minHeight: 24)
            // The design's 14 × 6 padding is measured inside its 1 pt border.
            .padding(.horizontal, 15)
            .padding(.vertical, 7)
            .background {
                shape.fill(Color("color-scale-2"))
            }
            .overlay {
                shape.strokeBorder(Color("color-separator-10"), lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(message)
            .accessibilityIdentifier("toast.message")
    }
}

extension EnvironmentValues {
    @Entry var toastDemoIsEnabled: Binding<Bool>? = nil
}

struct DemoToastToggle: View {
    @Environment(\.toastDemoIsEnabled) private var isEnabled
    @Environment(\.demoLanguage) private var language

    var body: some View {
        if let isEnabled {
            Toggle(language.text(.simulateToast), isOn: isEnabled)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color("color-text-30"))
                .accessibilityIdentifier("debug.toast.simulation")
        }
    }
}

#Preview {
    ToastView(message: "订单已提交")
        .padding()
}
