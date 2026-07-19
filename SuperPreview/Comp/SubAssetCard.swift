//
//  SubAssetCard.swift
//  SuperPreview
//

import Foundation
import SwiftUI

enum TradeAggregationExpansionStorageKey {
    static let stockSubAssetCard = "tradeAggregation.subAssetCard.stock.isExpanded"
    static let fundSubAssetCard = "tradeAggregation.subAssetCard.fund.isExpanded"
    static let virtualAssetSubAssetCard = "tradeAggregation.subAssetCard.virtualAsset.isExpanded"
    static let stockHoldingGroups = "tradeAggregation.holdingGroups.stock.collapsedMarkets"
    static let fundHoldingGroups = "tradeAggregation.holdingGroups.fund.collapsedCurrencies"
    static let virtualAssetHoldingGroups = "tradeAggregation.holdingGroups.virtualAsset.collapsedCategories"
}

enum TradeAggregationExpansionState {
    static func restoredCollapsed<Value: Hashable & RawRepresentable>(
        for key: String,
        fallback: Set<Value>
    ) -> Set<Value> where Value.RawValue == String {
        guard let rawValues = UserDefaults.standard.stringArray(forKey: key) else {
            return fallback
        }

        return Set(rawValues.compactMap { Value(rawValue: $0) })
    }

    static func saveCollapsed<Value: Hashable & RawRepresentable>(
        _ values: Set<Value>,
        for key: String
    ) where Value.RawValue == String {
        UserDefaults.standard.set(values.map(\.rawValue).sorted(), forKey: key)
    }
}

struct SubAssetCurrencyBalance: Identifiable {
    let currency: String
    let flagImageName: String
    let available: String
    let withdrawable: String
    let buyingPower: String

    var id: String { currency }
}

enum SubAssetCardMotion {
    static func expansion(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? nil
            : .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)
    }
}

enum SubAssetCardValue {
    static func display(_ value: String, isNumberHidden: Bool) -> String {
        isNumberHidden ? "***" : value
    }
}

struct SubAssetCardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(width: 346, alignment: .topLeading)
        .padding(12)
        .background(Color("color-scale-1"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SubAssetExpansionModifier: ViewModifier {
    let isExpanded: Bool
    let blurRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isExpanded ? 1 : 0)
            .blur(radius: blurRadius)
            .frame(height: isExpanded ? nil : 0, alignment: .top)
            .clipped()
            .accessibilityHidden(!isExpanded)
            .allowsHitTesting(isExpanded)
    }
}

extension View {
    func subAssetExpansion(isExpanded: Bool, blurRadius: CGFloat) -> some View {
        modifier(
            SubAssetExpansionModifier(
                isExpanded: isExpanded,
                blurRadius: blurRadius
            )
        )
    }
}

struct SubAssetCardHeader: View {
    let currency: String
    let netAsset: String
    let profitLossTitle: String
    let profitLoss: String
    let isNumberHidden: Bool
    let isExpanded: Bool
    let toggleExpansion: () -> Void
    let contentWidth: CGFloat

    init(
        currency: String,
        netAsset: String,
        profitLossTitle: String,
        profitLoss: String,
        isNumberHidden: Bool,
        isExpanded: Bool,
        toggleExpansion: @escaping () -> Void
    ) {
        self.init(
            currency: currency,
            netAsset: netAsset,
            profitLossTitle: profitLossTitle,
            profitLoss: profitLoss,
            isNumberHidden: isNumberHidden,
            isExpanded: isExpanded,
            toggleExpansion: toggleExpansion,
            contentWidth: 183
        )
    }

