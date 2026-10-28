//
//  NewsLiveView.swift
//  SuperPreview
//
//  Created by Codex on 2026/10/28.
//

import Foundation
import SwiftUI

/// The 7x24 content feed shown inside the host's existing navigation shell.
struct NewsLiveView: View {
    private let onArticle: (String?) -> Void
    private let bottomContentClearance: CGFloat

    @State private var selectedFilter = NewsLiveFilter.all
    @Environment(\.demoLanguage) private var language

    init(
        onArticle: @escaping (String?) -> Void = { _ in /* The host supplies article navigation. */ },
        bottomContentClearance: CGFloat = 28
    ) {
        self.onArticle = onArticle
        self.bottomContentClearance = bottomContentClearance
    }

    var body: some View {
        VStack(spacing: 0) {
            NewsLiveFilterBar(selection: $selectedFilter)

            ScrollView {
                VStack(spacing: 0) {
                    dateHeader

                    if filteredStories.isEmpty {
                        emptyState
                    } else {
                        NewsLiveTimeline(
                            stories: filteredStories,
                            onArticle: onArticle
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }

                    Color.clear
                        .frame(height: bottomContentClearance)
                        .accessibilityHidden(true)
                }
            }
            .id(selectedFilter)
            .scrollIndicators(.hidden)
        }
        .accessibilityIdentifier("news.live.page")
    }

    @ViewBuilder
    private var dateHeader: some View {
        if let firstStory = filteredStories.first {
            Text(firstStory.date.displayText(for: language))
                .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 24))
                .foregroundStyle(Color("color-text-30"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(language.newsLiveEmptyTitle)
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                .foregroundStyle(Color("color-text-30"))

            Text(language.newsLiveEmptyMessage)
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundStyle(Color("color-text-60"))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
        .accessibilityElement(children: .combine)
    }

    private var filteredStories: [NewsStory] {
        NewsStoryCatalog.bundled
            .stories(in: .live)
            .filter { $0.categories.contains(selectedFilter.category) }
    }
}

private struct NewsLiveFilterBar: View {
    @Binding var selection: NewsLiveFilter
    @Environment(\.demoLanguage) private var language

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(NewsLiveFilter.allCases) { filter in
                    Button {
                        selection = filter
                    } label: {
                        filterLabel(filter)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == filter ? .isSelected : [])
                    .accessibilityIdentifier("news.live.category.\(filter.rawValue)")
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 48)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("news.live.categoryBar")
    }

    private func filterLabel(_ filter: NewsLiveFilter) -> some View {
        let isSelected = selection == filter
        let title = filter.title(in: language)

        return Text(title)
            .modifier(
                CustomFontModifier(
                    size: 14,
                    font: isSelected ? .bold : .regular,
                    lineHeight: 20
                )
            )
            .foregroundStyle(Color(isSelected ? "color-text-30" : "color-text-60"))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(height: 20)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(isSelected ? "color-base-1" : "color-scale-1"))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color("color-base-r") : .clear,
                        lineWidth: 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityLabel(title)
    }
}

private struct NewsLiveTimeline: View {
    let stories: [NewsStory]
    let onArticle: (String?) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            NewsLiveTimelineRule()
                .accessibilityHidden(true)

            VStack(spacing: 32) {
                ForEach(stories, id: \.id) { story in
                    NewsLiveArticleRow(story: story, onArticle: onArticle)
                }
            }
        }
    }
}

private struct NewsLiveTimelineRule: View {
    var body: some View {
        Image("news-live-timeline-line")
            .frame(width: 620, height: 1.50002)
            .rotationEffect(.degrees(90))
            .frame(width: 1.50002, height: 620)
            .offset(x: 4.25, y: 16)
    }
}

private struct NewsLiveArticleRow: View {
    let story: NewsStory
    let onArticle: (String?) -> Void
    @Environment(\.demoLanguage) private var language

