//
//  StockOrderPriceInput.swift
//  SuperPreview
//

import SwiftUI

/// The currently editable field on the assembled stock-order page.
///
/// Individual input components retain their local `FocusState`, while this
/// small shared value lets the page dismiss the keyboard consistently when a
/// user moves on to another interaction.
enum StockOrderFormInputFocus: Hashable {
    case price
    case quantity
}

/// The price field used by the stock-order demo.
///
/// The parent owns price-tick validation and the resulting price. This view
/// only accepts decimal keypad input, sanitizes it to a single decimal point,
/// and forwards nudge requests to the parent.
struct StockOrderPriceInput: View {
    @Binding var price: String
    @Binding var priceTarget: StockOrderPriceTarget
    @Binding var focusedInput: StockOrderFormInputFocus?
    @Binding var isTargetMenuPresented: Bool

    /// The selected symbol's current price. A value enables the input-deviation bubble.
    let currentPrice: Decimal?
    /// Percentage points required before the input-deviation bubble is shown.
    let minimumDeviationPercent: Decimal
    /// Price targets available for the selected symbol and its quote entitlement.
    let supportedPriceTargets: [StockOrderPriceTarget]
    let showsTargetButton: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isPriceFieldFocused: Bool

    init(
        price: Binding<String>,
        priceTarget: Binding<StockOrderPriceTarget>,
        focusedInput: Binding<StockOrderFormInputFocus?> = .constant(nil),
        isTargetMenuPresented: Binding<Bool> = .constant(false),
        currentPrice: Decimal? = nil,
        minimumDeviationPercent: Decimal = 0.01,
        supportedPriceTargets: [StockOrderPriceTarget] = StockOrderPriceTargetOptions.advancedQuote,
        showsTargetButton: Bool = true,
        onDecrease: @escaping () -> Void = {},
        onIncrease: @escaping () -> Void = {}
    ) {
        _price = price
        _priceTarget = priceTarget
        _focusedInput = focusedInput
        _isTargetMenuPresented = isTargetMenuPresented
        self.currentPrice = currentPrice
        self.minimumDeviationPercent = minimumDeviationPercent
        self.supportedPriceTargets = supportedPriceTargets
        self.showsTargetButton = showsTargetButton
        self.onDecrease = onDecrease
        self.onIncrease = onIncrease
    }

