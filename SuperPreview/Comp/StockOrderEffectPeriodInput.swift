//
//  StockOrderEffectPeriodInput.swift
//  SuperPreview
//

import SwiftUI

/// The time in force applied to a stock order.
///
/// The eventual order page owns the selected value. New order forms should
/// initialize this binding with `StockOrderEffectPeriod.defaultSelection`.
enum StockOrderEffectPeriod: String, CaseIterable, Hashable, Identifiable {
    case day
    case untilCancelled

    static let defaultSelection: Self = .day

    var id: String { rawValue }

    var titleKey: DemoCopyKey {
        switch self {
        case .day:
            .dayValid
        case .untilCancelled:
            .goodTillCancelled
        }
    }
}

/// The time-in-force selector used by the stock-order demo.
struct StockOrderEffectPeriodInput: View {
    @Binding var selection: StockOrderEffectPeriod

    let showsInfoButton: Bool
    let onSelectionRequested: () -> Void
    let onInfo: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isActionSheetPresented = false
    @State private var isChevronPointingUp = false

    init(
        selection: Binding<StockOrderEffectPeriod>,
        showsInfoButton: Bool = false,
        onSelectionRequested: @escaping () -> Void = {},
        onInfo: @escaping () -> Void = {}
    ) {
        _selection = selection
        self.showsInfoButton = showsInfoButton
        self.onSelectionRequested = onSelectionRequested
        self.onInfo = onInfo
    }

    var body: some View {
        HStack(spacing: 0) {
            periodLabel
            selectableValue
        }
        .padding(.horizontal, StockOrderEffectPeriodInputLayout.horizontalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderEffectPeriodInputLayout.inputHeight,
            maxHeight: StockOrderEffectPeriodInputLayout.inputHeight,
            alignment: .leading
        )
        .background(Color("color-base-1"))
        .fullScreenCover(isPresented: $isActionSheetPresented) {
            StockOrderEffectPeriodActionSheet(
                selection: $selection,
                reduceMotion: reduceMotion,
                onWillDismiss: { isChevronPointingUp = false },
                onDismiss: dismissActionSheet
            )
            .environment(\.demoLanguage, language)
            .environment(\.colorScheme, colorScheme)
            .presentationBackground(.clear)
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.effectPeriodInput")
    }

    private var selectedTitle: String {
        language.text(selection.titleKey)
    }

    private var periodLabel: some View {
        HStack(spacing: StockOrderEffectPeriodInputLayout.labelIconSpacing) {
            Text(language.text(.effectPeriod))
                .modifier(
                    CustomFontModifier(
                        size: 16,
                        font: .regular,
                        lineHeight: 24
                    )
                )
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)

            if showsInfoButton {
                Button(action: onInfo) {
                    Image("stock_order_type_info")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockOrderEffectPeriodInputLayout.infoIconSize,
                            height: StockOrderEffectPeriodInputLayout.infoIconSize
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .accessibilityLabel(language.text(.effectPeriodInformation))
                .accessibilityIdentifier("stockOrder.effectPeriodInput.info")
            }
        }
        .frame(
            width: StockOrderEffectPeriodInputLayout.labelWidth,
            height: StockOrderEffectPeriodInputLayout.inputHeight,
            alignment: .leading
        )
        .accessibilityIdentifier("stockOrder.effectPeriodInput.label")
    }

    private var selectableValue: some View {
        Button(action: presentActionSheet) {
            HStack(spacing: 0) {
                Text(selectedTitle)
                    .modifier(
                        CustomFontModifier(
                            size: 16,
                            font: .medium,
                            lineHeight: 24
                        )
                    )
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(
                        .leading,
                        StockOrderEffectPeriodInputLayout.valueLeadingPadding
                    )

                ZStack {
                    RoundedRectangle(
                        cornerRadius: StockOrderEffectPeriodInputLayout.arrowButtonCornerRadius,
                        style: .continuous
                    )
                    .fill(Color("color-base-1"))

                    Image("stock_order_type_chevron_down")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockOrderEffectPeriodInputLayout.arrowGlyphSize,
                            height: StockOrderEffectPeriodInputLayout.arrowGlyphSize
                        )
                        .rotationEffect(.degrees(isChevronPointingUp ? 180 : 0))
                }
                .frame(
                    width: StockOrderEffectPeriodInputLayout.arrowButtonSize,
                    height: StockOrderEffectPeriodInputLayout.arrowButtonSize
                )
                .padding(
                    .trailing,
                    StockOrderEffectPeriodInputLayout.arrowTrailingPadding
                )
            }
            .frame(
                width: StockOrderEffectPeriodInputLayout.valueWidth,
                height: StockOrderEffectPeriodInputLayout.inputHeight,
                alignment: .leading
            )
            .background(Color("color-scale-2"))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: StockOrderEffectPeriodInputLayout.inputCornerRadius,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(language.text(.effectPeriod)): \(selectedTitle)")
        .accessibilityHint(language.text(.selectEffectPeriod))
        .accessibilityIdentifier("stockOrder.effectPeriodInput.selection")
    }

    private func presentActionSheet() {
        onSelectionRequested()
        updateActionSheetPresentation(true)
        isChevronPointingUp = true
    }

    private func dismissActionSheet() {
        updateActionSheetPresentation(false)
    }

    /// The cover is presented without a system transition; its sheet supplies
    /// the same in-place mask fade and bottom-up card motion as order type.
    private func updateActionSheetPresentation(_ isPresented: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            isActionSheetPresented = isPresented
        }
    }
}

private enum StockOrderEffectPeriodInputLayout {
    static let horizontalPadding: CGFloat = 16
    static let labelWidth: CGFloat = 112
    static let valueWidth: CGFloat = 258
    static let labelIconSpacing: CGFloat = 4
    static let inputHeight: CGFloat = 44
    static let inputCornerRadius: CGFloat = 10
    static let valueLeadingPadding: CGFloat = 12
    static let arrowButtonSize: CGFloat = 32
    static let arrowButtonCornerRadius: CGFloat = 6
    static let arrowGlyphSize: CGFloat = 30
    static let arrowTrailingPadding: CGFloat = 6
    static let infoIconSize: CGFloat = 16
}

private struct StockOrderEffectPeriodInputPreviewHarness: View {
    @State private var selection = StockOrderEffectPeriod.defaultSelection

    var body: some View {
        StockOrderEffectPeriodInput(selection: $selection)
    }
}

struct StockOrderEffectPeriodInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderEffectPeriodInputPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese · Day")

            StockOrderEffectPeriodInput(
                selection: .constant(.untilCancelled),
                showsInfoButton: true
            )
            .environment(\.demoLanguage, .traditionalChinese)
            .preferredColorScheme(.dark)
            .previewDisplayName("Traditional Chinese · Good Till Cancelled")

            StockOrderEffectPeriodInput(
                selection: .constant(.day)
            )
            .environment(\.demoLanguage, .english)
            .previewDisplayName("English · Day")
        }
        .previewLayout(.fixed(width: 402, height: 44))
    }
}
