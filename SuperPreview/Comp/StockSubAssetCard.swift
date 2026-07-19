//
//  StockSubAssetCard.swift
//  SuperPreview
//

import SwiftUI

struct StockSubAssetCardModel {
    let currency: String
    let netAsset: String
    let todayProfitLoss: String
    let securitiesMarketValue: String
    let totalCash: String
    let positionProfitLoss: String
    let fundsInTransit: String
    let ipoFundsInTransit: String
    let frozenFunds: String
    let currencyBalances: [SubAssetCurrencyBalance]

    static let preview = StockSubAssetCardModel(
        currency: "USD",
        netAsset: "8,880,123.01",
        todayProfitLoss: "+1,123.01(+3.12%)",
        securitiesMarketValue: "8,880,123.01",
        totalCash: "122,262,100.12",
        positionProfitLoss: "+9,123,090.12",
        fundsInTransit: "0.00",
        ipoFundsInTransit: "0.00",
        frozenFunds: "0.00",
        currencyBalances: [
            SubAssetCurrencyBalance(
                currency: "HKD",
                flagImageName: "subasset_flag_hkd",
                available: "300.00",
                withdrawable: "300.00",
                buyingPower: "600.00"
            ),
            SubAssetCurrencyBalance(
                currency: "USD",
                flagImageName: "subasset_flag_usd",
                available: "300.00",
                withdrawable: "300.00",
                buyingPower: "300.00"
            ),
            SubAssetCurrencyBalance(
                currency: "CNY",
                flagImageName: "subasset_flag_cny",
                available: "300.00",
                withdrawable: "300.00",
                buyingPower: "300.00"
            )
        ]
    )
}

struct StockSubAssetCard: View {
    let model: StockSubAssetCardModel
    let isNumberHidden: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isExpanded: Bool
    @State private var expansionBlurRadius: CGFloat

    init(
        model: StockSubAssetCardModel = .preview,
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
                toggleExpansion: toggleExpansion,
                contentWidth: 248
            )

            SubAssetMetricRow(
                items: [
                    SubAssetMetricItem(
                        title: "证券市值",
                        value: model.securitiesMarketValue,
                        alignment: .leading
                    ),
                    SubAssetMetricItem(
                        title: "总现金",
                        value: model.totalCash,
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
                SubAssetMetricRow(
                    items: [
                        SubAssetMetricItem(
                            title: "在途资金",
                            value: model.fundsInTransit,
                            alignment: .leading
                        ),
                        SubAssetMetricItem(
                            title: "IPO 在途资金",
                            value: model.ipoFundsInTransit,
                            alignment: .center
                        ),
                        SubAssetMetricItem(
                            title: "冻结资金",
                            value: model.frozenFunds,
                            alignment: .trailing
                        )
                    ],
                    isNumberHidden: isNumberHidden
                )

                SubAssetCardSeparator()

                StockSubAssetCashBreakdown(
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

private struct StockSubAssetCashBreakdown: View {
    let balances: [SubAssetCurrencyBalance]
    let isNumberHidden: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                title("现金可用", alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(balances) { balance in
                        SubAssetCurrencyValue(
                            flagImageName: balance.flagImageName,
                            value: balance.available,
                            isNumberHidden: isNumberHidden
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                title("现金可取", alignment: .center)

                VStack(spacing: 8) {
                    ForEach(balances) { balance in
                        value(balance.withdrawable, alignment: .center)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .trailing, spacing: 4) {
                title("最大购买力", alignment: .trailing)

                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(balances) { balance in
                        value(balance.buyingPower, alignment: .trailing)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 346, height: 100, alignment: .top)
    }

    private func title(_ text: String, alignment: Alignment) -> some View {
        Text(text)
            .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
            .foregroundColor(Color("color-text-60"))
            .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20, alignment: alignment)
    }

    private func value(_ text: String, alignment: Alignment) -> some View {
        Text(SubAssetCardValue.display(text, isNumberHidden: isNumberHidden))
            .font(.custom("PlusJakartaSans-Medium", size: 14, relativeTo: .subheadline))
            .foregroundColor(Color("color-text-30"))
            .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20, alignment: alignment)
            .lineLimit(1)
    }
}

struct StockSubAssetCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            StockSubAssetCard()
            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .frame(width: 402, height: 420, alignment: .top)
        .background(Color("color-base-1"))
        .previewLayout(.fixed(width: 402, height: 420))
        .previewDisplayName("Stock SubAssetCard")
    }
}