    var body: some View {
        HStack(spacing: 0) {
            priceLabel

            priceControl
        }
        .padding(.horizontal, StockOrderPriceInputLayout.horizontalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderPriceInputLayout.controlHeight,
            maxHeight: StockOrderPriceInputLayout.controlHeight,
            alignment: .leading
        )
        .background(Color("color-base-1"))
        .overlay(alignment: .topLeading) {
            if let priceDeviation {
                StockOrderPriceDeviationBubble(
                    text: priceDeviation.localizedText(for: language)
                )
                .offset(
                    x: StockOrderPriceInputLayout.deviationBubbleLeadingOffset,
                    y: StockOrderPriceInputLayout.deviationBubbleTopOffset
                )
                .allowsHitTesting(false)
                .accessibilityLabel(priceDeviation.localizedText(for: language))
                .accessibilityIdentifier("stockOrder.priceInput.deviationBubble")
            }
        }
        .overlay(alignment: .topLeading) {
            if isTargetMenuPresented {
                StockOrderPriceTargetMenu(
                    selection: $priceTarget,
                    supportedTargets: supportedPriceTargets,
                    onSelection: { _ in
                        isTargetMenuPresented = false
                    }
                )
                .offset(
                    x: StockOrderPriceInputLayout.targetMenuLeadingOffset,
                    y: StockOrderPriceInputLayout.targetMenuTopOffset
                )
                .zIndex(1)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.priceInput")
        .zIndex(isTargetMenuPresented ? 1 : 0)
        .onChange(of: price) { _, newValue in
            let sanitizedPrice = sanitized(newValue)

            if sanitizedPrice != newValue {
                price = sanitizedPrice
            }
        }
        .onChange(of: focusedInput) { _, focusedInput in
            guard focusedInput != .price else { return }
            isPriceFieldFocused = false
            if focusedInput != nil {
                isTargetMenuPresented = false
            }
        }
        .onChange(of: isPriceFieldFocused) { _, isFocused in
            if isFocused {
                isTargetMenuPresented = false
                focusedInput = .price
            } else if focusedInput == .price {
                focusedInput = nil
            }
        }
        .onDisappear {
            if focusedInput == .price {
                focusedInput = nil
            }
        }
    }

    private var priceControl: some View {
        HStack(spacing: StockOrderPriceInputLayout.targetButtonSpacing) {
            priceField

            if showsTargetButton {
                targetButton
            }
        }
        .frame(
            width: StockOrderPriceInputLayout.valueWidth,
            height: StockOrderPriceInputLayout.controlHeight,
            alignment: .trailing
        )
    }

    private var priceLabel: some View {
        Text(language.text(priceTarget.priceLabelKey))
            .modifier(
                CustomFontModifier(
                    size: 16,
                    font: .regular,
                    lineHeight: 24
                )
            )
            .foregroundColor(
                priceTarget.isSpecifiedPrice
                    ? Color("color-text-30")
                    : Color("color-brand-blue")
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(
                width: StockOrderPriceInputLayout.labelWidth,
                height: StockOrderPriceInputLayout.controlHeight,
                alignment: .leading
            )
            .accessibilityIdentifier("stockOrder.priceInput.label")
    }

    private var priceField: some View {
        HStack(spacing: 0) {
            nudgeButton(
                assetName: "stock_order_price_decrease_sign",
                accessibilityLabel: language.text(.decreasePrice),
                identifier: "stockOrder.priceInput.decrease",
                action: decrease
            )
            .padding(.leading, StockOrderPriceInputLayout.nudgeHorizontalInset)

            ZStack(alignment: .leading) {
                if price.isEmpty {
                    Text(language.text(.enterPrice))
                        .modifier(
                            CustomFontModifier(
                                size: 16,
                                font: .regular,
                                lineHeight: 24
                            )
                        )
                        .foregroundColor(Color("color-text-90"))
                        .lineLimit(1)
                        .allowsHitTesting(false)
                }

                TextField("", text: $price)
                    .modifier(
                        CustomFontModifier(
                            size: 16,
                            font: .medium,
                            lineHeight: 24
                        )
                    )
                    .foregroundColor(Color("color-text-30"))
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($isPriceFieldFocused)
                    .accessibilityLabel(language.text(.price))
                    .accessibilityValue(
                        price.isEmpty
                            ? language.text(.enterPrice)
                            : price
                    )
                    .accessibilityIdentifier("stockOrder.priceInput.field")
            }
            .frame(
                width: textFieldWidth,
                height: StockOrderPriceInputLayout.controlHeight,
                alignment: .leading
            )
            .padding(.leading, StockOrderPriceInputLayout.textFieldLeadingInset)

            nudgeButton(
                assetName: "stock_order_price_increase_sign",
                accessibilityLabel: language.text(.increasePrice),
                identifier: "stockOrder.priceInput.increase",
                action: increase
            )
            .padding(.trailing, StockOrderPriceInputLayout.nudgeHorizontalInset)
        }
        .frame(
            width: priceFieldWidth,
            height: StockOrderPriceInputLayout.controlHeight
        )
        .background(Color("color-scale-2"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderPriceInputLayout.fieldCornerRadius,
                style: .continuous
            )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.priceInput.value")
    }

    private var targetButton: some View {
        Button(action: toggleTargetMenu) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: StockOrderPriceInputLayout.fieldCornerRadius,
                    style: .continuous
                )
                .fill(Color("color-scale-2"))

                targetGlyph
            }
            .frame(
                width: StockOrderPriceInputLayout.targetButtonSize,
                height: StockOrderPriceInputLayout.targetButtonSize
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(language.text(.priceTracking))
        .accessibilityValue(language.text(priceTarget.menuTitleKey))
        .accessibilityIdentifier("stockOrder.priceInput.target")
    }

    private var targetGlyph: some View {
        Image(
            isTargetButtonActive
                ? "stock_order_price_target_active"
                : "stock_order_price_target_inactive"
        )
        .resizable()
        .scaledToFit()
        .frame(
            width: StockOrderPriceInputLayout.targetButtonGlyphSize,
            height: StockOrderPriceInputLayout.targetButtonGlyphSize
        )
        .accessibilityHidden(true)
    }

    private var isTargetButtonActive: Bool {
        !priceTarget.isSpecifiedPrice
    }

    private var priceFieldWidth: CGFloat {
        showsTargetButton
            ? StockOrderPriceInputLayout.fieldWidthWithTargetButton
            : StockOrderPriceInputLayout.valueWidth
    }

    private var textFieldWidth: CGFloat {
        showsTargetButton
            ? StockOrderPriceInputLayout.textFieldWidthWithTargetButton
            : StockOrderPriceInputLayout.textFieldWidthWithoutTargetButton
    }

    private var priceDeviation: StockOrderPriceDeviation? {
        guard isPriceFieldFocused,
              let currentPrice,
              currentPrice > .zero,
              let enteredPrice = Decimal(
                string: price,
                locale: StockOrderPriceInputLayout.priceLocale
              )
        else {
            return nil
        }

        let deviationPercent = (enteredPrice / currentPrice - 1) * 100
        let absoluteDeviationPercent = deviationPercent < .zero
            ? -deviationPercent
            : deviationPercent

        guard absoluteDeviationPercent >= max(minimumDeviationPercent, .zero),
              absoluteDeviationPercent > .zero
        else {
            return nil
        }

        return StockOrderPriceDeviation(
            direction: deviationPercent > .zero ? .above : .below,
            percentage: absoluteDeviationPercent
        )
    }

    private func nudgeButton(
        assetName: String,
        accessibilityLabel: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: StockOrderPriceInputLayout.nudgeCornerRadius,
                    style: .continuous
                )
                .fill(Color("color-base-1"))

                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: StockOrderPriceInputLayout.nudgeGlyphSize,
                        height: StockOrderPriceInputLayout.nudgeGlyphSize
                    )
            }
            .frame(
                width: StockOrderPriceInputLayout.nudgeSize,
                height: StockOrderPriceInputLayout.nudgeSize
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(
            StockOrderNudgePressStyle(reduceMotion: reduceMotion)
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }

    private func decrease() {
        nudgePrice(onDecrease)
    }

    private func increase() {
        nudgePrice(onIncrease)
    }

    private func nudgePrice(_ action: () -> Void) {
        isTargetMenuPresented = false
        let shouldRestoreFocus = isPriceFieldFocused

        if !shouldRestoreFocus {
            dismissActiveInput()
        }

        action()
        HapticManager.instance.impactHaptic(type: .medium)

        guard shouldRestoreFocus else { return }

        isPriceFieldFocused = true
        DispatchQueue.main.async {
            isPriceFieldFocused = true
        }
    }

    private func toggleTargetMenu() {
        guard supportedPriceTargets.count > 1 else { return }

        dismissActiveInput()
        HapticManager.instance.impactHaptic(type: .medium)
        isTargetMenuPresented.toggle()
    }

    private func dismissActiveInput() {
        isPriceFieldFocused = false
        focusedInput = nil
    }

    private func sanitized(_ value: String) -> String {
        let allowedCharacters = value.filter { "0123456789.".contains($0) }

        guard let decimalIndex = allowedCharacters.firstIndex(of: ".") else {
            return allowedCharacters
        }

        let wholePart = String(allowedCharacters[..<decimalIndex])
        let fractionalPart = String(
            allowedCharacters[allowedCharacters.index(after: decimalIndex)...]
        )
        .replacingOccurrences(of: ".", with: "")

        return "\(wholePart.isEmpty ? "0" : wholePart).\(fractionalPart)"
    }
}

private enum StockOrderPriceInputLayout {
    static let priceLocale = Locale(identifier: "en_US_POSIX")
    static let horizontalPadding: CGFloat = 16
    static let labelWidth: CGFloat = 112
    static let valueWidth: CGFloat = 258
    static let controlHeight: CGFloat = 44
    static let fieldWidthWithTargetButton: CGFloat = 208
    static let fieldCornerRadius: CGFloat = 10
    static let targetButtonSpacing: CGFloat = 6
    static let targetButtonSize: CGFloat = 44
    static let targetButtonGlyphSize: CGFloat = 30
    static let targetMenuLeadingOffset: CGFloat = 290
    static let targetMenuTopOffset: CGFloat = 36
    static let deviationBubbleLeadingOffset: CGFloat = 178
    static let deviationBubbleTopOffset: CGFloat = -20
    static let nudgeHorizontalInset: CGFloat = 6
    static let nudgeSize: CGFloat = 32
    static let nudgeGlyphSize: CGFloat = 30
    static let nudgeCornerRadius: CGFloat = 6
    static let textFieldLeadingInset: CGFloat = 12
    static let textFieldWidthWithTargetButton: CGFloat = 120
    static let textFieldWidthWithoutTargetButton: CGFloat = 170
}

private struct StockOrderPriceDeviation {
    enum Direction {
        case above
        case below
    }

    let direction: Direction
    let percentage: Decimal

    func localizedText(for language: DemoLanguage) -> String {
        let copyKey: DemoCopyKey = switch direction {
        case .above:
            .priceAboveCurrentPrice
        case .below:
            .priceBelowCurrentPrice
        }

        return String(
            format: language.text(copyKey),
            "\(formattedPercentage)%"
        )
    }

    private var formattedPercentage: String {
        let formatter = NumberFormatter()
        formatter.locale = StockOrderPriceInputLayout.priceLocale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSDecimalNumber(decimal: percentage))
            ?? NSDecimalNumber(decimal: percentage).stringValue
    }
}

private struct StockOrderPriceDeviationBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .modifier(
                CustomFontModifier(
                    size: 10,
                    font: .regular,
                    lineHeight: 12
                )
            )
            .foregroundColor(Color("color-brand-blue"))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(Color("color-brand-blue").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Image("stock_order_price_deviation_bubble_pointer")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 7.794, height: 2.738)
                    .offset(x: 9.6, y: 2.738)
                    .accessibilityHidden(true)
            }
    }
}

