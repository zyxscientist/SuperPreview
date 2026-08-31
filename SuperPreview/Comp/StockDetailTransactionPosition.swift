//
//  StockDetailTransactionPosition.swift
//  SuperPreview
//

import SwiftUI

/// The display state of the stock-detail transaction module's position tab.
///
/// A position card has three profit-and-loss tones; the empty state is kept
/// separate because it follows a distinct, fixed-height layout in the design.
enum StockDetailTransactionPositionState: Equatable {
    case position(StockDetailTransactionPositionData)
    case empty
}

/// The color and direction treatment applied to position profit-and-loss data.
enum StockDetailTransactionPositionProfitLossTone: Equatable {
    case gain
    case loss
    case flat
}

/// Data displayed for one symbol in the position tab.
struct StockDetailTransactionPositionData: Equatable {
    let positionProfitLoss: String
    let positionProfitLossRate: String
    let todayProfitLoss: String
    let quantity: String
    let marketValue: String
    let costPrice: String
    let portfolioWeight: String
    let positionProfitLossTone: StockDetailTransactionPositionProfitLossTone
    let todayProfitLossTone: StockDetailTransactionPositionProfitLossTone

    init(
        positionProfitLoss: String,
        positionProfitLossRate: String,
        todayProfitLoss: String,
        quantity: String,
        marketValue: String,
        costPrice: String,
        portfolioWeight: String,
        positionProfitLossTone: StockDetailTransactionPositionProfitLossTone,
        todayProfitLossTone: StockDetailTransactionPositionProfitLossTone
    ) {
        self.positionProfitLoss = positionProfitLoss
        self.positionProfitLossRate = positionProfitLossRate
        self.todayProfitLoss = todayProfitLoss
        self.quantity = quantity
        self.marketValue = marketValue
        self.costPrice = costPrice
        self.portfolioWeight = portfolioWeight
        self.positionProfitLossTone = positionProfitLossTone
        self.todayProfitLossTone = todayProfitLossTone
    }
}

