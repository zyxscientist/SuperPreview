//
//  StockOrderEffectPeriodActionSheet.swift
//  SuperPreview
//

import SwiftUI

/// The time-in-force action sheet. Its visual transition intentionally matches
/// the order-type action sheet: the mask fades in place and cards move up from
/// the bottom edge without a spring.
struct StockOrderEffectPeriodActionSheet: View {
    @Binding var selection: StockOrderEffectPeriod

    let reduceMotion: Bool
    let onWillDismiss: () -> Void
    let onDismiss: () -> Void

    @Environment(\.demoLanguage) private var language
    @State private var isMaskVisible = false
    @State private var isCardsVisible = false
    @State private var isDismissing = false

    init(
        selection: Binding<StockOrderEffectPeriod>,
        reduceMotion: Bool = false,
        onWillDismiss: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        _selection = selection
        self.reduceMotion = reduceMotion
        self.onWillDismiss = onWillDismiss
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                dismissalMask

                VStack(spacing: StockOrderEffectPeriodActionSheetLayout.sectionSpacing) {
                    optionsCard
                    cancelButton
                }
                .padding(
                    .horizontal,
                    StockOrderEffectPeriodActionSheetLayout.horizontalPadding
                )
                .padding(
                    .bottom,
                    StockOrderEffectPeriodActionSheetLayout.bottomPadding
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottom
                )
                .offset(y: isCardsVisible ? 0 : proxy.size.height)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeOut(
                            duration: StockOrderEffectPeriodActionSheetLayout.cardTransitionDuration
                        ),
                    value: isCardsVisible
                )
            }
        }
        .onAppear(perform: present)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.effectPeriodActionSheet")
    }

    private var dismissalMask: some View {
        Button(action: dismiss) {
            Color.black
                .opacity(
                    isMaskVisible
                        ? StockOrderEffectPeriodActionSheetLayout.maskOpacity
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
                    duration: StockOrderEffectPeriodActionSheetLayout.maskFadeDuration
                ),
            value: isMaskVisible
        )
        .accessibilityLabel(language.text(.cancel))
        .accessibilityIdentifier("stockOrder.effectPeriodActionSheet.mask")
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            Text(language.text(.chooseEffectPeriod))
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
                    minHeight: StockOrderEffectPeriodActionSheetLayout.titleHeight,
                    maxHeight: StockOrderEffectPeriodActionSheetLayout.titleHeight
                )
                .overlay(alignment: .bottom) {
                    separator
                }
                .accessibilityIdentifier("stockOrder.effectPeriodActionSheet.title")

            ForEach(Array(StockOrderEffectPeriod.allCases.enumerated()), id: \.element.id) {
                index,
                effectPeriod in
                optionButton(effectPeriod)
                    .overlay(alignment: .bottom) {
                        if index < StockOrderEffectPeriod.allCases.count - 1 {
                            separator
                        }
                    }
            }
        }
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderEffectPeriodActionSheetLayout.cornerRadius,
                style: .continuous
            )
        )
    }

    private var cancelButton: some View {
        Button(action: dismiss) {
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
                    minHeight: StockOrderEffectPeriodActionSheetLayout.rowHeight,
                    maxHeight: StockOrderEffectPeriodActionSheetLayout.rowHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderEffectPeriodActionSheetLayout.cornerRadius,
                style: .continuous
            )
        )
        .accessibilityLabel(language.text(.cancel))
        .accessibilityIdentifier("stockOrder.effectPeriodActionSheet.cancel")
    }

    private var separator: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(height: StockOrderEffectPeriodActionSheetLayout.separatorHeight)
            .accessibilityHidden(true)
    }

    private func optionButton(_ effectPeriod: StockOrderEffectPeriod) -> some View {
        Button {
            select(effectPeriod)
        } label: {
            Text(language.text(effectPeriod.titleKey))
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
                    minHeight: StockOrderEffectPeriodActionSheetLayout.rowHeight,
                    maxHeight: StockOrderEffectPeriodActionSheetLayout.rowHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(language.text(effectPeriod.titleKey))
        .accessibilityIdentifier(
            "stockOrder.effectPeriodActionSheet.option.\(effectPeriod.rawValue)"
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

    private func select(_ effectPeriod: StockOrderEffectPeriod) {
        guard !isDismissing else { return }

        selection = effectPeriod
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
                + StockOrderEffectPeriodActionSheetLayout.cardTransitionDuration
        ) {
            onDismiss()
        }
    }
}

private enum StockOrderEffectPeriodActionSheetLayout {
    static let horizontalPadding: CGFloat = 16
    static let bottomPadding: CGFloat = 8
    static let sectionSpacing: CGFloat = 8
    static let titleHeight: CGFloat = 46
    static let rowHeight: CGFloat = 56
    static let separatorHeight: CGFloat = 0.5
    static let cornerRadius: CGFloat = 14
    static let maskOpacity: CGFloat = 0.3
    static let maskFadeDuration: TimeInterval = 0.3
    static let cardTransitionDuration: TimeInterval = 0.3
}

private struct StockOrderEffectPeriodActionSheetPreviewHarness: View {
    @State private var selection = StockOrderEffectPeriod.defaultSelection

    var body: some View {
        StockOrderEffectPeriodActionSheet(selection: $selection)
            .environment(\.demoLanguage, .simplifiedChinese)
    }
}

struct StockOrderEffectPeriodActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderEffectPeriodActionSheetPreviewHarness()
                .previewDisplayName("Simplified Chinese")

            StockOrderEffectPeriodActionSheet(
                selection: .constant(.untilCancelled)
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Dark")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
