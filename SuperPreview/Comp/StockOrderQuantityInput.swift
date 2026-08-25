//
//  StockOrderQuantityInput.swift
//  SuperPreview
//

import SwiftUI

/// A selectable quantity shown in the stock-order quick-input panel.
///
/// `displayQuantity` is the localized/formatted value shown in the panel,
/// while `inputValue` is written to the order form when the option is chosen.
struct StockOrderQuantityQuickInputItem: Identifiable, Hashable {
    let id: String
    let fractionLabel: String
    let displayQuantity: String
    let inputValue: String

    init(
        id: String? = nil,
        fractionLabel: String,
        displayQuantity: String,
        inputValue: String
    ) {
        self.id = id ?? "\(fractionLabel)-\(inputValue)"
        self.fractionLabel = fractionLabel
        self.displayQuantity = displayQuantity
        self.inputValue = inputValue
    }
}

/// The semantic side of a quick-input amount column.
enum StockOrderQuantityQuickInputTone: String, Hashable {
    case buy
    case sell

    fileprivate var color: Color {
        switch self {
        case .buy:
            Color("color-utility3-red")
        case .sell:
            Color("color-utility3-green")
        }
    }
}

/// Controls the keypad and validation used by the quantity field.
///
/// Stock markets use whole-share quantities. Virtual assets can use a decimal
/// quantity, while the parent still owns the actual lot-size arithmetic.
enum StockOrderQuantityInputMode: Hashable {
    case wholeNumber
    case decimal(maxFractionDigits: Int, placeholder: String?)

    var placeholder: String? {
        switch self {
        case .wholeNumber:
            return nil
        case let .decimal(_, placeholder):
            return placeholder
        }
    }

    var maxFractionDigits: Int? {
        switch self {
        case .wholeNumber:
            return nil
        case let .decimal(maxFractionDigits, _):
            return max(0, maxFractionDigits)
        }
    }
}

/// One column in the quantity quick-input tool.
///
/// The parent order page supplies the market- and side-specific values; this
/// component only renders them and writes the selected `inputValue`.
struct StockOrderQuantityQuickInputColumn: Identifiable, Hashable {
    let id: String
    let title: String
    let tone: StockOrderQuantityQuickInputTone
    let options: [StockOrderQuantityQuickInputItem]

    init(
        id: String,
        title: String,
        tone: StockOrderQuantityQuickInputTone,
        options: [StockOrderQuantityQuickInputItem]
    ) {
        self.id = id
        self.title = title
        self.tone = tone
        self.options = options
    }

    static func demoColumns(for language: DemoLanguage) -> [Self] {
        let cashAmounts: [StockOrderQuantityQuickInputItem] = [
            .init(fractionLabel: language.text(.fullPosition), displayQuantity: "24,000", inputValue: "24000"),
            .init(fractionLabel: "1/2", displayQuantity: "12,000", inputValue: "12000"),
            .init(fractionLabel: "1/3", displayQuantity: "8,000", inputValue: "8000"),
            .init(fractionLabel: "1/4", displayQuantity: "6,000", inputValue: "6000")
        ]

        return [
            .init(
                id: "cashPurchasable",
                title: language.text(.cashPurchasable),
                tone: .buy,
                options: cashAmounts
            ),
            .init(
                id: "maximumPurchasable",
                title: language.text(.maximumPurchasable),
                tone: .buy,
                options: cashAmounts
            ),
            .init(
                id: "positionSellable",
                title: language.text(.positionSellable),
                tone: .sell,
                options: [
                    .init(fractionLabel: language.text(.fullPosition), displayQuantity: "4,000", inputValue: "4000"),
                    .init(fractionLabel: "1/2", displayQuantity: "2,000", inputValue: "2000"),
                    .init(fractionLabel: "1/3", displayQuantity: "1320", inputValue: "1320"),
                    .init(fractionLabel: "1/4", displayQuantity: "1000", inputValue: "1000")
                ]
            )
        ]
    }
}