/// Matches the press/release scale of the new Watchlist action buttons.
///
/// Both price and quantity steppers use this style so their feedback remains
/// visually consistent while the parent page owns the actual increment logic.
struct StockOrderNudgePressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        StockOrderNudgePressButton(
            configuration: configuration,
            reduceMotion: reduceMotion
        )
    }
}

private struct StockOrderNudgePressButton: View {
    let configuration: ButtonStyle.Configuration
    let reduceMotion: Bool

    @State private var isHoldingFeedback = false
    @State private var releaseWorkItem: DispatchWorkItem?

    private var isScaled: Bool {
        configuration.isPressed || isHoldingFeedback
    }

    var body: some View {
        configuration.label
            .scaleEffect(reduceMotion || !isScaled ? 1 : 0.96)
            .animation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: isScaled ? 0.06 : 0.12),
                value: isScaled
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    releaseWorkItem?.cancel()
                    isHoldingFeedback = true
                } else {
                    let workItem = DispatchWorkItem {
                        isHoldingFeedback = false
                    }
                    releaseWorkItem = workItem
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.12,
                        execute: workItem
                    )
                }
            }
    }
}

private struct StockOrderPriceInputPreviewHarness: View {
    @State private var price = "233.610"
    @State private var priceTarget: StockOrderPriceTarget = .specifiedPrice
    @State private var isTargetMenuPresented = false