    var body: some View {
        let title = story.title.text(in: language)
        let summary = story.summary.text(in: language)
        let sourceName = story.source.name.text(in: language)
        let publishedDate = story.date.displayText(for: language)

        HStack(alignment: .top, spacing: 8) {
            Image("news-live-timeline-node")
                .frame(width: 10, height: 13)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(publishedDate)
                        .modifier(CustomFontModifier(size: 12, font: .medium, lineHeight: 16))
                        .foregroundStyle(Color("color-text-90"))
                        .frame(height: 16)
                        .fixedSize(horizontal: true, vertical: false)

                    Text("·")
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundStyle(Color("color-text-60"))
                        .frame(height: 16)

                    Text(sourceName)
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundStyle(Color("color-text-60"))
                        .lineLimit(1)
                        .frame(height: 16)

                    Spacer(minLength: 0)

                    ShareLink(item: title) {
                        Image("share-Right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(language.newsLiveShareAccessibilityLabel(articleTitle: title))
                    .accessibilityIdentifier("news.live.share.\(story.id)")
                }

                Button {
                    onArticle(story.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .modifier(CustomFontModifier(size: 18, font: .medium, lineHeight: 28))
                            .foregroundStyle(Color("color-text-30"))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(summary)
                                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                                .foregroundStyle(Color("color-text-30"))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    language.newsLiveArticleAccessibilityLabel(
                        title: title,
                        date: publishedDate,
                        source: sourceName
                    )
                )
                .accessibilityHint(language.newsLiveArticleAccessibilityHint)
                .accessibilityIdentifier("news.live.article.\(story.id)")

                Link(destination: story.source.url) {
                    Text(language.newsLiveViewOriginalTitle)
                        .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                        .foregroundStyle(Color("color-brand-blue"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.newsLiveSourceLinkAccessibilityLabel(sourceName: sourceName))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum NewsLiveFilter: String, CaseIterable, Identifiable {
    case all
    case headlines
    case hongKong
    case usStocks
    case aShares
    case crypto
    case research

    var id: Self { self }

    var category: NewsCategory {
        switch self {
        case .all: return .live
        case .headlines: return .headlines
        case .hongKong: return .hongKong
        case .usStocks: return .usStocks
        case .aShares: return .aShares
        case .crypto: return .crypto
        case .research: return .research
        }
    }

    func title(in language: DemoLanguage) -> String {
        switch self {
        case .all:
            switch language {
            case .simplifiedChinese, .traditionalChinese: return "全部"
            case .english: return "All"
            }
        case .headlines:
            switch language {
            case .simplifiedChinese: return "要闻"
            case .traditionalChinese: return "要聞"
            case .english: return "Headlines"
            }
        case .hongKong:
            switch language {
            case .simplifiedChinese, .traditionalChinese: return "港股"
            case .english: return "Hong Kong"
            }
        case .usStocks:
            switch language {
            case .simplifiedChinese, .traditionalChinese: return "美股"
            case .english: return "US Stocks"
            }
        case .aShares:
            switch language {
            case .simplifiedChinese, .traditionalChinese: return "A股"
            case .english: return "A-Shares"
            }
        case .crypto:
            switch language {
            case .simplifiedChinese: return "虚拟资产"
            case .traditionalChinese: return "虛擬資產"
            case .english: return "Virtual Assets"
            }
        case .research:
            switch language {
            case .simplifiedChinese: return "研报"
            case .traditionalChinese: return "研報"
            case .english: return "Research"
            }
        }
    }
}

private extension DemoLanguage {
    var newsLiveEmptyTitle: String {
        switch self {
        case .simplifiedChinese: return "暂无资讯"
        case .traditionalChinese: return "暫無資訊"
        case .english: return "No news available"
        }
    }

    var newsLiveEmptyMessage: String {
        switch self {
        case .simplifiedChinese: return "切换分类查看其他内容"
        case .traditionalChinese: return "切換分類查看其他內容"
        case .english: return "Try another category."
        }
    }

    func newsLiveShareAccessibilityLabel(articleTitle: String) -> String {
        switch self {
        case .simplifiedChinese: return "分享资讯，\(articleTitle)"
        case .traditionalChinese: return "分享資訊，\(articleTitle)"
        case .english: return "Share news: \(articleTitle)"
        }
    }

    var newsLiveViewOriginalTitle: String {
        switch self {
        case .simplifiedChinese, .traditionalChinese: return "查看原文"
        case .english: return "View original"
        }
    }

    func newsLiveSourceLinkAccessibilityLabel(sourceName: String) -> String {
        switch self {
        case .simplifiedChinese: return "在\(sourceName)查看原文"
        case .traditionalChinese: return "在\(sourceName)查看原文"
        case .english: return "View the original article at \(sourceName)"
        }
    }

    func newsLiveArticleAccessibilityLabel(title: String, date: String, source: String) -> String {
        switch self {
        case .simplifiedChinese:
            return "\(title)，\(date)，来源：\(source)"
        case .traditionalChinese:
            return "\(title)，\(date)，來源：\(source)"
        case .english:
            return "\(title), \(date), source: \(source)"
        }
    }

    var newsLiveArticleAccessibilityHint: String {
        switch self {
        case .simplifiedChinese: return "打开资讯详情。"
        case .traditionalChinese: return "開啟資訊詳情。"
        case .english: return "Open news details."
        }
    }
}

struct NewsLiveView_Previews: PreviewProvider {
    static var previews: some View {
        NewsLiveView()
            .previewLayout(.fixed(width: 402, height: 740))
    }
}
