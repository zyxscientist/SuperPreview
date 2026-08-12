//
//  FundSubAssetCard.swift
//  SuperPreview
//

import SwiftUI

struct FundSubAssetCardModel {
    let currency: String
    let netAsset: String
    let yesterdayIncome: String
    let fundMarketValue: String
    let positionIncome: String
    let fundsInTransit: String
    let frozenFunds: String

    static let preview = FundSubAssetCardModel(
        currency: "USD",
        netAsset: "8,880,123.01",
        yesterdayIncome: "+1,123.01",
        fundMarketValue: "10,123.01",
        positionIncome: "+13,090.12",
        fundsInTransit: "0.00",
        frozenFunds: "0.00"
    )
}

struct FundSubAssetCard: View {
    let model: FundSubAssetCardModel
    let isNumberHidden: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage(TradeAggregationExpansionStorageKey.fundSubAssetCard)
    private var isExpanded = false
    @State private var expansionBlurRadius: CGFloat
    @Environment(\.demoLanguage) private var language

    init(
        model: FundSubAssetCardModel = .preview,
        isNumberHidden: Bool = false,
        initiallyExpanded: Bool = false
    ) {
        self.model = model
        self.isNumberHidden = isNumberHidden
        _isExpanded = AppStorage(
            wrappedValue: initiallyExpanded,
            TradeAggregationExpansionStorageKey.fundSubAssetCard
        )
        _expansionBlurRadius = State(initialValue: initiallyExpanded ? 0 : 7)
    }

    var body: some View {
        SubAssetCardContainer {
            SubAssetCardHeader(
                currency: model.currency,
                netAsset: model.netAsset,
                profitLossTitle: language.text(.yesterdayProfitLoss),
                profitLoss: model.yesterdayIncome,
                isNumberHidden: isNumberHidden,
                isExpanded: isExpanded,
                toggleExpansion: toggleExpansion
            )

            SubAssetMetricRow(
                items: [
                    SubAssetMetricItem(
                        id: "fundMarketValue",
                        title: language.text(.fundMarketValue),
                        value: model.fundMarketValue,
                        alignment: .leading,
                        accessibilityLabel: language.accessibilityText(.fundMarketValue)
                    ),
                    SubAssetMetricItem(
                        id: "positionIncome",
                        title: language.text(.positionIncome),
                        value: model.positionIncome,
                        alignment: .trailing,
                        isGain: true,
                        accessibilityLabel: language.accessibilityText(.positionIncome)
                    )
                ],
                isNumberHidden: isNumberHidden
            )
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 16) {
                SubAssetMetricRow(
                    items: [
                        SubAssetMetricItem(
                            id: "fundsInTransit",
                            title: language.text(.fundsInTransit),
                            value: model.fundsInTransit,
                            alignment: .leading,
                            accessibilityLabel: language.accessibilityText(.fundsInTransit)
                        ),
                        SubAssetMetricItem(
                            id: "fundsOnHold",
                            title: language.text(.fundsOnHold),
                            value: model.frozenFunds,
                            alignment: .trailing,
                            accessibilityLabel: language.accessibilityText(.fundsOnHold)
                        )
                    ],
                    isNumberHidden: isNumberHidden
                )
            }
            .padding(.top, 16)
            .subAssetExpansion(
                isExpanded: isExpanded,
                blurRadius: isExpanded ? 0 : expansionBlurRadius
            )
        }
    }

    private func toggleExpansion() {
        withAnimation(SubAssetCardMotion.expansion(reduceMotion: accessibilityReduceMotion)) {
            isExpanded.toggle()
            expansionBlurRadius = isExpanded ? 0 : 5
        }
    }
}

struct FundSubAssetCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            FundSubAssetCard()
            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .frame(width: 402, height: 420, alignment: .top)
        .background(Color("color-base-1"))
        .previewLayout(.fixed(width: 402, height: 420))
        .previewDisplayName("Fund SubAssetCard")
    }
}
