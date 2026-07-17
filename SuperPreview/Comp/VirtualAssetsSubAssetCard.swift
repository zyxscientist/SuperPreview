//
//  VirtualAssetsSubAssetCard.swift
//  SuperPreview
//

import SwiftUI

struct VirtualAssetsSubAssetCardModel {
    let currency: String
    let netAsset: String
    let todayProfitLoss: String
    let marketValue: String
    let availableCash: String
    let positionProfitLoss: String
    let currencyBalances: [SubAssetCurrencyBalance]

    static let preview = VirtualAssetsSubAssetCardModel(
        currency: "USD",
        netAsset: "8,880,123.01",
        todayProfitLoss: "+1,123.01(+3.12%)",
        marketValue: "10,123.01",
        availableCash: "9,900.91",
        positionProfitLoss: "+13,090.12",
        currencyBalances: [
            SubAssetCurrencyBalance(
                currency: "HKD",
                flagImageName: "subasset_flag_hkd",
                available: "300.00",
                withdrawable: "",
                buyingPower: ""
            ),
            SubAssetCurrencyBalance(
                currency: "USD",
                flagImageName: "subasset_flag_usd",
                available: "300.00",
                withdrawable: "",
                buyingPower: ""
            )
        ]
    )
}

struct VirtualAssetsSubAssetCard: View {
    let model: VirtualAssetsSubAssetCardModel
    let isNumberHidden: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isExpanded: Bool
    @State private var expansionBlurRadius: CGFloat

    init(
        model: VirtualAssetsSubAssetCardModel = .preview,
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
                profitLossTitle: "今日盈亏",
                profitLoss: model.todayProfitLoss,
                isNumberHidden: isNumberHidden,
                isExpanded: isExpanded,
                toggleExpansion: toggleExpansion
            )

            SubAssetMetricRow(
                items: [
                    SubAssetMetricItem(
                        title: "虚拟资产市值",
                        value: model.marketValue,
                        alignment: .leading
                    ),
                    SubAssetMetricItem(
                        title: "现金可用",
                        value: model.availableCash,
                        alignment: .center,
                        showsDisclosure: true
                    ),
                    SubAssetMetricItem(
                        title: "持仓盈亏",
                        value: model.positionProfitLoss,
                        alignment: .trailing,
                        isGain: true
                    )
                ],
                isNumberHidden: isNumberHidden
            )
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 16) {
                SubAssetCardSeparator()

                VirtualAssetsCashBreakdown(
                    balances: model.currencyBalances,
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

private struct VirtualAssetsCashBreakdown: View {
    let balances: [SubAssetCurrencyBalance]
    let isNumberHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("现金可用")
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundColor(Color("color-text-60"))
                .frame(height: 20)

            HStack(spacing: 0) {
                ForEach(balances) { balance in
                    SubAssetCurrencyValue(
                        flagImageName: balance.flagImageName,
                        value: balance.available,
                        isNumberHidden: isNumberHidden
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 20)
        }
        .frame(width: 346, height: 44, alignment: .leading)
    }
}

struct VirtualAssetsSubAssetCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            VirtualAssetsSubAssetCard()
            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .frame(width: 402, height: 420, alignment: .top)
        .background(Color("color-base-1"))
        .previewLayout(.fixed(width: 402, height: 420))
        .previewDisplayName("Virtual Assets SubAssetCard")
    }
}
