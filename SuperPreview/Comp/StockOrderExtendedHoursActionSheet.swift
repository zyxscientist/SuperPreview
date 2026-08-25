//
//  StockOrderExtendedHoursActionSheet.swift
//  SuperPreview
//

import SwiftUI

/// The extended-hours action sheet. It deliberately matches the existing order
/// type and effect-period sheets: an in-place mask fade with cards moving from
/// the bottom, without a spring.
struct StockOrderExtendedHoursActionSheet: View {
    @Binding var selection: StockOrderExtendedHours

    let reduceMotion: Bool
    let onWillDismiss: () -> Void
    let onDismiss: () -> Void

    @Environment(\.demoLanguage) private var language
    @State private var isMaskVisible = false
    @State private var isCardsVisible = false
    @State private var isDismissing = false

    init(
        selection: Binding<StockOrderExtendedHours>,
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

                VStack(spacing: StockOrderExtendedHoursActionSheetLayout.sectionSpacing) {
                    optionsCard
                    cancelButton
                }
                .padding(.horizontal, StockOrderExtendedHoursActionSheetLayout.horizontalPadding)
                .padding(
                    .bottom,
                    StockOrderExtendedHoursActionSheetLayout.bottomPadding
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .offset(y: isCardsVisible ? 0 : proxy.size.height)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeOut(
                            duration: StockOrderExtendedHoursActionSheetLayout.cardTransitionDuration
                        ),
                    value: isCardsVisible
                )
            }
        }
        .onAppear(perform: present)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.extendedHoursActionSheet")
    }

    private var dismissalMask: some View {
        Button(action: dismiss) {
            Color.black
                .opacity(isMaskVisible ? StockOrderExtendedHoursActionSheetLayout.maskOpacity : 0)
                .ignoresSafeArea()
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            reduceMotion
                ? nil
                : .easeOut(
                    duration: StockOrderExtendedHoursActionSheetLayout.maskFadeDuration
                ),
            value: isMaskVisible
        )
        .accessibilityLabel(language.text(.cancel))
        .accessibilityIdentifier("stockOrder.extendedHoursActionSheet.mask")
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            Text(language.text(.chooseExtendedHours))
                .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                .foregroundColor(Color("color-text-60"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderExtendedHoursActionSheetLayout.titleHeight,
                    maxHeight: StockOrderExtendedHoursActionSheetLayout.titleHeight
                )
                .overlay(alignment: .bottom) { separator }
                .accessibilityIdentifier("stockOrder.extendedHoursActionSheet.title")

            ForEach(Array(StockOrderExtendedHours.allCases.enumerated()), id: \.element.id) {
                index,
                extendedHours in
                optionButton(extendedHours)
                    .overlay(alignment: .bottom) {
                        if index < StockOrderExtendedHours.allCases.count - 1 {
                            separator
                        }
                    }
            }
        }
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderExtendedHoursActionSheetLayout.cornerRadius,
                style: .continuous
            )
        )
    }

    private var cancelButton: some View {
        Button(action: dismiss) {
            Text(language.text(.cancel))
                .modifier(CustomFontModifier(size: 18, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-brand-blue"))
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderExtendedHoursActionSheetLayout.rowHeight,
                    maxHeight: StockOrderExtendedHoursActionSheetLayout.rowHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderExtendedHoursActionSheetLayout.cornerRadius,
                style: .continuous
            )
        )
        .accessibilityLabel(language.text(.cancel))
        .accessibilityIdentifier("stockOrder.extendedHoursActionSheet.cancel")
    }

    private var separator: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(height: StockOrderExtendedHoursActionSheetLayout.separatorHeight)
            .accessibilityHidden(true)
    }

    private func optionButton(_ extendedHours: StockOrderExtendedHours) -> some View {
        Button {
            select(extendedHours)
        } label: {
            Text(language.text(extendedHours.titleKey))
                .modifier(CustomFontModifier(size: 18, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-brand-blue"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderExtendedHoursActionSheetLayout.rowHeight,
                    maxHeight: StockOrderExtendedHoursActionSheetLayout.rowHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(language.text(extendedHours.titleKey))
        .accessibilityIdentifier("stockOrder.extendedHoursActionSheet.option.\(extendedHours.rawValue)")
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

    private func select(_ extendedHours: StockOrderExtendedHours) {
        guard !isDismissing else { return }
        selection = extendedHours
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
            deadline: .now() + StockOrderExtendedHoursActionSheetLayout.cardTransitionDuration
        ) {
            onDismiss()
        }
    }
}

private enum StockOrderExtendedHoursActionSheetLayout {
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

private struct StockOrderExtendedHoursActionSheetPreviewHarness: View {
    @State private var selection = StockOrderExtendedHours.defaultSelection

    var body: some View {
        StockOrderExtendedHoursActionSheet(selection: $selection)
    }
}

struct StockOrderExtendedHoursActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderExtendedHoursActionSheetPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese")

            StockOrderExtendedHoursActionSheet(selection: .constant(.notAllowed))
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("English · Dark")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