/// The content displayed beneath the stock-detail transaction module's
/// position tab.
///
/// The containing transaction module owns tab selection; this view is focused
/// solely on the selected symbol's position state and remains passive.
struct StockDetailTransactionPosition: View {
    let state: StockDetailTransactionPositionState

    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(spacing: 0) {
            switch state {
            case let .position(data):
                positionCard(data)
                    .padding(.horizontal, StockDetailTransactionPositionLayout.horizontalPadding)
                    .padding(.bottom, StockDetailTransactionPositionLayout.cardBottomPadding)

            case .empty:
                emptyState
                    .padding(.bottom, StockDetailTransactionPositionLayout.emptyBottomPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color("color-base-1"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("color-separator-10"))
                .frame(height: StockDetailTransactionPositionLayout.separatorHeight)
                .padding(.horizontal, StockDetailTransactionPositionLayout.horizontalPadding)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.transactionPosition")
    }

    private func positionCard(_ data: StockDetailTransactionPositionData) -> some View {
        VStack(spacing: StockDetailTransactionPositionLayout.cardSectionSpacing) {
            HStack(alignment: .top, spacing: StockDetailTransactionPositionLayout.topRowSpacing) {
                profitLossBlock(data)
                    .frame(maxWidth: .infinity, alignment: .leading)

                quantityBlock(data)
                    .frame(width: StockDetailTransactionPositionLayout.quantityColumnWidth, alignment: .trailing)
            }

            HStack(spacing: StockDetailTransactionPositionLayout.statisticsSpacing) {
                statisticColumn(
                    title: positionText(.marketValue),
                    value: data.marketValue,
                    alignment: .leading
                )

                statisticColumn(
                    title: positionText(.costPrice),
                    value: data.costPrice,
                    alignment: .center
                )

                statisticColumn(
                    title: language.text(.portfolioWeightHeader),
                    value: data.portfolioWeight,
                    alignment: .trailing
                )
            }
        }
        .padding(StockDetailTransactionPositionLayout.cardPadding)
        .frame(maxWidth: .infinity)
        .frame(height: StockDetailTransactionPositionLayout.cardHeight)
        .background(
            Color("color-scale-1"),
            in: RoundedRectangle(
                cornerRadius: StockDetailTransactionPositionLayout.cardCornerRadius,
                style: .continuous
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.transactionPosition.card")
    }

    private func profitLossBlock(_ data: StockDetailTransactionPositionData) -> some View {
        VStack(alignment: .leading, spacing: StockDetailTransactionPositionLayout.profitLossBlockSpacing) {
            labelText(language.text(.positionProfitLoss))
                .frame(height: StockDetailTransactionPositionLayout.regularLineHeight)

            HStack(spacing: StockDetailTransactionPositionLayout.profitLossRateSpacing) {
                HStack(spacing: StockDetailTransactionPositionLayout.valueToArrowSpacing) {
                    largeValueText(
                        data.positionProfitLoss,
                        tone: data.positionProfitLossTone
                    )

                    if let arrowAssetName = arrowAssetName(for: data.positionProfitLossTone) {
                        Image(arrowAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: StockDetailTransactionPositionLayout.arrowSize,
                                height: StockDetailTransactionPositionLayout.arrowSize
                            )
                            .accessibilityHidden(true)
                    }
                }

                valueText(
                    data.positionProfitLossRate,
                    tone: data.positionProfitLossTone,
                    font: .medium
                )
            }
            .frame(height: StockDetailTransactionPositionLayout.largeValueLineHeight, alignment: .leading)

            HStack(spacing: StockDetailTransactionPositionLayout.todayProfitLossSpacing) {
                labelText(language.text(.todayProfitLoss))

                valueText(
                    data.todayProfitLoss,
                    tone: data.todayProfitLossTone,
                    font: .medium
                )
            }
            .frame(height: StockDetailTransactionPositionLayout.regularLineHeight, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.transactionPosition.profitLoss")
    }

    private func quantityBlock(_ data: StockDetailTransactionPositionData) -> some View {
        VStack(alignment: .trailing, spacing: StockDetailTransactionPositionLayout.quantitySpacing) {
            labelText(positionText(.quantity))
                .frame(height: StockDetailTransactionPositionLayout.regularLineHeight)

            valueText(data.quantity, tone: .flat, font: .bold)
                .frame(height: StockDetailTransactionPositionLayout.regularLineHeight)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.transactionPosition.quantity")
    }

    private func statisticColumn(
        title: String,
        value: String,
        alignment: Alignment
    ) -> some View {
        VStack(alignment: horizontalAlignment(for: alignment), spacing: StockDetailTransactionPositionLayout.statisticSpacing) {
            labelText(title)
                .frame(maxWidth: .infinity, alignment: alignment)
                .frame(height: StockDetailTransactionPositionLayout.regularLineHeight)

            valueText(value, tone: .flat, font: .medium)
                .frame(maxWidth: .infinity, alignment: alignment)
                .frame(height: StockDetailTransactionPositionLayout.regularLineHeight)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: StockDetailTransactionPositionLayout.emptyStateSpacing) {
            Image("empty_portfolio")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockDetailTransactionPositionLayout.emptyImageWidth,
                    height: StockDetailTransactionPositionLayout.emptyImageHeight
                )
                .accessibilityHidden(true)

            Text(language.text(.noPositions))
                .foregroundColor(Color("color-text-60"))
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTransactionPositionLayout.regularFontSize,
                        font: .regular,
                        lineHeight: StockDetailTransactionPositionLayout.regularLineHeight
                    )
                )
                .lineLimit(1)
                .frame(height: StockDetailTransactionPositionLayout.regularLineHeight)
        }
        .padding(.bottom, StockDetailTransactionPositionLayout.emptyStateBottomPadding)
        .frame(height: StockDetailTransactionPositionLayout.emptyStateHeight)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.transactionPosition.empty")
    }

    private func labelText(_ title: String) -> some View {
        Text(title)
            .foregroundColor(Color("color-text-60"))
            .modifier(
                CustomFontModifier(
                    size: StockDetailTransactionPositionLayout.regularFontSize,
                    font: .regular,
                    lineHeight: StockDetailTransactionPositionLayout.regularLineHeight
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private func largeValueText(
        _ value: String,
        tone: StockDetailTransactionPositionProfitLossTone
    ) -> some View {
        Text(value)
            .foregroundColor(color(for: tone))
            .modifier(
                CustomFontModifier(
                    size: StockDetailTransactionPositionLayout.largeValueFontSize,
                    font: .bold,
                    lineHeight: StockDetailTransactionPositionLayout.largeValueLineHeight
                )
            )
            .lineLimit(1)
            .monospacedDigit()
    }

    private func valueText(
        _ value: String,
        tone: StockDetailTransactionPositionProfitLossTone,
        font: CustomFontModifier.CustomFont
    ) -> some View {
        Text(value)
            .foregroundColor(color(for: tone))
            .modifier(
                CustomFontModifier(
                    size: StockDetailTransactionPositionLayout.regularFontSize,
                    font: font,
                    lineHeight: StockDetailTransactionPositionLayout.regularLineHeight
                )
            )
            .lineLimit(1)
            .monospacedDigit()
    }

    private func color(for tone: StockDetailTransactionPositionProfitLossTone) -> Color {
        switch tone {
        case .gain:
            Color("color-utility3-red")
        case .loss:
            Color("color-utility3-green")
        case .flat:
            Color("color-text-30")
        }
    }

    private func arrowAssetName(for tone: StockDetailTransactionPositionProfitLossTone) -> String? {
        switch tone {
        case .gain:
            "watchlistItem_up_red"
        case .loss:
            "watchlistItem_down_green"
        case .flat:
            nil
        }
    }

    private func horizontalAlignment(for alignment: Alignment) -> HorizontalAlignment {
        switch alignment {
        case .leading:
            .leading
        case .trailing:
            .trailing
        default:
            .center
        }
    }

    private func positionText(_ key: StockDetailTransactionPositionTextKey) -> String {
        switch (key, language) {
        case (.quantity, .simplifiedChinese):
            "持仓数量"
        case (.quantity, .traditionalChinese):
            "持倉數量"
        case (.quantity, .english):
            "Quantity"
        case (.marketValue, .simplifiedChinese):
            "市值"
        case (.marketValue, .traditionalChinese):
            "市值"
        case (.marketValue, .english):
            "Market Value"
        case (.costPrice, .simplifiedChinese):
            "成本价"
        case (.costPrice, .traditionalChinese):
            "成本價"
        case (.costPrice, .english):
            "Cost Price"
        }
    }
}

private enum StockDetailTransactionPositionTextKey {
    case quantity
    case marketValue
    case costPrice
}

private enum StockDetailTransactionPositionLayout {
    static let horizontalPadding: CGFloat = 16
    static let cardBottomPadding: CGFloat = 24
    static let emptyBottomPadding: CGFloat = 16
    static let separatorHeight: CGFloat = 0.5

    static let cardHeight: CGFloat = 172
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20
    static let cardSectionSpacing: CGFloat = 16
    static let topRowSpacing: CGFloat = 4
    static let quantityColumnWidth: CGFloat = 100
    static let statisticsSpacing: CGFloat = 4
    static let profitLossBlockSpacing: CGFloat = 4
    static let profitLossRateSpacing: CGFloat = 8
    static let valueToArrowSpacing: CGFloat = 4
    static let todayProfitLossSpacing: CGFloat = 8
    static let quantitySpacing: CGFloat = 10
    static let statisticSpacing: CGFloat = 4

    static let regularFontSize: CGFloat = 14
    static let regularLineHeight: CGFloat = 20
    static let largeValueFontSize: CGFloat = 20
    static let largeValueLineHeight: CGFloat = 32
    static let arrowSize: CGFloat = 12

    static let emptyStateHeight: CGFloat = 134
    static let emptyStateSpacing: CGFloat = 24
    static let emptyStateBottomPadding: CGFloat = 10
    static let emptyImageWidth: CGFloat = 130
    static let emptyImageHeight: CGFloat = 80
}

private struct StockDetailTransactionPositionPreviewHarness: View {
    let state: StockDetailTransactionPositionState

    @State private var selectedTab: StockDetailTransactionModuleTab? = .positions

    var body: some View {
        VStack(spacing: 0) {
            StockDetailTransactionModuleTabBar(selection: $selectedTab)
                .allowsHitTesting(false)

            StockDetailTransactionPosition(state: state)
        }
        .background(Color("color-base-1"))
    }
}

private enum StockDetailTransactionPositionPreviewData {
    static let gain = StockDetailTransactionPositionData(
        positionProfitLoss: "+6,100.00",
        positionProfitLossRate: "+9.53%",
        todayProfitLoss: "+1,123.01",
        quantity: "1,500",
        marketValue: "70,100.00",
        costPrice: "293.320",
        portfolioWeight: "8.38%",
        positionProfitLossTone: .gain,
        todayProfitLossTone: .gain
    )

    static let loss = StockDetailTransactionPositionData(
        positionProfitLoss: "-6,100.00",
        positionProfitLossRate: "-1.47%",
        todayProfitLoss: "-360.80",
        quantity: "1,500",
        marketValue: "70,100.00",
        costPrice: "293.320",
        portfolioWeight: "8.38%",
        positionProfitLossTone: .loss,
        todayProfitLossTone: .loss
    )

    static let flat = StockDetailTransactionPositionData(
        positionProfitLoss: "0.00",
        positionProfitLossRate: "0.00%",
        todayProfitLoss: "0.00",
        quantity: "1,500",
        marketValue: "70,100.00",
        costPrice: "293.320",
        portfolioWeight: "8.38%",
        positionProfitLossTone: .flat,
        todayProfitLossTone: .flat
    )
}

struct StockDetailTransactionPosition_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailTransactionPositionPreviewHarness(
                state: .position(StockDetailTransactionPositionPreviewData.gain)
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("盈利")
            .previewLayout(.fixed(width: 402, height: 260))

            StockDetailTransactionPositionPreviewHarness(
                state: .position(StockDetailTransactionPositionPreviewData.loss)
            )
            .environment(\.demoLanguage, .traditionalChinese)
            .previewDisplayName("虧損")
            .previewLayout(.fixed(width: 402, height: 260))

            StockDetailTransactionPositionPreviewHarness(
                state: .position(StockDetailTransactionPositionPreviewData.flat)
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Break-even")
            .previewLayout(.fixed(width: 402, height: 260))

            StockDetailTransactionPositionPreviewHarness(state: .empty)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("暫無持倉")
                .previewLayout(.fixed(width: 402, height: 214))
        }
    }
}
