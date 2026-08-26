//
//  StockOrderConfirmationSheet.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderConfirmationSide: String, Hashable, Identifiable {
    case buy
    case sell

    var id: String { rawValue }

    var titleKey: DemoCopyKey {
        self == .buy ? .buy : .sell
    }
}

enum StockOrderConfirmationValueTone {
    case primary
    case buy
    case sell
    case warning

    var color: Color {
        switch self {
        case .primary:
            return Color("color-text-30")
        case .buy:
            return Color("color-utility3-red")
        case .sell:
            return Color("color-utility3-green")
        case .warning:
            return Color("color-utility3-warning")
        }
    }
}

struct StockOrderConfirmationRow: Identifiable {
    let id: String
    let label: String
    let value: String
    let tone: StockOrderConfirmationValueTone

    init(
        id: String,
        label: String,
        value: String,
        tone: StockOrderConfirmationValueTone = .primary
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.tone = tone
    }
}

struct StockOrderConfirmationData {
    let estimatedAmount: String
    let rows: [StockOrderConfirmationRow]
    let warning: String?

    init(
        estimatedAmount: String,
        rows: [StockOrderConfirmationRow],
        warning: String? = nil
    ) {
        self.estimatedAmount = estimatedAmount
        self.rows = rows
        self.warning = warning
    }
}

/// The second confirmation surface shown after tapping Buy or Sell.
///
/// The presentation is intentionally kept inside the component so the parent
/// only supplies localized, presentation-ready order data and the final
/// confirmation callback. Its initial and explicit dismissal transitions stay
/// as a simple bottom-up ease-out, while downward dragging follows the finger
/// and either dismisses or rebounds like the native symbol-search sheet.
struct StockOrderConfirmationSheet: View {
    let data: StockOrderConfirmationData
    let onConfirm: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isMaskVisible = false
    @State private var isCardVisible = false
    @State private var isDismissing = false
    @State private var cardDragOffset: CGFloat = 0

    init(
        data: StockOrderConfirmationData,
        onConfirm: @escaping () -> Void = {}
    ) {
        self.data = data
        self.onConfirm = onConfirm
    }

