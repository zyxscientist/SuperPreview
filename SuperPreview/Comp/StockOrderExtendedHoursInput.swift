//
//  StockOrderExtendedHoursInput.swift
//  SuperPreview
//

import SwiftUI

/// Whether a U.S. equity order can trade during pre-market and after-hours.
///
/// The parent order page should only render `StockOrderExtendedHoursInput` for
/// `StockOrderMarket.us`; this component deliberately remains market-agnostic.
enum StockOrderExtendedHours: String, CaseIterable, Hashable, Identifiable {
    case allowed
    case notAllowed

    static let defaultSelection: Self = .allowed

    var id: String { rawValue }

    var titleKey: DemoCopyKey {
        switch self {
        case .allowed: .extendedHoursAllowed
        case .notAllowed: .extendedHoursNotAllowed
        }
    }
}

/// The U.S.-stock extended-hours selector used by the stock-order demo.
struct StockOrderExtendedHoursInput: View {
    @Binding var selection: StockOrderExtendedHours

    let showsInfoButton: Bool
    let onSelectionRequested: () -> Void
    let onInfo: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isActionSheetPresented = false
    @State private var isChevronPointingUp = false

    init(
        selection: Binding<StockOrderExtendedHours>,
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
            extendedHoursLabel
            selectableValue
        }
        .padding(.horizontal, StockOrderExtendedHoursInputLayout.horizontalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderExtendedHoursInputLayout.inputHeight,
            maxHeight: StockOrderExtendedHoursInputLayout.inputHeight,
            alignment: .leading
        )
        .background(Color("color-base-1"))
        .fullScreenCover(isPresented: $isActionSheetPresented) {
            StockOrderExtendedHoursActionSheet(
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
        .accessibilityIdentifier("stockOrder.extendedHoursInput")
    }

    private var selectedTitle: String {
        language.text(selection.titleKey)
    }

    private var extendedHoursLabel: some View {
        HStack(spacing: StockOrderExtendedHoursInputLayout.labelIconSpacing) {
            Text(language.text(.extendedHours))
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)

            if showsInfoButton {
                Button(action: onInfo) {
                    Image("stock_order_type_info")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockOrderExtendedHoursInputLayout.infoIconSize,
                            height: StockOrderExtendedHoursInputLayout.infoIconSize
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .accessibilityLabel(language.text(.extendedHoursInformation))
                .accessibilityIdentifier("stockOrder.extendedHoursInput.info")
            }
        }
        .frame(
            width: StockOrderExtendedHoursInputLayout.labelWidth,
            height: StockOrderExtendedHoursInputLayout.inputHeight,
            alignment: .leading
        )
        .accessibilityIdentifier("stockOrder.extendedHoursInput.label")
    }

    private var selectableValue: some View {
        Button(action: presentActionSheet) {
            HStack(spacing: 0) {
                Text(selectedTitle)
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, StockOrderExtendedHoursInputLayout.valueLeadingPadding)

                ZStack {
                    RoundedRectangle(
                        cornerRadius: StockOrderExtendedHoursInputLayout.arrowButtonCornerRadius,
                        style: .continuous
                    )
                    .fill(Color("color-base-1"))

                    Image("stock_order_type_chevron_down")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockOrderExtendedHoursInputLayout.arrowGlyphSize,
                            height: StockOrderExtendedHoursInputLayout.arrowGlyphSize
                        )
                        .rotationEffect(.degrees(isChevronPointingUp ? 180 : 0))
                }
                .frame(
                    width: StockOrderExtendedHoursInputLayout.arrowButtonSize,
                    height: StockOrderExtendedHoursInputLayout.arrowButtonSize
                )
                .padding(.trailing, StockOrderExtendedHoursInputLayout.arrowTrailingPadding)
            }
            .frame(
                width: StockOrderExtendedHoursInputLayout.valueWidth,
                height: StockOrderExtendedHoursInputLayout.inputHeight,
                alignment: .leading
            )
            .background(Color("color-scale-2"))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: StockOrderExtendedHoursInputLayout.inputCornerRadius,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(language.text(.extendedHours)): \(selectedTitle)")
        .accessibilityHint(language.text(.selectExtendedHours))
        .accessibilityIdentifier("stockOrder.extendedHoursInput.selection")
    }

    private func presentActionSheet() {
        onSelectionRequested()
        updateActionSheetPresentation(true)
        isChevronPointingUp = true
    }

    private func dismissActionSheet() {
        updateActionSheetPresentation(false)
    }

    /// The cover is immediate; the sheet owns the mask fade and card motion.
    private func updateActionSheetPresentation(_ isPresented: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            isActionSheetPresented = isPresented
        }
    }
}

private enum StockOrderExtendedHoursInputLayout {
    static let horizontalPadding: CGFloat = 16
    static let labelWidth: CGFloat = 112
    static let labelIconSpacing: CGFloat = 4
    static let inputHeight: CGFloat = 44
    static let inputCornerRadius: CGFloat = 10
    static let valueWidth: CGFloat = 258
    static let valueLeadingPadding: CGFloat = 12
    static let arrowButtonSize: CGFloat = 32
    static let arrowButtonCornerRadius: CGFloat = 6
    static let arrowGlyphSize: CGFloat = 30
    static let arrowTrailingPadding: CGFloat = 6
    static let infoIconSize: CGFloat = 16
}

private struct StockOrderExtendedHoursInputPreviewHarness: View {
    @State private var selection = StockOrderExtendedHours.defaultSelection

    var body: some View {
        StockOrderExtendedHoursInput(selection: $selection)
    }
}

struct StockOrderExtendedHoursInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderExtendedHoursInputPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese · Allowed")

            StockOrderExtendedHoursInput(selection: .constant(.notAllowed))
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("English · Not Allowed")
        }
        .previewLayout(.fixed(width: 402, height: 44))
    }
}
