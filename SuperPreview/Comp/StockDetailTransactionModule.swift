//
//  StockDetailTransactionModule.swift
//  SuperPreview
//

import SwiftUI

/// The destinations represented by the transaction module's top-level tabs.
///
/// The tab bar is intentionally independent from the module content so the
/// subsequent trade, position, order, and history views can share this state.
enum StockDetailTransactionModuleTab: CaseIterable, Hashable, Identifiable {
    case trade
    case positions
    case orders
    case history

    var id: Self { self }

    fileprivate func title(for language: DemoLanguage) -> String {
        switch (self, language) {
        case (.trade, .simplifiedChinese):
            return "交易"
        case (.trade, .traditionalChinese):
            return "交易"
        case (.trade, .english):
            return "Trade"
        case (.positions, .simplifiedChinese):
            return "持仓"
        case (.positions, .traditionalChinese):
            return "持倉"
        case (.positions, .english):
            return "Position"
        case (.orders, .simplifiedChinese):
            return "订单"
        case (.orders, .traditionalChinese):
            return "訂單"
        case (.orders, .english):
            return "Orders"
        case (.history, .simplifiedChinese):
            return "历史"
        case (.history, .traditionalChinese):
            return "歷史"
        case (.history, .english):
            return "History"
        }
    }

    fileprivate func iconAssetName(isSelected: Bool) -> String {
        switch (self, isSelected) {
        case (.trade, false):
            return "stock_detail_transaction_trade"
        case (.trade, true):
            return "stock_detail_transaction_trade_selected"
        case (.positions, false):
            return "stock_detail_transaction_position"
        case (.positions, true):
            return "stock_detail_transaction_position_selected"
        case (.orders, false):
            return "stock_detail_transaction_order"
        case (.orders, true):
            return "stock_detail_transaction_order_selected"
        case (.history, false):
            return "stock_detail_transaction_history"
        case (.history, true):
            return "stock_detail_transaction_history_selected"
        }
    }

    fileprivate var accessibilityIdentifier: String {
        switch self {
        case .trade:
            return "trade"
        case .positions:
            return "positions"
        case .orders:
            return "orders"
        case .history:
            return "history"
        }
    }
}

/// The four-button navigation strip at the top of the stock-detail
/// transaction module.
///
/// It only owns tab selection. The corresponding detail content is added by
/// the parent module as that larger feature is built.
struct StockDetailTransactionModuleTabBar: View {
    @Binding private var selection: StockDetailTransactionModuleTab?

    @Environment(\.demoLanguage) private var language

    init(selection: Binding<StockDetailTransactionModuleTab?>) {
        _selection = selection
    }

    var body: some View {
        GeometryReader { geometry in
            let tabWidth = max(
                (
                    geometry.size.width
                        - StockDetailTransactionModuleTabBarLayout.horizontalPadding * 2
                        - StockDetailTransactionModuleTabBarLayout.tabSpacing
                            * CGFloat(StockDetailTransactionModuleTab.allCases.count - 1)
                ) / CGFloat(StockDetailTransactionModuleTab.allCases.count),
                0
            )

            HStack(spacing: StockDetailTransactionModuleTabBarLayout.tabSpacing) {
                ForEach(StockDetailTransactionModuleTab.allCases) { tab in
                    tabButton(tab, width: tabWidth)
                }
            }
            .padding(.horizontal, StockDetailTransactionModuleTabBarLayout.horizontalPadding)
            .padding(.vertical, StockDetailTransactionModuleTabBarLayout.verticalPadding)
        }
        .frame(height: StockDetailTransactionModuleTabBarLayout.height)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionModule.tabBar")
    }

    private func tabButton(
        _ tab: StockDetailTransactionModuleTab,
        width: CGFloat
    ) -> some View {
        let isSelected = selection == tab
        let title = tab.title(for: language)

        return Button {
            selection = isSelected ? nil : tab
        } label: {
            HStack(spacing: StockDetailTransactionModuleTabBarLayout.iconToTitleSpacing) {
                Image(tab.iconAssetName(isSelected: isSelected))
                    .resizable()
                    .frame(
                        width: StockDetailTransactionModuleTabBarLayout.iconSize,
                        height: StockDetailTransactionModuleTabBarLayout.iconSize
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailTransactionModuleTabBarLayout.titleFontSize,
                            font: isSelected ? .medium : .regular,
                            lineHeight: StockDetailTransactionModuleTabBarLayout.titleLineHeight
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(StockDetailTransactionModuleTabBarLayout.minimumTitleScale)
            }
            .foregroundColor(isSelected ? Color("color-brand-blue") : Color("color-text-30"))
            .padding(.vertical, StockDetailTransactionModuleTabBarLayout.buttonVerticalPadding)
            .frame(
                width: width,
                height: StockDetailTransactionModuleTabBarLayout.buttonHeight
            )
            .background(
                isSelected
                    ? Color("color-brand-blue").opacity(StockDetailTransactionModuleTabBarLayout.selectedBackgroundOpacity)
                    : Color("color-base-1"),
                in: RoundedRectangle(
                    cornerRadius: StockDetailTransactionModuleTabBarLayout.cornerRadius,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: StockDetailTransactionModuleTabBarLayout.cornerRadius,
                    style: .continuous
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("stockDetail.transactionModule.tab.\(tab.accessibilityIdentifier)")
    }
}

private enum StockDetailTransactionModuleTabBarLayout {
    static let height: CGFloat = 64
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 16
    static let tabSpacing: CGFloat = 8
    static let buttonHeight: CGFloat = 32
    static let buttonVerticalPadding: CGFloat = 6
    static let iconSize: CGFloat = 16
    static let iconToTitleSpacing: CGFloat = 4
    static let titleFontSize: CGFloat = 14
    static let titleLineHeight: CGFloat = 20
    static let minimumTitleScale: CGFloat = 0.5
    static let cornerRadius: CGFloat = 8
    static let selectedBackgroundOpacity: CGFloat = 0.1
}

private struct StockDetailTransactionModuleTabBarPreviewHarness: View {
    @State private var selection: StockDetailTransactionModuleTab?

    init(initialSelection: StockDetailTransactionModuleTab? = nil) {
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        StockDetailTransactionModuleTabBar(selection: $selection)
    }
}

struct StockDetailTransactionModuleTabBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionModuleTabBarPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("简体中文 · 未选择")

            StockDetailTransactionModuleTabBarPreviewHarness(initialSelection: .history)
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("English · History")
        }
        .previewLayout(.fixed(width: 402, height: 64))
    }
}