    var body: some View {
        GeometryReader { proxy in
            let dragProgress = min(
                max(cardDragOffset / max(proxy.size.height, 1), 0),
                1
            )

            ZStack(alignment: .bottom) {
                dismissalMask(dragProgress: dragProgress)

                confirmationCard
                    .offset(
                        y: isCardVisible
                            ? cardDragOffset
                            : proxy.size.height
                    )
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeOut(
                                duration: StockOrderConfirmationSheetLayout.cardTransitionDuration
                            ),
                        value: isCardVisible
                    )
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear(perform: present)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.confirmationSheet")
    }

    private func dismissalMask(dragProgress: CGFloat) -> some View {
        Button(action: dismissSheet) {
            Color.black
                .opacity(
                    isMaskVisible
                        ? StockOrderConfirmationSheetLayout.maskOpacity
                            * (1 - dragProgress)
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
                    duration: StockOrderConfirmationSheetLayout.maskFadeDuration
                ),
            value: isMaskVisible
        )
        .accessibilityLabel(language.text(.cancel))
        .accessibilityIdentifier("stockOrder.confirmationSheet.mask")
    }

    private var confirmationCard: some View {
        VStack(spacing: 0) {
            sheetHandle
            sheetContent
            bottomButtonArea
        }
        .frame(maxWidth: .infinity)
        .background(Color("color-base-1"))
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: StockOrderConfirmationSheetLayout.cornerRadius,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: StockOrderConfirmationSheetLayout.cornerRadius
                ),
                style: .continuous
            )
        )
        .accessibilityIdentifier("stockOrder.confirmationSheet.card")
        .contentShape(Rectangle())
        .simultaneousGesture(cardDragGesture)
    }

    private var sheetHandle: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color("color-scale-3"))
                .frame(
                    width: StockOrderConfirmationSheetLayout.handleWidth,
                    height: StockOrderConfirmationSheetLayout.handleHeight
                )
                .accessibilityHidden(true)
        }
        .padding(.top, StockOrderConfirmationSheetLayout.handleTopPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderConfirmationSheetLayout.handleAreaHeight,
            maxHeight: StockOrderConfirmationSheetLayout.handleAreaHeight,
            alignment: .top
        )
        .accessibilityHidden(true)
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: StockOrderConfirmationSheetLayout.contentSpacing) {
            estimatedAmount

            if let warning = data.warning, !warning.isEmpty {
                Text(warning)
                    .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                    .foregroundColor(Color("color-utility3-warning"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, StockOrderConfirmationSheetLayout.horizontalPadding)
                    .accessibilityIdentifier("stockOrder.confirmationSheet.warning")
            }

            VStack(spacing: 0) {
                ForEach(data.rows) { row in
                    detailRow(row)
                }
            }
            .padding(.bottom, StockOrderConfirmationSheetLayout.lastRowBottomPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("stockOrder.confirmationSheet.content")
    }

    private var estimatedAmount: some View {
        VStack(alignment: .leading, spacing: StockOrderConfirmationSheetLayout.amountSpacing) {
            Text(language.text(.estimatedAmount))
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)

            Text(data.estimatedAmount)
                .modifier(CustomFontModifier(size: 30, font: .bold, lineHeight: 40))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .accessibilityIdentifier("stockOrder.confirmationSheet.estimatedAmount")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, StockOrderConfirmationSheetLayout.horizontalPadding)
        .padding(.vertical, StockOrderConfirmationSheetLayout.amountVerticalPadding)
    }

    private func detailRow(_ row: StockOrderConfirmationRow) -> some View {
        HStack(spacing: 0) {
            Text(row.label)
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(
                    width: StockOrderConfirmationSheetLayout.labelWidth,
                    alignment: .leading
                )

            Text(row.value)
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .foregroundColor(row.tone.color)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, StockOrderConfirmationSheetLayout.horizontalPadding)
        .padding(.vertical, StockOrderConfirmationSheetLayout.rowVerticalPadding)
        .frame(minHeight: StockOrderConfirmationSheetLayout.rowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(row.label)
        .accessibilityValue(row.value)
        .accessibilityIdentifier("stockOrder.confirmationSheet.row.\(row.id)")
    }

    private var bottomButtonArea: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color("color-separator-10"))
                .frame(height: StockOrderConfirmationSheetLayout.separatorHeight)
                .accessibilityHidden(true)

            HStack(spacing: StockOrderConfirmationSheetLayout.buttonSpacing) {
                actionButton(
                    title: language.text(.cancel),
                    fill: Color("color-scale-2"),
                    foreground: Color("color-text-30"),
                    action: dismissSheet,
                    identifier: "cancel"
                )

                actionButton(
                    title: language.text(.confirm),
                    fill: Color("color-base-r"),
                    foreground: Color("color-text-r"),
                    action: confirm,
                    identifier: "confirm"
                )
            }
            .padding(.horizontal, StockOrderConfirmationSheetLayout.horizontalPadding)
            .padding(.top, StockOrderConfirmationSheetLayout.buttonTopPadding)

            Color.clear
                .frame(height: StockOrderConfirmationSheetLayout.homeIndicatorAreaHeight)
                .accessibilityHidden(true)
        }
        .accessibilityIdentifier("stockOrder.confirmationSheet.buttons")
    }

    private func actionButton(
        title: String,
        fill: Color,
        foreground: Color,
        action: @escaping () -> Void,
        identifier: String
    ) -> some View {
        Button(action: action) {
            Text(title)
                .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 16))
                .foregroundColor(foreground)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: StockOrderConfirmationSheetLayout.buttonHeight)
                .background(fill, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityIdentifier("stockOrder.confirmationSheet.button.\(identifier)")
    }

    private func present() {
        guard !isDismissing else { return }

        cardDragOffset = 0

        if reduceMotion {
            isMaskVisible = true
            isCardVisible = true
            return
        }

        DispatchQueue.main.async {
            guard !isDismissing else { return }

            isMaskVisible = true
            isCardVisible = true
        }
    }

    private var cardDragGesture: some Gesture {
        DragGesture(
            minimumDistance: StockOrderConfirmationSheetLayout.dragMinimumDistance,
            coordinateSpace: .local
        )
        .onChanged(updateCardDrag)
        .onEnded(endCardDrag)
    }

    private func updateCardDrag(_ value: DragGesture.Value) {
        guard isCardVisible, !isDismissing else { return }

        let isVerticalDrag = abs(value.translation.height) >= abs(value.translation.width)
        let nextOffset = isVerticalDrag ? max(0, value.translation.height) : 0
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            cardDragOffset = nextOffset
        }
    }

    private func endCardDrag(_ value: DragGesture.Value) {
        guard isCardVisible, !isDismissing else { return }

        let isVerticalDrag = abs(value.translation.height) >= abs(value.translation.width)
        let translation = max(0, value.translation.height)
        let projectedTranslation = max(0, value.predictedEndTranslation.height)
        let shouldDismiss = isVerticalDrag && (
            translation >= StockOrderConfirmationSheetLayout.dragDismissalDistance
                || projectedTranslation
                    >= StockOrderConfirmationSheetLayout.dragProjectedDismissalDistance
        )

        if shouldDismiss {
            dismissSheet()
        } else {
            resetCardDrag()
        }
    }

    private func resetCardDrag() {
        guard cardDragOffset != 0 else { return }

        if reduceMotion {
            cardDragOffset = 0
        } else {
            withAnimation(StockOrderConfirmationSheetLayout.dragResetAnimation) {
                cardDragOffset = 0
            }
        }
    }

    private func confirm() {
        guard !isDismissing else { return }

        onConfirm()
        dismissSheet()
    }

    private func dismissSheet() {
        guard !isDismissing else { return }

        isDismissing = true
        isMaskVisible = false
        isCardVisible = false

        if reduceMotion {
            dismiss()
            return
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now()
                + StockOrderConfirmationSheetLayout.cardTransitionDuration
        ) {
            dismiss()
        }
    }
}

