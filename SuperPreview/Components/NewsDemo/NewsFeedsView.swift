//
//  NewsFeedsView.swift
//  SuperPreview
//
//  Created by Codex on 2026/10/28.
//

import SwiftUI

/// The watchlist news feed shown inside the host's existing navigation shell.
struct NewsWatchlistFeedView: View {
    private let stories: [NewsStory]
    let onArticle: (String?) -> Void
    private let bottomContentClearance: CGFloat

    init(
        stories: [NewsStory] = NewsStoryCatalog.bundled.stories(in: .watchlist),
        onArticle: @escaping (String?) -> Void = { _ in /* The host supplies article navigation. */ },
        bottomContentClearance: CGFloat = 28
    ) {
        self.stories = stories
        self.onArticle = onArticle
        self.bottomContentClearance = bottomContentClearance
    }

    var body: some View {
        NewsFeedList(
            stories: stories,
            rowStyle: .watchlist,
            identifier: "watchlist",
            onArticle: onArticle,
            bottomContentClearance: bottomContentClearance
        )
    }
}

/// The virtual-asset news feed shown inside the host's existing navigation shell.
struct NewsCryptoFeedView: View {
    private let stories: [NewsStory]
    let onArticle: (String?) -> Void
    private let bottomContentClearance: CGFloat

    init(
        stories: [NewsStory] = NewsStoryCatalog.bundled.stories(in: .crypto),
        onArticle: @escaping (String?) -> Void = { _ in /* The host supplies article navigation. */ },
        bottomContentClearance: CGFloat = 28
    ) {
        self.stories = stories
        self.onArticle = onArticle
        self.bottomContentClearance = bottomContentClearance
    }

    var body: some View {
        NewsFeedList(
            stories: stories,
            rowStyle: .crypto,
            identifier: "crypto",
            onArticle: onArticle,
            bottomContentClearance: bottomContentClearance
        )
    }
}

private struct NewsFeedList: View {
    let stories: [NewsStory]
    let rowStyle: NewsFeedRowStyle
    let identifier: String
    let onArticle: (String?) -> Void
    let bottomContentClearance: CGFloat
    @Environment(\.demoLanguage) private var language

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if stories.isEmpty {
                    NewsFeedEmptyState(style: rowStyle)
                        .containerRelativeFrame(.vertical, alignment: .center)
                } else {
                    ForEach(stories, id: \.id) { story in
                        Button {
                            onArticle(story.id)
                        } label: {
                            NewsArticleRow(story: story, style: rowStyle)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(accessibilityLabel(for: story))
                        .accessibilityHint(language.resolve(NewsDemoCopy.openArticleDetailsHint))
                        .accessibilityIdentifier("news.feed.article.\(story.id)")
                    }
                }

                Color.clear
                    .frame(height: bottomContentClearance)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("news.feed.\(identifier)")
    }

    private func accessibilityLabel(for story: NewsStory) -> String {
        let relatedWatchlistNames = orderedWatchlistRelations(for: story).map {
            language.watchlistName(symbol: $0.symbol, fallback: $0.symbol)
        }
        let values = [story.title.text(in: language)]
            + relatedWatchlistNames
            + [
                story.date.displayText(for: language),
                story.source.name.text(in: language)
            ]
        return values.joined(separator: NewsDemoCopy.accessibilitySeparator(for: language))
    }

    private func orderedWatchlistRelations(for story: NewsStory) -> [NewsWatchlistRelation] {
        let primary = story.relatedWatchlistAssets.filter { $0.role == .primary }
        let secondary = story.relatedWatchlistAssets.filter { $0.role == .secondary }
        var seenSymbols: Set<String> = []
        return (primary + secondary).filter { seenSymbols.insert($0.symbol).inserted }
    }
}

private enum NewsFeedRowStyle {
    case watchlist
    case crypto

    var identifier: String {
        switch self {
        case .watchlist: return "watchlist"
        case .crypto: return "crypto"
        }
    }

    var minimumHeight: CGFloat? {
        switch self {
        case .watchlist: return nil
        case .crypto: return 104
        }
    }

    var pinsMetadataToBottom: Bool {
        minimumHeight != nil
    }

    var showsWatchlistTags: Bool {
        switch self {
        case .watchlist:
            return true
        case .crypto:
            return false
        }
    }
}

private struct NewsArticleRow: View {
    let story: NewsStory
    let style: NewsFeedRowStyle
    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(story.title.text(in: language))
                    .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                    .lineSpacing(8)
                    .foregroundStyle(Color("color-text-30"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: .topLeading)

                if style.showsWatchlistTags, !story.relatedWatchlistAssets.isEmpty {
                    NewsWatchlistTags(relations: story.relatedWatchlistAssets)
                        .padding(.top, 12)
                }

                if style.pinsMetadataToBottom {
                    Spacer(minLength: 12)
                } else {
                    Color.clear
                        .frame(height: 12)
                }

                NewsArticleMetadata(story: story)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            if let imageName = story.image {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 94, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: style.minimumHeight, alignment: .topLeading)
        .background(Color("color-base-1"))
        .contentShape(Rectangle())
    }
}

private struct NewsWatchlistTags: View {
    let relations: [NewsWatchlistRelation]

    var body: some View {
        NewsWatchlistTagFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Array(orderedRelations.enumerated()), id: \.offset) { _, relation in
                NewsWatchlistTag(symbol: relation.symbol)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var orderedRelations: [NewsWatchlistRelation] {
        let primary = relations.filter { $0.role == .primary }
        let secondary = relations.filter { $0.role == .secondary }
        var seenSymbols: Set<String> = []
        return (primary + secondary).filter { seenSymbols.insert($0.symbol).inserted }
    }
}

/// Keeps the Figma-aligned single row at standard sizes and wraps complete tags
/// when Dynamic Type or the available width makes that row too wide.
private struct NewsWatchlistTagFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let rows = makeRows(in: proposal.width ?? .infinity, subviews: subviews)
        let contentWidth = rows.map(\.width).max() ?? 0

