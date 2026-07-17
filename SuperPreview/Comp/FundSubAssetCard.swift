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
    @State private var isExpanded: Bool
    @State private var expansionBlurRadius: CGFloat

    init(
        model: FundSubAssetCardModel = .preview,
        isNumberHidden: Bool = false,
        initiallyExpanded: Bool = false
    ) {
        self.model = model
        self.isNumberHidden = isNumberHidden
        _isExpanded = State(initialValue: initiallyExpanded)
        _expansionBlurRadius = State(initialValue: initiallyExpanded ? 0 : 7)
    }

    var body: some View {
        SubAssetCardContainer {
            SubAssetCardHeader(
                currency: model.currency,
                netAsset: model.netAsset,
                profitLossTitle: "昨日收益",
                profitLoss: model.yesterdayIncome,
                isNumberHidden: isNumberHidden,
                isExpanded: isExpanded,
                toggleExpansion: toggleExpansion
            )

            SubAssetMetricRow(
                items: [
                    SubAssetMetricItem(
                        title: "基金市值",
                        value: model.fundMarketValue,
                        alignment: .leading
                    ),
                    SubAssetMetricItem(
                        title: "持仓收益",
                        value: model.positionIncome,
                        alignment: .trailing,
                        isGain: true
                    )
                ],
                isNumberHidden: isNumberHidden
            )
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 16) {
                SubAssetMetricRow(
                    items: [
                        SubAssetMetricItem(
                            title: "在途资金",
                            value: model.fundsInTransit,
                            alignment: .leading
                        ),
                        SubAssetMetricItem(
                            title: "冻结资金",
                            value: model.frozenFunds,
                            alignment: .trailing
                        )
                    ],
                    isNumberHidden: isNumberHidden
                )
            }
            .padding(.top, 16)
            .subAssetExpansion(
                isExpanded: isExpanded,
                blurRadius: expansionBlurRadius
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