private enum StockOrderConfirmationSheetLayout {
    static let horizontalPadding: CGFloat = 16
    static let handleAreaHeight: CGFloat = 44
    static let handleTopPadding: CGFloat = 10
    static let handleWidth: CGFloat = 40
    static let handleHeight: CGFloat = 4
    static let contentSpacing: CGFloat = 10
    static let amountSpacing: CGFloat = 4
    static let amountVerticalPadding: CGFloat = 4
    static let labelWidth: CGFloat = 120
    static let rowHeight: CGFloat = 32
    static let rowVerticalPadding: CGFloat = 4
    static let lastRowBottomPadding: CGFloat = 10
    static let separatorHeight: CGFloat = 0.5
    static let buttonTopPadding: CGFloat = 8
    static let buttonHeight: CGFloat = 44
    static let buttonSpacing: CGFloat = 12
    static let homeIndicatorAreaHeight: CGFloat = 34
    static let cornerRadius: CGFloat = 10
    static let maskOpacity: CGFloat = 0.3
    static let maskFadeDuration: TimeInterval = 0.3
    static let cardTransitionDuration: TimeInterval = 0.3
    static let dragMinimumDistance: CGFloat = 2
    static let dragDismissalDistance: CGFloat = 120
    static let dragProjectedDismissalDistance: CGFloat = 220
    static let dragResetAnimation = Animation.spring(
        response: 0.35,
        dampingFraction: 0.86,
        blendDuration: 0.15
    )
}

private struct StockOrderConfirmationSheetPreviewHarness: View {
    let data: StockOrderConfirmationData

    var body: some View {
        StockOrderConfirmationSheet(data: data)
            .environment(\.demoLanguage, .simplifiedChinese)
    }
}

struct StockOrderConfirmationSheet_Previews: PreviewProvider {
    static var previews: some View {
        StockOrderConfirmationSheetPreviewHarness(
            data: StockOrderConfirmationData(
                estimatedAmount: "HKD 34,000.00",
                rows: [
                    .init(id: "account", label: "交易账户", value: "证券融资账户(0909)"),
                    .init(id: "type", label: "订单类型", value: "增强限价单"),
                    .init(id: "side", label: "方向", value: "买入", tone: .buy),
                    .init(id: "symbol", label: "名称", value: "云锋金融(00376)"),
                    .init(id: "price", label: "价格", value: "3.990"),
                    .init(id: "quantity", label: "数量", value: "2,000"),
                    .init(id: "fees", label: "交易费用及税项", value: "11.23"),
                    .init(id: "commission", label: "佣金费率", value: "0.00%，最低0.00"),
                    .init(id: "validity", label: "有效期", value: "当日有效")
                ]
            )
        )
        .previewDisplayName("Common · Simplified Chinese")
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
