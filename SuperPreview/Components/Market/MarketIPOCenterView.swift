//
//  MarketIPOCenterView.swift
//  SuperPreview
//
//  组件名称：新股中心
//  简介：展示「今日认购」的新股、优惠标签和认购剩余时间。
//  用于：新市场页的港股分类，也可独立预览。
//

import SwiftUI

struct MarketIPOSubscription: Identifiable, Hashable {
    enum Promotion: Hashable {
        case leverage(Int)
        case zeroCashSubscriptionFee
    }

    let id: String
    let name: String
    let code: String
    let remainingTimeHours: Int
    let promotion: Promotion?

    static let figmaReference: [Self] = [
        Self(
            id: "subscription-1",
            name: "奕斯伟计算",
            code: "01256",
            remainingTimeHours: 23,
            promotion: .leverage(10)
        ),
        Self(
            id: "subscription-2",
            name: "大疆创新",
            code: "01234",
            remainingTimeHours: 71,
            promotion: .zeroCashSubscriptionFee
        ),
        Self(
            id: "subscription-3",
            name: "大疆创新",
            code: "01234",
            remainingTimeHours: 143,
            promotion: nil
        )
    ]
}

/// The subscription state of the standalone IPO center.
/// The host supplies navigation and subscription actions when those flows exist.
struct MarketIPOCenterView: View {
    let subscriptions: [MarketIPOSubscription]
    let upcomingListingCount: Int
    let onShowAll: () -> Void
    let onSubscribe: (MarketIPOSubscription) -> Void
    @Environment(\.demoLanguage) private var language

    init(
        subscriptions: [MarketIPOSubscription] = MarketIPOSubscription.figmaReference,
        upcomingListingCount: Int = 3,
        onShowAll: @escaping () -> Void = { /* TODO: connect the IPO center destination. */ },
        onSubscribe: @escaping (MarketIPOSubscription) -> Void = { _ in
            /* TODO: connect the subscription destination. */
        }
    ) {
        self.subscriptions = subscriptions
        self.upcomingListingCount = upcomingListingCount
        self.onShowAll = onShowAll
        self.onSubscribe = onSubscribe
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(alignment: .leading, spacing: 8) {
                tabs
                subscriptionCards
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.ipoCenter")
    }

    private var header: some View {
        Button(action: onShowAll) {
            HStack(spacing: 8) {
                Text(language.text(.ipoCenter))
                    .modifier(CustomFontModifier(size: 18, font: .bold, lineHeight: 28))
                    .foregroundStyle(Color("color-text-30"))

                Spacer(minLength: 0)

                Image("chevron_right_text30_sm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .accessibilityLabel(language.actionAccessibilityLabel(name: language.text(.ipoCenter), action: language.text(.viewAll)))
        .accessibilityIdentifier("market.ipoCenter.showAll")
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            Text(String(format: language.text(.ipoTodaySubscriptionsFormat), subscriptions.count))
                .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                .foregroundStyle(Color("color-text-30"))
                .frame(height: 20)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color("color-base-r"), lineWidth: 1)
                }
                .accessibilityAddTraits(.isSelected)
                .accessibilityIdentifier("market.ipoCenter.tab.subscriptions")

            // The upcoming-listings state will be added with its design.
            Text(String(format: language.text(.ipoUpcomingListingsFormat), upcomingListingCount))
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundStyle(Color("color-text-60"))
                .frame(height: 20)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityIdentifier("market.ipoCenter.tab.upcoming")

            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var subscriptionCards: some View {
        VStack(spacing: 2) {
            ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, subscription in
                subscriptionCard(
                    subscription,
                    isFirst: index == 0,
                    isLast: index == subscriptions.count - 1
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func subscriptionCard(
        _ subscription: MarketIPOSubscription,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        let localizedName = language.ipoCompanyName(id: subscription.id, fallback: subscription.name)
        let nameAndCode = String(format: language.text(.ipoNameAndCodeFormat), localizedName, subscription.code)
        let remainingTime = language.ipoRemainingTime(hours: subscription.remainingTimeHours)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(nameAndCode)
                    .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))
                    .foregroundStyle(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(height: 20)

                if let promotion = subscription.promotion {
                    promotionTag(promotion)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onSubscribe(subscription)
            } label: {
                Text(remainingTime)
                    .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 16))
                    .foregroundStyle(Color("color-text-r"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 62)
                    .frame(height: 28)
                    .background(Color("color-base-r"), in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: language.text(.ipoSubscribeAccessibilityFormat), localizedName, remainingTime))
            .accessibilityIdentifier("market.ipoCenter.subscribe.\(subscription.id)")
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 16)
        .frame(minHeight: 78)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: isFirst ? 20 : 2,
                bottomLeadingRadius: isLast ? 20 : 2,
                bottomTrailingRadius: isLast ? 20 : 2,
                topTrailingRadius: isFirst ? 20 : 2
            )
            .fill(Color("color-scale-1"))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.ipoCenter.row.\(subscription.id)")
    }

    @ViewBuilder
    private func promotionTag(_ promotion: MarketIPOSubscription.Promotion) -> some View {
        switch promotion {
        case .leverage(let multiplier):
            HStack(spacing: 4) {
                Image("market_ipo_leverage_fire")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)

                (
                    Text(language.text(.ipoUpTo))
                    + Text("\(multiplier)").font(.custom(CustomFontModifier.CustomFont.bold.rawValue, size: 12))
                    + Text(language.text(.ipoLeverage))
                )
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundStyle(Color("color-utility6-orange"))
                .frame(height: 16)
            }
            .padding(.trailing, 8)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: 4
                )
                .fill(Color("color-utility6-orange").opacity(0.1))
            }

        case .zeroCashSubscriptionFee:
            Text(language.text(.ipoCashSubscriptionFeeZero))
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundStyle(Color("color-brand-blue"))
                .frame(height: 16)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color("color-brand-blue-2"), in: RoundedRectangle(cornerRadius: 4))
        }
    }
}

struct MarketIPOCenterView_Previews: PreviewProvider {
    static var previews: some View {
        MarketIPOCenterView()
            .background(Color("color-base-1"))
            .previewLayout(.fixed(width: 402, height: 334))
            .previewDisplayName("新股中心 · 今日认购")
    }
}
