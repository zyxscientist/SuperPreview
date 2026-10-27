//
//  MarketIPOCenterView.swift
//  SuperPreview
//
//  组件名称：新股中心
//  简介：展示今日认购与待上市新股信息。
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

struct MarketIPOUpcomingListing: Identifiable, Hashable {
    let id: String
    let name: String
    let code: String
    let greyMarketDate: String
    let listingDate: String

    static let figmaReference: [Self] = [
        Self(
            id: "upcoming-1",
            name: "奕斯伟计算机",
            code: "01256",
            greyMarketDate: "2026/11/11",
            listingDate: "2026/11/11"
        ),
        Self(
            id: "upcoming-2",
            name: "大疆创新",
            code: "01234",
            greyMarketDate: "2026/11/14",
            listingDate: "2026/11/15"
        ),
        Self(
            id: "upcoming-3",
            name: "星海科技",
            code: "02688",
            greyMarketDate: "2026/11/20",
            listingDate: "2026/11/21"
        )
    ]
}

/// The host supplies navigation and subscription actions when those flows exist.
struct MarketIPOCenterView: View {
    private enum Tab: Equatable {
        case subscriptions
        case upcomingListings
    }

    let subscriptions: [MarketIPOSubscription]
    let upcomingListings: [MarketIPOUpcomingListing]
    let onShowAll: () -> Void
    let onSubscribe: (MarketIPOSubscription) -> Void
    let onAddToWatchlist: (MarketIPOUpcomingListing) -> Void
    @State private var selectedTab: Tab = .subscriptions
    @Environment(\.demoLanguage) private var language

    init(
        subscriptions: [MarketIPOSubscription] = MarketIPOSubscription.figmaReference,
        upcomingListings: [MarketIPOUpcomingListing] = MarketIPOUpcomingListing.figmaReference,
        onShowAll: @escaping () -> Void = { /* TODO: connect the IPO center destination. */ },
        onSubscribe: @escaping (MarketIPOSubscription) -> Void = { _ in
            /* TODO: connect the subscription destination. */
        },
        onAddToWatchlist: @escaping (MarketIPOUpcomingListing) -> Void = { _ in
            /* TODO: connect the watchlist action. */
        }
    ) {
        self.subscriptions = subscriptions
        self.upcomingListings = upcomingListings
        self.onShowAll = onShowAll
        self.onSubscribe = onSubscribe
        self.onAddToWatchlist = onAddToWatchlist
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(alignment: .leading, spacing: 8) {
                tabs
                if selectedTab == .subscriptions {
                    subscriptionCards
                } else {
                    upcomingListingCards
                }
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
            tabButton(
                title: String(format: language.text(.ipoTodaySubscriptionsFormat), subscriptions.count),
                isSelected: selectedTab == .subscriptions,
                accessibilityIdentifier: "market.ipoCenter.tab.subscriptions"
            ) {
                selectedTab = .subscriptions
            }

            tabButton(
                title: String(format: language.text(.ipoUpcomingListingsFormat), upcomingListings.count),
                isSelected: selectedTab == .upcomingListings,
                accessibilityIdentifier: "market.ipoCenter.tab.upcoming"
            ) {
                selectedTab = .upcomingListings
            }

            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func tabButton(
        title: String,
        isSelected: Bool,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            // Keep both font descriptors stable so the numeric glyph does not
            // disappear while SwiftUI replaces its font on selection.
            ZStack {
                Text(title)
                    .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                    .opacity(isSelected ? 0 : 1)
                    .accessibilityHidden(true)

                Text(title)
                    .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
                .animation(nil, value: isSelected)
                .foregroundStyle(Color(isSelected ? "color-text-30" : "color-text-60"))
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(
                    Color(isSelected ? "color-base-1" : "color-scale-1"),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? Color("color-base-r") : .clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(accessibilityIdentifier)
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

    private var upcomingListingCards: some View {
        VStack(spacing: 2) {
            ForEach(Array(upcomingListings.enumerated()), id: \.element.id) { index, listing in
                upcomingListingCard(
                    listing,
                    isFirst: index == 0,
                    isLast: index == upcomingListings.count - 1
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
        .background(cardBackground(isFirst: isFirst, isLast: isLast))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.ipoCenter.row.\(subscription.id)")
    }

    private func upcomingListingCard(
        _ listing: MarketIPOUpcomingListing,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        let localizedName = language.ipoCompanyName(id: listing.id, fallback: listing.name)
        let nameAndCode = String(format: language.text(.ipoNameAndCodeFormat), localizedName, listing.code)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(nameAndCode)
                    .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))
                    .foregroundStyle(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    listingDateRow(
                        label: language.text(.ipoGreyMarketTradingTime),
                        date: listing.greyMarketDate
                    )
                    listingDateRow(
                        label: language.text(.ipoListingTime),
                        date: listing.listingDate
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onAddToWatchlist(listing)
            } label: {
                Image("Favorite")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(language.text(.ipoAddToWatchlist))
            .accessibilityIdentifier("market.ipoCenter.watchlist.\(listing.id)")
        }
        .padding(.leading, 16)
        .padding(.trailing, 20)
        .padding(.vertical, 16)
        .frame(minHeight: 96)
        .background(cardBackground(isFirst: isFirst, isLast: isLast))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.ipoCenter.upcoming.\(listing.id)")
    }

    private func listingDateRow(label: String, date: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
            Text(date)
        }
        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
        .foregroundStyle(Color("color-text-60"))
        .lineLimit(1)
    }

    private func cardBackground(isFirst: Bool, isLast: Bool) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? 20 : 2,
            bottomLeadingRadius: isLast ? 20 : 2,
            bottomTrailingRadius: isLast ? 20 : 2,
            topTrailingRadius: isFirst ? 20 : 2
        )
        .fill(Color("color-scale-1"))
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
