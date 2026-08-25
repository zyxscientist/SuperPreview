//
//  StockOrderOrderTypeInput.swift
//  SuperPreview
//

import SwiftUI

/// An order type which can be supplied by the eventual stock-order page.
///
/// Market-specific availability belongs to the parent page. This component only
/// uses the supplied options to decide whether the type is selectable.
enum StockOrderOrderType: String, CaseIterable, Hashable, Identifiable {
    case limit
    case enhancedLimit
    case market
    case auctionLimit
    case auctionMarket
    case oddLot
    case conditional

    var id: String { rawValue }

    var titleKey: DemoCopyKey {
        switch self {
        case .limit:
            return .limitOrder
        case .enhancedLimit:
            return .enhancedLimitOrder
        case .market:
            return .marketOrder
        case .auctionLimit:
            return .auctionLimitOrder
        case .auctionMarket:
            return .auctionMarketOrder
        case .oddLot:
            return .oddLotOrder
        case .conditional:
            return .conditionalOrder
        }
    }
}

/// A reminder attached to an order type for a specific market or symbol.
enum StockOrderOrderTypeReminder {
    case marketOrder
    case custom(simplifiedChinese: String, traditionalChinese: String, english: String)

    func text(for language: DemoLanguage) -> String {
        switch self {
        case .marketOrder:
            return language.text(.marketOrderReminder)
        case let .custom(simplifiedChinese, traditionalChinese, english):
            switch language {
            case .simplifiedChinese:
                return simplifiedChinese
            case .traditionalChinese:
                return traditionalChinese
            case .english:
                return english
            }
        }
    }
}

/// A supported order type and its optional, type-specific reminder.
struct StockOrderOrderTypeOption: Identifiable {
    let orderType: StockOrderOrderType
    let reminder: StockOrderOrderTypeReminder?

    var id: String { orderType.rawValue }

    init(
        orderType: StockOrderOrderType,
        reminder: StockOrderOrderTypeReminder? = nil
    ) {
        self.orderType = orderType
        self.reminder = reminder
    }
}

/// Standard market-level option collections. The eventual stock-order page can
/// select one after a user chooses a symbol, or pass a symbol-specific override.
enum StockOrderOrderTypeOptions {
    static let hongKong: [StockOrderOrderTypeOption] = [
        StockOrderOrderTypeOption(orderType: .enhancedLimit),
        StockOrderOrderTypeOption(orderType: .limit),
        StockOrderOrderTypeOption(
            orderType: .market,
            reminder: .marketOrder
        ),
        StockOrderOrderTypeOption(orderType: .auctionLimit),
        StockOrderOrderTypeOption(orderType: .auctionMarket),
        StockOrderOrderTypeOption(orderType: .oddLot),
        StockOrderOrderTypeOption(orderType: .conditional)
    ]

    static let us: [StockOrderOrderTypeOption] = [
        StockOrderOrderTypeOption(orderType: .limit),
        StockOrderOrderTypeOption(
            orderType: .market,
            reminder: .marketOrder
        ),
        StockOrderOrderTypeOption(orderType: .conditional)
    ]

    static let aShare: [StockOrderOrderTypeOption] = [
        StockOrderOrderTypeOption(orderType: .limit),
        StockOrderOrderTypeOption(orderType: .conditional)
    ]

    /// A single option causes `StockOrderOrderTypeInput` to render plain text
    /// instead of the selectable field and chevron.
    static let crypto: [StockOrderOrderTypeOption] = [
        StockOrderOrderTypeOption(orderType: .limit)
    ]

    static func supportedOrderTypes(
        for market: StockOrderMarket
    ) -> [StockOrderOrderTypeOption] {
        switch market {
        case .hk:
            return hongKong
        case .us:
            return us
        case .china:
            return aShare
        case .crypto:
            return crypto
        }
    }
}

struct StockOrderOrderTypeInput: View {
    @Binding var selection: StockOrderOrderType

    let supportedOrderTypes: [StockOrderOrderTypeOption]
    let showsInfoButton: Bool
    let onSelectionRequested: () -> Void
    let onInfo: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOrderTypeActionSheetPresented = false
    @State private var isChevronPointingUp = false

    init(
        selection: Binding<StockOrderOrderType>,
        supportedOrderTypes: [StockOrderOrderTypeOption],
        showsInfoButton: Bool = false,
        onSelectionRequested: @escaping () -> Void = {},
        onInfo: @escaping () -> Void = {}
    ) {
        _selection = selection
        self.supportedOrderTypes = supportedOrderTypes
        self.showsInfoButton = showsInfoButton
        self.onSelectionRequested = onSelectionRequested
        self.onInfo = onInfo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                typeLabel

                if supportsSelection {
                    selectableValue
                } else {
                    unselectableValue
                }
            }
            .frame(height: StockOrderOrderTypeInputLayout.inputHeight)