    var body: some View {
        StockOrderPriceInput(
            price: $price,
            priceTarget: $priceTarget,
            isTargetMenuPresented: $isTargetMenuPresented,
            currentPrice: Decimal(string: "231.576", locale: StockOrderPriceInputLayout.priceLocale),
            onDecrease: { updatePrice(by: -0.010) },
            onIncrease: { updatePrice(by: 0.010) }
        )
    }

    private func updatePrice(by increment: Decimal) {
        let locale = Locale(identifier: "en_US_POSIX")
        let currentPrice = Decimal(string: price, locale: locale) ?? 0
        let updatedPrice = max(0, currentPrice + increment)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        formatter.numberStyle = .decimal

        price = formatter.string(from: NSDecimalNumber(decimal: updatedPrice)) ?? price
    }
}

struct StockOrderPriceInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderPriceInput(
                price: .constant(""),
                priceTarget: .constant(.specifiedPrice)
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("Simplified Chinese · Empty")

            StockOrderPriceInputPreviewHarness()
                .environment(\.demoLanguage, .traditionalChinese)
            .previewDisplayName("Traditional Chinese · Interactive")

            StockOrderPriceInput(
                price: .constant("233.610"),
                priceTarget: .constant(.marketPrice),
                showsTargetButton: false
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · No Target Button · Dark")
        }
        .previewLayout(.fixed(width: 402, height: 44))
    }
}