/// The quantity field used by the stock-order demo.
///
/// The parent owns valid lot sizes, nudging arithmetic, and the quick-input
/// values that apply to a symbol. Decimal validation is intentionally kept
/// local to this input component so crypto quantities behave like the stock
/// quantity field everywhere else.
struct StockOrderQuantityInput: View {
    @Binding var quantity: String
    @Binding var focusedInput: StockOrderFormInputFocus?

    let quickInputColumns: [StockOrderQuantityQuickInputColumn]
    let inputMode: StockOrderQuantityInputMode
    let showsValidationError: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onQuickInput: (StockOrderQuantityQuickInputItem) -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isQuantityFieldFocused: Bool
    @State private var isQuickInputPresented: Bool

    init(
        quantity: Binding<String>,
        quickInputColumns: [StockOrderQuantityQuickInputColumn],
        focusedInput: Binding<StockOrderFormInputFocus?> = .constant(nil),
        inputMode: StockOrderQuantityInputMode = .wholeNumber,
        showsValidationError: Bool = false,
        initiallyShowsQuickInput: Bool = false,
        onDecrease: @escaping () -> Void = {},
        onIncrease: @escaping () -> Void = {},
        onQuickInput: @escaping (StockOrderQuantityQuickInputItem) -> Void = { _ in }
    ) {
        _quantity = quantity
        _focusedInput = focusedInput
        self.quickInputColumns = quickInputColumns
        self.inputMode = inputMode
        self.showsValidationError = showsValidationError
        self.onDecrease = onDecrease
        self.onIncrease = onIncrease
        self.onQuickInput = onQuickInput
        _isQuickInputPresented = State(
            initialValue: initiallyShowsQuickInput && !quickInputColumns.isEmpty
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            quantityContent
        }
        .frame(
            maxWidth: .infinity,
            minHeight: presentationHeight,
            maxHeight: presentationHeight,
            alignment: .top
        )
        .clipped()
        .background(Color("color-base-1"))
        .animation(
            StockOrderMotion.expansion(reduceMotion: reduceMotion),
            value: isQuickInputPresented
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.quantityInput")
        .onChange(of: quantity) { _, newValue in
            let sanitizedQuantity = sanitized(newValue)

            if sanitizedQuantity != newValue {
                quantity = sanitizedQuantity
            }
        }
        .onChange(of: isQuantityFieldFocused) { _, isFocused in
            if isFocused && isQuickInputPresented {
                withAnimation(
                    StockOrderMotion.expansion(reduceMotion: reduceMotion)
                ) {
                    isQuickInputPresented = false
                }
            }

            if isFocused {
                focusedInput = .quantity
            } else if focusedInput == .quantity {
                focusedInput = nil
            }
        }
        .onChange(of: focusedInput) { _, focusedInput in
            guard focusedInput != .quantity else { return }
            isQuantityFieldFocused = false
        }
        .onDisappear {
            if focusedInput == .quantity {
                focusedInput = nil
            }
        }
    }

    private var quantityContent: some View {
        VStack(spacing: 0) {
            inputRow

            if hasQuickInput {
                StockOrderQuantityQuickInputPanel(
                    columns: quickInputColumns,
                    onSelect: selectQuickInput
                )
                .padding(.horizontal, StockOrderQuantityInputLayout.horizontalPadding)
                .allowsHitTesting(isQuickInputPresented)
                .accessibilityHidden(!isQuickInputPresented)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var inputRow: some View {
        HStack(spacing: 0) {
            quantityLabel

            quantityControl
        }
        .padding(.horizontal, StockOrderQuantityInputLayout.horizontalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderQuantityInputLayout.controlHeight,
            maxHeight: StockOrderQuantityInputLayout.controlHeight,
            alignment: .leading
        )
    }

    private var quantityLabel: some View {
        Text(language.text(.quantity))
            .modifier(
                CustomFontModifier(
                    size: 16,
                    font: .regular,
                    lineHeight: 24
                )
            )
            .foregroundColor(
                showsValidationError
                    ? Color("color-utility3-red")
                    : Color("color-text-30")
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(
                width: StockOrderQuantityInputLayout.labelWidth,
                height: StockOrderQuantityInputLayout.controlHeight,
                alignment: .leading
            )
            .accessibilityIdentifier("stockOrder.quantityInput.label")
    }

    private var quantityControl: some View {
        HStack(spacing: StockOrderQuantityInputLayout.quickInputButtonSpacing) {
            quantityField

            if hasQuickInput {
                quickInputButton
            }
        }
        .frame(
            width: StockOrderQuantityInputLayout.valueWidth,
            height: StockOrderQuantityInputLayout.controlHeight,
            alignment: .trailing
        )
    }

    private var quantityField: some View {
        HStack(spacing: 0) {
            nudgeButton(
                assetName: "decrease__sign",
                accessibilityLabel: language.text(.decreaseQuantity),
                identifier: "stockOrder.quantityInput.decrease",
                action: decrease
            )
            .padding(.leading, StockOrderQuantityInputLayout.nudgeHorizontalInset)

            ZStack(alignment: .leading) {
                if quantity.isEmpty {
                    Text(quantityPlaceholder)
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

                TextField("", text: $quantity)
                    .modifier(
                        CustomFontModifier(
                            size: 16,
                            font: .medium,
                            lineHeight: 24
                        )
                    )
                    .foregroundColor(Color("color-text-30"))
                    .keyboardType(inputMode.maxFractionDigits == nil ? .numberPad : .decimalPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($isQuantityFieldFocused)
                    .accessibilityLabel(language.text(.quantity))
                    .accessibilityValue(
                        quantity.isEmpty
                            ? quantityPlaceholder
                            : quantity
                    )
                    .accessibilityIdentifier("stockOrder.quantityInput.field")
            }
            .frame(
                width: textFieldWidth,
                height: StockOrderQuantityInputLayout.controlHeight,
                alignment: .leading
            )
            .padding(.leading, StockOrderQuantityInputLayout.textFieldLeadingInset)

            nudgeButton(
                assetName: "increase_sign",
                accessibilityLabel: language.text(.increaseQuantity),
                identifier: "stockOrder.quantityInput.increase",
                action: increase
            )
            .padding(.trailing, StockOrderQuantityInputLayout.nudgeHorizontalInset)
        }
        .frame(
            width: quantityFieldWidth,
            height: StockOrderQuantityInputLayout.controlHeight
        )
        .background(Color("color-scale-2"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderQuantityInputLayout.fieldCornerRadius,
                style: .continuous
            )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.quantityInput.value")
    }

    private var quickInputButton: some View {
        Button(action: toggleQuickInput) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: StockOrderQuantityInputLayout.fieldCornerRadius,
                    style: .continuous
                )
                .fill(Color("color-scale-2"))
                .frame(
                    width: StockOrderQuantityInputLayout.quickInputBackgroundSize,
                    height: StockOrderQuantityInputLayout.quickInputBackgroundSize
                )

                Image(
                    isQuickInputPresented
                        ? "quantity_quick_select_active"
                        : "quantity_quick_select_inactive"
                )
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockOrderQuantityInputLayout.quickInputGlyphSize,
                    height: StockOrderQuantityInputLayout.quickInputGlyphSize
                )
                .accessibilityHidden(true)
            }
            .frame(
                width: StockOrderQuantityInputLayout.quickInputButtonSize,
                height: StockOrderQuantityInputLayout.quickInputButtonSize
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(StockOrderNudgePressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(
            language.text(
                isQuickInputPresented
                    ? .hideQuickQuantityInput
                    : .quickQuantityInput
            )
        )
        .accessibilityValue(
            language.text(
                isQuickInputPresented
                    ? .expanded
                    : .collapsed
            )
        )
        .accessibilityIdentifier("stockOrder.quantityInput.quickInput")
    }

    private var hasQuickInput: Bool {
        !quickInputColumns.isEmpty
    }

    private var quantityFieldWidth: CGFloat {
        hasQuickInput
            ? StockOrderQuantityInputLayout.fieldWidthWithQuickInput
            : StockOrderQuantityInputLayout.valueWidth
    }

    private var textFieldWidth: CGFloat {
        hasQuickInput
            ? StockOrderQuantityInputLayout.textFieldWidthWithQuickInput
            : StockOrderQuantityInputLayout.textFieldWidthWithoutQuickInput
    }

    private var quickInputPanelHeight: CGFloat {
        StockOrderQuantityQuickInputPanel.height(for: quickInputColumns)
    }

    private var presentationHeight: CGFloat {
        guard hasQuickInput && isQuickInputPresented else {
            return StockOrderQuantityInputLayout.controlHeight
        }

        return StockOrderQuantityInputLayout.controlHeight + quickInputPanelHeight
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
                    cornerRadius: StockOrderQuantityInputLayout.nudgeCornerRadius,
                    style: .continuous
                )
                .fill(Color("color-base-1"))

                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: StockOrderQuantityInputLayout.nudgeGlyphSize,
                        height: StockOrderQuantityInputLayout.nudgeGlyphSize
                    )
            }
            .frame(
                width: StockOrderQuantityInputLayout.nudgeSize,
                height: StockOrderQuantityInputLayout.nudgeSize
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(StockOrderNudgePressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }

    private func decrease() {
        nudgeQuantity(onDecrease)
    }

    private func increase() {
        nudgeQuantity(onIncrease)
    }

    private func nudgeQuantity(_ action: () -> Void) {
        let shouldRestoreFocus = isQuantityFieldFocused

        if !shouldRestoreFocus {
            dismissActiveInput()
        }

        action()
        HapticManager.instance.impactHaptic(type: .medium)

        guard shouldRestoreFocus else { return }

        isQuantityFieldFocused = true
        DispatchQueue.main.async {
            isQuantityFieldFocused = true
        }
    }

    private func toggleQuickInput() {
        guard hasQuickInput else { return }

        dismissActiveInput()
        withAnimation(StockOrderMotion.expansion(reduceMotion: reduceMotion)) {
            isQuickInputPresented.toggle()
        }
    }

    private func selectQuickInput(_ item: StockOrderQuantityQuickInputItem) {
        dismissActiveInput()
        quantity = item.inputValue
        HapticManager.instance.impactHaptic(type: .medium)
        onQuickInput(item)
    }

    private func dismissActiveInput() {
        isQuantityFieldFocused = false
        focusedInput = nil
    }

    private func sanitized(_ value: String) -> String {
        guard let maxFractionDigits = inputMode.maxFractionDigits else {
            return value.filter { "0123456789".contains($0) }
        }

        let allowed = value.filter { "0123456789.".contains($0) }
        let pieces = allowed.split(separator: ".", omittingEmptySubsequences: false)
        let integerPart = pieces.first.map(String.init) ?? ""

        guard pieces.count > 1 else {
            return integerPart
        }

        let fractionPart = String(pieces[1].prefix(maxFractionDigits))
        return integerPart + "." + fractionPart
    }

    private var quantityPlaceholder: String {
        inputMode.placeholder ?? language.text(.enterQuantity)
    }
}

private enum StockOrderQuantityInputLayout {
    static let horizontalPadding: CGFloat = 16
    static let labelWidth: CGFloat = 112
    static let valueWidth: CGFloat = 258
    static let controlHeight: CGFloat = 44
    static let fieldWidthWithQuickInput: CGFloat = 208
    static let fieldCornerRadius: CGFloat = 10
    static let quickInputButtonSpacing: CGFloat = 6
    static let quickInputButtonSize: CGFloat = 44
    static let quickInputBackgroundSize: CGFloat = 42
    static let quickInputGlyphSize: CGFloat = 30
    static let nudgeHorizontalInset: CGFloat = 6
    static let nudgeSize: CGFloat = 32
    static let nudgeGlyphSize: CGFloat = 30
    static let nudgeCornerRadius: CGFloat = 6
    static let textFieldLeadingInset: CGFloat = 12
    static let textFieldWidthWithQuickInput: CGFloat = 120
    static let textFieldWidthWithoutQuickInput: CGFloat = 170
}

private struct StockOrderQuantityQuickInputPanel: View {
    let columns: [StockOrderQuantityQuickInputColumn]
    let onSelect: (StockOrderQuantityQuickInputItem) -> Void

    @Environment(\.demoLanguage) private var language

    private var numberOfRows: Int {
        columns.map(\.options.count).max() ?? 0
    }

    /// Buy and sell areas are allocated independently so their total widths
    /// always remain equal. A side may contain one or more amount columns.
    private var marketSideGroups: [[StockOrderQuantityQuickInputColumn]] {
        let buyColumns = columns.filter { $0.tone == .buy }
        let sellColumns = columns.filter { $0.tone == .sell }

        return [buyColumns, sellColumns].filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(spacing: StockOrderQuantityQuickInputPanelLayout.headerToGridSpacing) {
            headers

            if numberOfRows > 0 {
                grid
            }
        }
        .padding(.top, StockOrderQuantityQuickInputPanelLayout.topInset)
        .padding(.bottom, StockOrderQuantityQuickInputPanelLayout.bottomInset)
        .frame(
            maxWidth: .infinity,
            minHeight: Self.height(for: columns),
            maxHeight: Self.height(for: columns),
            alignment: .top
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.text(.quickQuantityInput))
        .accessibilityIdentifier("stockOrder.quantityInput.quickInput.panel")
    }

    private var headers: some View {
        HStack(spacing: StockOrderQuantityQuickInputPanelLayout.marketSideSpacing) {
            ForEach(marketSideGroups.indices, id: \.self) { groupIndex in
                headerGroup(for: marketSideGroups[groupIndex])
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: StockOrderQuantityQuickInputPanelLayout.rowSpacing) {
            ForEach(0..<numberOfRows, id: \.self) { rowIndex in
                HStack(spacing: StockOrderQuantityQuickInputPanelLayout.marketSideSpacing) {
                    ForEach(marketSideGroups.indices, id: \.self) { groupIndex in
                        optionGroup(
                            marketSideGroups[groupIndex],
                            at: rowIndex
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderQuantityQuickInputPanelLayout.rowHeight,
                    maxHeight: StockOrderQuantityQuickInputPanelLayout.rowHeight
                )
            }
        }
    }

    private func headerGroup(
        for columns: [StockOrderQuantityQuickInputColumn]
    ) -> some View {
        HStack(spacing: StockOrderQuantityQuickInputPanelLayout.columnSpacing) {
            ForEach(columns) { column in
                Text(column.title)
                    .modifier(
                        CustomFontModifier(
                            size: 12,
                            font: .regular,
                            lineHeight: 16
                        )
                    )
                    .foregroundColor(Color("color-text-90"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: StockOrderQuantityQuickInputPanelLayout.headerHeight,
                        maxHeight: StockOrderQuantityQuickInputPanelLayout.headerHeight
                    )
            }
        }
    }

    @ViewBuilder
    private func optionGroup(
        _ columns: [StockOrderQuantityQuickInputColumn],
        at rowIndex: Int
    ) -> some View {
        HStack(spacing: StockOrderQuantityQuickInputPanelLayout.columnSpacing) {
            ForEach(columns) { column in
                if rowIndex < column.options.count {
                    quickInputOption(
                        column.options[rowIndex],
                        in: column
                    )
                } else {
                    Color.clear
                        .frame(
                            maxWidth: .infinity,
                            minHeight: StockOrderQuantityQuickInputPanelLayout.rowHeight,
                            maxHeight: StockOrderQuantityQuickInputPanelLayout.rowHeight
                        )
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func quickInputOption(
        _ option: StockOrderQuantityQuickInputItem,
        in column: StockOrderQuantityQuickInputColumn
    ) -> some View {
        Button {
            onSelect(option)
        } label: {
            VStack(spacing: 0) {
                Text(option.fractionLabel)
                    .modifier(
                        CustomFontModifier(
                            size: 12,
                            font: .regular,
                            lineHeight: 16
                        )
                    )
                    .foregroundColor(Color("color-text-90"))
                    .lineLimit(1)

                Text(option.displayQuantity)
                    .modifier(
                        CustomFontModifier(
                            size: 14,
                            font: .medium,
                            lineHeight: 20
                        )
                    )
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: StockOrderQuantityQuickInputPanelLayout.rowHeight,
                maxHeight: StockOrderQuantityQuickInputPanelLayout.rowHeight
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(column.tone.color.opacity(0.1))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderQuantityQuickInputPanelLayout.optionCornerRadius,
                style: .continuous
            )
        )
        .accessibilityLabel(
            "\(column.title), \(option.fractionLabel), \(option.displayQuantity)"
        )
        .accessibilityIdentifier(
            "stockOrder.quantityInput.quickInput.\(column.id).\(option.id)"
        )
    }

    static func height(for columns: [StockOrderQuantityQuickInputColumn]) -> CGFloat {
        let rowCount = columns.map(\.options.count).max() ?? 0
        let gridHeight = CGFloat(rowCount)
            * StockOrderQuantityQuickInputPanelLayout.rowHeight
            + CGFloat(max(rowCount - 1, 0))
            * StockOrderQuantityQuickInputPanelLayout.rowSpacing

        return StockOrderQuantityQuickInputPanelLayout.topInset
            + StockOrderQuantityQuickInputPanelLayout.headerHeight
            + StockOrderQuantityQuickInputPanelLayout.headerToGridSpacing
            + gridHeight
            + StockOrderQuantityQuickInputPanelLayout.bottomInset
    }
}

private enum StockOrderQuantityQuickInputPanelLayout {
    static let topInset: CGFloat = 12
    static let bottomInset: CGFloat = 12
    static let headerHeight: CGFloat = 14
    static let headerToGridSpacing: CGFloat = 8
    static let marketSideSpacing: CGFloat = 4
    static let columnSpacing: CGFloat = 4
    static let rowSpacing: CGFloat = 4
    static let rowHeight: CGFloat = 43
    static let optionCornerRadius: CGFloat = 4
}

private struct StockOrderQuantityInputPreviewHarness: View {
    let initiallyShowsQuickInput: Bool

    @State private var quantity = "100"
    @Environment(\.demoLanguage) private var language

    var body: some View {
        StockOrderQuantityInput(
            quantity: $quantity,
            quickInputColumns: StockOrderQuantityQuickInputColumn.demoColumns(for: language),
            initiallyShowsQuickInput: initiallyShowsQuickInput,
            onDecrease: { nudgeQuantity(by: -100) },
            onIncrease: { nudgeQuantity(by: 100) }
        )
    }

    private func nudgeQuantity(by amount: Int) {
        let currentQuantity = Int(quantity) ?? 0
        quantity = String(max(0, currentQuantity + amount))
    }
}

struct StockOrderQuantityInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderQuantityInput(
                quantity: .constant(""),
                quickInputColumns: StockOrderQuantityQuickInputColumn.demoColumns(
                    for: .simplifiedChinese
                )
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("Simplified Chinese · Empty")
            .previewLayout(.fixed(width: 402, height: 44))

            StockOrderQuantityInputPreviewHarness(initiallyShowsQuickInput: true)
                .environment(\.demoLanguage, .traditionalChinese)
                .previewDisplayName("Traditional Chinese · Quick Input")
            .previewLayout(.fixed(width: 402, height: 274))

            StockOrderQuantityInput(
                quantity: .constant("100"),
                quickInputColumns: StockOrderQuantityQuickInputColumn.demoColumns(
                    for: .english
                ),
                showsValidationError: true
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Validation Error · Dark")
            .previewLayout(.fixed(width: 402, height: 44))
        }
    }
}