    init(
        currency: String,
        netAsset: String,
        profitLossTitle: String,
        profitLoss: String,
        isNumberHidden: Bool,
        isExpanded: Bool,
        toggleExpansion: @escaping () -> Void,
        contentWidth: CGFloat = 183
    ) {
        self.currency = currency
        self.netAsset = netAsset
        self.profitLossTitle = profitLossTitle
        self.profitLoss = profitLoss
        self.isNumberHidden = isNumberHidden
        self.isExpanded = isExpanded
        self.toggleExpansion = toggleExpansion
        self.contentWidth = contentWidth
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("净资产·\(currency)")
                    .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                    .foregroundColor(Color("color-text-60"))
                    .frame(height: 20)

                Text(SubAssetCardValue.display(netAsset, isNumberHidden: isNumberHidden))
                    .font(.custom("PlusJakartaSans-Bold", size: 24, relativeTo: .title2))
                    .foregroundColor(Color("color-text-30"))
                    .frame(height: 36)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 8) {
                    Text(profitLossTitle)
                        .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                        .foregroundColor(Color("color-text-60"))

                    Text(SubAssetCardValue.display(profitLoss, isNumberHidden: isNumberHidden))
                        .font(.custom("PlusJakartaSans-Medium", size: 14, relativeTo: .subheadline))
                        .foregroundColor(Color(isNumberHidden ? "color-text-30" : "color-utility2-red"))
                }
                .frame(height: 20)
                .lineLimit(1)
            }
            .frame(width: contentWidth, height: 84, alignment: .topLeading)

            Spacer(minLength: 0)

            Button(action: toggleExpansion) {
                SubAssetCardExpansionIcon(isExpanded: isExpanded)
            }
            .buttonStyle(PlainButtonStyle())
            .sensoryFeedback(.impact(weight: .medium), trigger: isExpanded)
            .accessibilityLabel(isExpanded ? "收起资产详情" : "展开资产详情")
        }
        .frame(width: 346, height: 84, alignment: .top)
    }
}

private struct SubAssetCardExpansionIcon: View {
    let isExpanded: Bool

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                icon
                    .glassEffect(.regular.interactive(), in: .circle)
            } else {
                icon
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }

    private var icon: some View {
        Image("subasset_expand_chevron")
            .resizable()
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .frame(width: 24, height: 24)
    }
}

struct SubAssetMetricItem: Identifiable {
    let id: String
    let title: String
    let value: String
    let alignment: Alignment
    let isGain: Bool
    let showsDisclosure: Bool

    init(
        id: String? = nil,
        title: String,
        value: String,
        alignment: Alignment,
        isGain: Bool = false,
        showsDisclosure: Bool = false
    ) {
        self.id = id ?? title
        self.title = title
        self.value = value
        self.alignment = alignment
        self.isGain = isGain
        self.showsDisclosure = showsDisclosure
    }
}

struct SubAssetMetricRow: View {
    let items: [SubAssetMetricItem]
    let isNumberHidden: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                VStack(spacing: 4) {
                    HStack(spacing: item.showsDisclosure ? 2 : 0) {
                        Text(item.title)

                        if item.showsDisclosure {
                            Image("subasset_disclosure_chevron")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                    .foregroundColor(Color("color-text-60"))
                    .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20, alignment: item.alignment)

                    Text(SubAssetCardValue.display(item.value, isNumberHidden: isNumberHidden))
                        .font(.custom("PlusJakartaSans-Medium", size: 14, relativeTo: .subheadline))
                        .foregroundColor(valueColor(for: item))
                        .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20, alignment: item.alignment)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: item.alignment)
            }
        }
        .frame(width: 346, height: 44)
    }

    private func valueColor(for item: SubAssetMetricItem) -> Color {
        if item.isGain && !isNumberHidden {
            return Color("color-utility2-red")
        }
        return Color("color-text-30")
    }
}

struct SubAssetCardSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(width: 346, height: 0.5)
            .frame(height: 1, alignment: .bottom)
    }
}

struct SubAssetCurrencyValue: View {
    let flagImageName: String
    let value: String
    let isNumberHidden: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(flagImageName)
                .resizable()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)

            Text(SubAssetCardValue.display(value, isNumberHidden: isNumberHidden))
                .font(.custom("PlusJakartaSans-Medium", size: 14, relativeTo: .subheadline))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
        }
        .frame(height: 20)
    }
}