            if let reminderText {
                reminder(reminderText)
            }
        }
        .padding(.horizontal, StockOrderOrderTypeInputLayout.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .fullScreenCover(isPresented: $isOrderTypeActionSheetPresented) {
            StockOrderOrderTypeActionSheet(
                selection: $selection,
                supportedOrderTypes: supportedOrderTypes,
                reduceMotion: reduceMotion,
                onWillDismiss: { isChevronPointingUp = false },
                onDismiss: dismissOrderTypeActionSheet
            )
            .environment(\.demoLanguage, language)
            .environment(\.colorScheme, colorScheme)
            .presentationBackground(.clear)
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.orderTypeInput")
    }

    private var supportsSelection: Bool {
        Set(supportedOrderTypes.map(\.orderType)).count > 1
    }

    private var selectedOption: StockOrderOrderTypeOption {
        supportedOrderTypes.first { $0.orderType == selection }
            ?? StockOrderOrderTypeOption(orderType: selection)
    }

    private var selectedTitle: String {
        language.text(selectedOption.orderType.titleKey)
    }

    private var reminderText: String? {
        selectedOption.reminder?.text(for: language)
    }

    private var typeLabel: some View {
        HStack(spacing: StockOrderOrderTypeInputLayout.labelIconSpacing) {
            Text(language.text(.orderType))
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)

            if showsInfoButton {
                Button(action: onInfo) {
                    Image("stock_order_type_info")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockOrderOrderTypeInputLayout.infoIconSize,
                            height: StockOrderOrderTypeInputLayout.infoIconSize
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .accessibilityLabel(language.text(.orderTypeInformation))
                .accessibilityIdentifier("stockOrder.orderTypeInput.info")
            }
        }
        .frame(
            width: StockOrderOrderTypeInputLayout.labelWidth,
            height: StockOrderOrderTypeInputLayout.inputHeight,
            alignment: .leading
        )
        .accessibilityIdentifier("stockOrder.orderTypeInput.label")
    }

    private var selectableValue: some View {
        Button(action: presentOrderTypeActionSheet) {
            HStack(spacing: 0) {
                Text(selectedTitle)
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, StockOrderOrderTypeInputLayout.valueLeadingPadding)

                ZStack {
                    RoundedRectangle(
                        cornerRadius: StockOrderOrderTypeInputLayout.arrowButtonCornerRadius,
                        style: .continuous
                    )
                    .fill(Color("color-base-1"))

                    Image("stock_order_type_chevron_down")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockOrderOrderTypeInputLayout.arrowGlyphSize,
                            height: StockOrderOrderTypeInputLayout.arrowGlyphSize
                        )
                        .rotationEffect(.degrees(isChevronPointingUp ? 180 : 0))
                }
                .frame(
                    width: StockOrderOrderTypeInputLayout.arrowButtonSize,
                    height: StockOrderOrderTypeInputLayout.arrowButtonSize
                )
                .padding(.trailing, StockOrderOrderTypeInputLayout.arrowTrailingPadding)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: StockOrderOrderTypeInputLayout.inputHeight,
                maxHeight: StockOrderOrderTypeInputLayout.inputHeight,
                alignment: .leading
            )
            .background(Color("color-scale-2"))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: StockOrderOrderTypeInputLayout.inputCornerRadius,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(language.text(.orderType)): \(selectedTitle)")
        .accessibilityHint(language.text(.selectOrderType))
        .accessibilityIdentifier("stockOrder.orderTypeInput.selection")
    }

    private var unselectableValue: some View {
        Text(selectedTitle)
            .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
            .foregroundColor(Color("color-text-30"))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("\(language.text(.orderType)): \(selectedTitle)")
            .accessibilityIdentifier("stockOrder.orderTypeInput.value")
    }

    private func reminder(_ text: String) -> some View {
        Text(text)
            .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
            .foregroundColor(Color("color-text-90"))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, StockOrderOrderTypeInputLayout.reminderVerticalPadding)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(text)
            .accessibilityIdentifier("stockOrder.orderTypeInput.reminder")
    }

    private func presentOrderTypeActionSheet() {
        onSelectionRequested()
        updateOrderTypeActionSheetPresentation(true)
        isChevronPointingUp = true
    }

    private func dismissOrderTypeActionSheet() {
        updateOrderTypeActionSheetPresentation(false)
    }

    /// The full-screen cover itself is made visible immediately. The contained
    /// action sheet owns the visible animation: its mask fades in place while
    /// its cards move upward from the bottom edge.
    private func updateOrderTypeActionSheetPresentation(_ isPresented: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            isOrderTypeActionSheetPresented = isPresented
        }
    }
}

private enum StockOrderOrderTypeInputLayout {
    static let horizontalPadding: CGFloat = 16
    static let labelWidth: CGFloat = 112
    static let labelIconSpacing: CGFloat = 4
    static let inputHeight: CGFloat = 44
    static let inputCornerRadius: CGFloat = 10
    static let valueLeadingPadding: CGFloat = 12
    static let arrowButtonSize: CGFloat = 32
    static let arrowButtonCornerRadius: CGFloat = 6
    static let arrowGlyphSize: CGFloat = 30
    static let arrowTrailingPadding: CGFloat = 6
    static let infoIconSize: CGFloat = 16
    static let reminderVerticalPadding: CGFloat = 8
}

private enum StockOrderOrderTypePreviewData {
    static let selectableOptions = StockOrderOrderTypeOptions.hongKong
}

struct StockOrderOrderTypeInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderOrderTypeInput(
                selection: .constant(.enhancedLimit),
                supportedOrderTypes: StockOrderOrderTypePreviewData.selectableOptions
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("Simplified Chinese · Selectable")

            StockOrderOrderTypeInput(
                selection: .constant(.market),
                supportedOrderTypes: StockOrderOrderTypeOptions.us
            )
            .environment(\.demoLanguage, .traditionalChinese)
            .preferredColorScheme(.dark)
            .previewDisplayName("Traditional Chinese · US Market Reminder")

            StockOrderOrderTypeInput(
                selection: .constant(.limit),
                supportedOrderTypes: StockOrderOrderTypeOptions.crypto
            )
            .environment(\.demoLanguage, .english)
            .previewDisplayName("English · Crypto · Unselectable")

            StockOrderOrderTypeInput(
                selection: .constant(.conditional),
                supportedOrderTypes: StockOrderOrderTypeOptions.aShare
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("Simplified Chinese · A-share")

        }
        .previewLayout(.fixed(width: 402, height: 120))
    }
}
