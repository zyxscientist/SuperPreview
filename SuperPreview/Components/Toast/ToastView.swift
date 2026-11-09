import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .circular)

        Text(message)
            .modifier(CustomFontModifier(size: 16, font: .bold))
            .fontWeight(.bold)
            .foregroundStyle(Color("color-text1"))
            .lineLimit(1)
            .frame(minHeight: 24)
            // The design's 14 × 6 padding is measured inside its 1 pt border.
            .padding(.horizontal, 15)
            .padding(.vertical, 7)
            .background {
                shape.fill(Color("color-grayscale2"))
            }
            .overlay {
                shape.strokeBorder(Color("color-separator1"), lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(message)
            .accessibilityIdentifier("toast.message")
    }
}

extension EnvironmentValues {
    @Entry var toastDemoIsEnabled: Binding<Bool>? = nil
    @Entry var toastPresenter: ToastPresenter? = nil
}

struct DemoToastControls: View {
    @Environment(\.toastDemoIsEnabled) private var isEnabled
    @Environment(\.toastPresenter) private var presenter
    @Environment(\.demoLanguage) private var language

    private static let queueSample: [DemoCopyKey] = [
        .toastOrderSubmitted, .toastAddedToWatchlist, .toastOrderCancelled
    ]

    var body: some View {
        if let isEnabled, let presenter {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(language.text(.simulateToast), isOn: isEnabled)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color("color-text1"))
                    .accessibilityIdentifier("debug.toast.simulation")

                Button(language.text(.simulateToastQueue)) {
                    for key in Self.queueSample {
                        presenter.show(language.text(key))
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color("color-blue1"))
                .accessibilityIdentifier("debug.toast.queue")
            }
        }
    }
}

#Preview {
    ToastView(message: "订单已提交")
        .padding()
}