        return CGSize(
            width: proposal.width ?? contentWidth,
            height: rows.map(\.height).reduce(0, +)
                + CGFloat(max(rows.count - 1, 0)) * verticalSpacing
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = makeRows(in: bounds.width, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for item in row.items {
                let itemY = y + (row.height - item.size.height) / 2
                subviews[item.index].place(
                    at: CGPoint(x: x, y: itemY),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + horizontalSpacing
            }

            y += row.height + verticalSpacing
        }
    }

    private func makeRows(
        in availableWidth: CGFloat,
        subviews: Subviews
    ) -> [Row] {
        var rows: [Row] = []
        var items: [Item] = []
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        func appendRow() {
            guard !items.isEmpty else { return }
            rows.append(Row(items: items, width: rowWidth, height: rowHeight))
            items = []
            rowWidth = 0
            rowHeight = 0
        }

        for index in subviews.indices {
            let idealSize = subviews[index].sizeThatFits(.unspecified)
            let itemSize: CGSize

            if availableWidth.isFinite, idealSize.width > availableWidth {
                itemSize = subviews[index].sizeThatFits(
                    ProposedViewSize(width: availableWidth, height: nil)
                )
            } else {
                itemSize = idealSize
            }

            let itemWidth = min(itemSize.width, availableWidth)
            let nextWidth = items.isEmpty
                ? itemWidth
                : rowWidth + horizontalSpacing + itemWidth

            if !items.isEmpty, nextWidth > availableWidth {
                appendRow()
            }

            items.append(Item(index: index, size: itemSize))
            rowWidth = items.count == 1
                ? itemWidth
                : rowWidth + horizontalSpacing + itemWidth
            rowHeight = max(rowHeight, itemSize.height)
        }

        appendRow()
        return rows
    }

    private struct Item {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        let items: [Item]
        let width: CGFloat
        let height: CGFloat
    }
}

private struct NewsWatchlistTag: View {
    let symbol: String
    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 4) {
            if let marketAssetName {
                Image(marketAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 10)
                    .accessibilityHidden(true)
            }

            Text(language.watchlistName(symbol: symbol, fallback: symbol))
                .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                .foregroundStyle(Color("color-text-30"))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 16)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Color("color-scale-1"),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .accessibilityHidden(true)
    }

    private var marketAssetName: String? {
        Self.marketAssetNames[symbol]
    }

    private static let marketAssetNames: [String: String] = [
        "09988": "market_hk_allround",
        "00700": "market_hk_allround",
        "01810": "market_hk_allround",
        "03690": "market_hk_allround",
        "03032": "market_hk_allround",
        "300750": "market_sz_allround",
        "002594": "market_sz_allround",
        "600519": "market_sh_allround",
        "600036": "market_sh_allround",
        "600388": "market_sh_allround",
        "513100": "market_sh_allround",
        "NVDA": "market_us_allround",
        "AAPL": "market_us_allround",
        "TSLA": "market_us_allround",
        "MSFT": "market_us_allround",
        "AMZN": "market_us_allround",
        "GOOGL": "market_us_allround",
        "META": "market_us_allround",
        "AVGO": "market_us_allround",
        "AMD": "market_us_allround",
        "NFLX": "market_us_allround",
        "JPM": "market_us_allround",
        "WMT": "market_us_allround",
        "KO": "market_us_allround",
        "DIS": "market_us_allround",
        "HYBL": "market_us_allround",
        "SPCX": "market_us_allround",
        "VOO": "market_us_allround",
        "QQQ": "market_us_allround",
        "BABA": "market_us_allround",
        "FXI": "market_us_allround",
        "LU012376428": "market_MF",
        "BTC/USD": "market_crypto_btc",
        "ETH/USD": "market_crypto_eth"
    ]
}

private struct NewsArticleMetadata: View {
    let story: NewsStory
    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 2) {
            Text(story.date.displayText(for: language))
            Text("·")
            Text(story.source.name.text(in: language))
        }
        .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
        .foregroundStyle(Color("color-text-90"))
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(height: 12)
    }
}

private struct NewsFeedEmptyState: View {
    let style: NewsFeedRowStyle
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(spacing: 8) {
            Text(title.text(in: language))
                .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                .foregroundStyle(Color("color-text-30"))

            Text(message.text(in: language))
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color("color-text-60"))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("news.feed.\(style.identifier).empty")
    }

    private var title: NewsLocalizedText {
        switch style {
        case .watchlist:
            return NewsLocalizedText(
                simplified: "暂无自选资讯",
                traditional: "暫無自選資訊",
                english: "No watchlist news"
            )
        case .crypto:
            return NewsLocalizedText(
                simplified: "暂无虚拟资产资讯",
                traditional: "暫無虛擬資產資訊",
                english: "No crypto news"
            )
        }
    }

    private var message: NewsLocalizedText {
        NewsLocalizedText(
            simplified: "请稍后再试",
            traditional: "請稍後再試",
            english: "Please try again later"
        )
    }
}

struct NewsFeedsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NewsWatchlistFeedView()
                .previewDisplayName("自选")

            NewsCryptoFeedView()
                .previewDisplayName("虚拟资产")
        }
        .previewLayout(.fixed(width: 402, height: 740))
    }
}
