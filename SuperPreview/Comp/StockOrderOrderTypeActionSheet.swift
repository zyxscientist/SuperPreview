//
//  StockOrderOrderTypeActionSheet.swift
//  SuperPreview
//

import SwiftUI

struct StockOrderOrderTypeActionSheet: View {
    @Binding var selection: StockOrderOrderType

    let supportedOrderTypes: [StockOrderOrderTypeOption]
    let reduceMotion: Bool
    let onWillDismiss: () -> Void
    let onDismiss: () -> Void

    @Environment(\.demoLanguage) private var language
    @State private var isMaskVisible = false
    @State private var isCardsVisible = false
    @State private var isDismissing = false

    init(
        selection: Binding<StockOrderOrderType>,
        supportedOrderTypes: [StockOrderOrderTypeOption],
        reduceMotion: Bool = false,
        onWillDismiss: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        _selection = selection
        self.supportedOrderTypes = supportedOrderTypes
        self.reduceMotion = reduceMotion
        self.onWillDismiss = onWillDismiss
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                dismissalMask

                VStack(spacing: StockOrderOrderTypeActionSheetLayout.sectionSpacing) {
                    optionsCard
                    cancelButton
                }
                .padding(
                    .horizontal,
                    StockOrderOrderTypeActionSheetLayout.horizontalPadding
                )
                .padding(
                    .bottom,
                    proxy.safeAreaInsets.bottom
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottom
                )
                .offset(
                    y: isCardsVisible
                        ? 0
                        : proxy.size.height
                )
                .animation(
                    reduceMotion
                        ? nil
                        : .easeOut(
                            duration: StockOrderOrderTypeActionSheetLayout.cardTransitionDuration
                        ),
                    value: isCardsVisible
                )
            }
        }
        .onAppear(perform: present)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.orderTypeActionSheet")
    }

    private var dismissalMask: some View {
        Button(action: dismiss) {
            Color.black
                .opacity(
                    isMaskVisible
                        ? StockOrderOrderTypeActionSheetLayout.maskOpacity
                        : 0
                )
                .ignoresSafeArea()
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            reduceMotion
                ? nil
                : .easeOut(
                    duration: StockOrderOrderTypeActionSheetLayout.maskFadeDuration
                ),
            value: isMaskVisible
        )
        .accessibilityLabel(language.text(.cancel))
        .accessibilityIdentifier("stockOrder.orderTypeActionSheet.mask")
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            Text(language.text(.chooseOrderType))
                .modifier(
                    CustomFontModifier(
                        size: 13,
                        font: .regular,
                        lineHeight: 16
                    )
                )
                .foregroundColor(Color("color-text-60"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderOrderTypeActionSheetLayout.titleHeight,
                    maxHeight: StockOrderOrderTypeActionSheetLayout.titleHeight
                )
                .overlay(alignment: .bottom) {
                    separator
                }
                .accessibilityIdentifier("stockOrder.orderTypeActionSheet.title")

            ForEach(Array(supportedOrderTypes.enumerated()), id: \.element.id) { index, option in
                optionButton(option)
                    .overlay(alignment: .bottom) {
                        if index < supportedOrderTypes.count - 1 {
                            separator
                        }
                    }
            }
        }
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderOrderTypeActionSheetLayout.cornerRadius,
                style: .continuous
            )
        )
    }

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text(language.text(.cancel))
                .modifier(
                    CustomFontModifier(
                        size: 18,
                        font: .regular,
                        lineHeight: 24
                    )
                )
                .foregroundColor(Color("color-brand-blue"))
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderOrderTypeActionSheetLayout.rowHeight,
                    maxHeight: StockOrderOrderTypeActionSheetLayout.rowHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderOrderTypeActionSheetLayout.cornerRadius,
                style: .continuous
            )
        )
        .accessibilityLabel(language.text(.cancel))
        .accessibilityIdentifier("stockOrder.orderTypeActionSheet.cancel")
    }

    private var separator: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(height: StockOrderOrderTypeActionSheetLayout.separatorHeight)
            .accessibilityHidden(true)
    }

    private func optionButton(_ option: StockOrderOrderTypeOption) -> some View {
        Button {
            select(option)
        } label: {
            Text(language.text(option.orderType.titleKey))
                .modifier(
                    CustomFontModifier(
                        size: 18,
                        font: .regular,
                        lineHeight: 24
                    )
                )
                .foregroundColor(Color("color-brand-blue"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderOrderTypeActionSheetLayout.rowHeight,
                    maxHeight: StockOrderOrderTypeActionSheetLayout.rowHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(language.text(option.orderType.titleKey))
        .accessibilityIdentifier(
            "stockOrder.orderTypeActionSheet.option.\(option.orderType.rawValue)"
        )
    }

    private func present() {
        guard !isDismissing else { return }

        if reduceMotion {
            isMaskVisible = true
            isCardsVisible = true
            return
        }

        DispatchQueue.main.async {
            guard !isDismissing else { return }

            isMaskVisible = true
            isCardsVisible = true
        }
    }

    private func select(_ option: StockOrderOrderTypeOption) {
        guard !isDismissing else { return }

        selection = option.orderType
        dismiss()
    }

    private func dismiss() {
        guard !isDismissing else { return }

        isDismissing = true
        onWillDismiss()

        if reduceMotion {
            isMaskVisible = false
            isCardsVisible = false
            onDismiss()
            return
        }

        isMaskVisible = false
        isCardsVisible = false

        DispatchQueue.main.asyncAfter(
            deadline: .now()
                + StockOrderOrderTypeActionSheetLayout.cardTransitionDuration
        ) {
            onDismiss()
        }
    }
}

enum StockOrderOrderTypeActionSheetLayout {
    static let horizontalPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 8
    static let titleHeight: CGFloat = 46
    static let rowHeight: CGFloat = 56
    static let separatorHeight: CGFloat = 0.5
    static let cornerRadius: CGFloat = 14
    static let maskOpacity: CGFloat = 0.3
    static let maskFadeDuration: TimeInterval = 0.3
    static let cardTransitionDuration: TimeInterval = 0.3
}

private struct StockOrderOrderTypeActionSheetPreviewHarness: View {
    @State private var selection: StockOrderOrderType = .enhancedLimit

    var body: some View {
        StockOrderOrderTypeActionSheet(
            selection: $selection,
            supportedOrderTypes: StockOrderOrderTypeOptions.hongKong
        )
        .environment(\.demoLanguage, .simplifiedChinese)
    }
}

struct StockOrderOrderTypeActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderOrderTypeActionSheetPreviewHarness()
                .previewDisplayName("Hong Kong · Simplified Chinese")

            StockOrderOrderTypeActionSheet(
                selection: .constant(.enhancedLimit),
                supportedOrderTypes: StockOrderOrderTypeOptions.hongKong
            )
            .environment(\.demoLanguage, .traditionalChinese)
            .preferredColorScheme(.dark)
            .previewDisplayName("Hong Kong · Traditional Chinese · Dark")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
