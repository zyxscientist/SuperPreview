//
//  NewsTopicsView.swift
//  SuperPreview
//

import SwiftUI

private enum NewsTopicsCopy {
    static let emptyTitle = NewsLocalizedText(
        simplified: "暂无相关新闻",
        traditional: "暫無相關新聞",
        english: "No matching stories"
    )

    static let emptyMessage = NewsLocalizedText(
        simplified: "该专题暂未收录符合条件的文章。",
        traditional: "該專題暫未收錄符合條件的文章。",
        english: "There are no stories matching this topic yet."
    )
}

/// The topics feed shown inside the host's existing news navigation shell.
struct NewsTopicsView: View {
    @Environment(\.demoLanguage) private var language
    private let onArticle: (String?) -> Void
    private let bottomContentClearance: CGFloat

    private var stories: [NewsStory] {
        NewsStoryCatalog.bundled.stories(in: .topics)
    }

    init(
        onArticle: @escaping (String?) -> Void = { _ in /* The host supplies article navigation. */ },
        bottomContentClearance: CGFloat = 28
    ) {
        self.onArticle = onArticle
        self.bottomContentClearance = bottomContentClearance
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                featuredTopics

                LazyVStack(spacing: 0) {
                    ForEach(stories, id: \.id) { story in
                        Button {
                            onArticle(story.id)
                        } label: {
                            NewsStoryRow(story: story)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            newsStoryAccessibilityLabel(story, language: language)
                        )
                        .accessibilityHint(language.resolve(NewsDemoCopy.openArticleDetailsHint))
                        .accessibilityIdentifier("news.topics.article.\(story.id)")
                    }
                }

                if stories.isEmpty {
                    NewsTopicsEmptyState()
                }

                Color.clear
                    .frame(height: bottomContentClearance)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("news.topics")
    }

    private var featuredTopics: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(language.resolve(NewsDemoCopy.featuredTopics))
                .font(.custom("PlusJakartaSans-Medium", size: 18, relativeTo: .headline))
                .foregroundStyle(Color("color-text-30"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Self.featured) { topic in
                        NavigationLink {
                            NewsTopicArticleListView(topic: topic)
                        } label: {
                            NewsTopicCard(topic: topic)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            [topic.title.text(in: language), topic.subtitle.text(in: language)]
                                .joined(
                                    separator: NewsDemoCopy.accessibilitySeparator(
                                        for: language
                                    )
                                )
                        )
                        .accessibilityHint(
                            NewsDemoCopy.openTopicArticleListHint(
                                topicTitle: topic.title.text(in: language),
                                language: language
                            )
                        )
                        .accessibilityIdentifier("news.topics.featured.\(topic.id)")
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .padding(.bottom, 16)
        }
    }

    private static let featured: [NewsTopic] = [
        NewsTopic(
            id: "ipo-observation",
            title: NewsLocalizedText(
                simplified: "新股观察",
                traditional: "新股觀察",
                english: "IPO Watch"
            ),
            subtitle: NewsLocalizedText(
                simplified: "IPO动态信息汇总",
                traditional: "IPO動態資訊彙總",
                english: "Latest IPO activity"
            ),
            category: .ipoObservation,
            imageName: "NewsTopicObservation"
        ),
        NewsTopic(
            id: "price-movement",
            title: NewsLocalizedText(
                simplified: "股价异动",
                traditional: "股價異動",
                english: "Price Moves"
            ),
            subtitle: NewsLocalizedText(
                simplified: "实时追踪股价异常波动信号",
                traditional: "即時追蹤股價異常波動訊號",
                english: "Track unusual price movements in real time"
            ),
            category: .priceMovement,
            imageName: "NewsTopicPriceMovement"
        ),
        NewsTopic(
            id: "research",
            title: NewsLocalizedText(
                simplified: "大行投研",
                traditional: "大行投研",
                english: "Institutional Research"
            ),
            subtitle: NewsLocalizedText(
                simplified: "明星研究机构最新内参",
                traditional: "明星研究機構最新內參",
                english: "Latest reports from leading research firms"
            ),
            category: .research,
            imageName: "NewsTopicResearch"
        )
    ]
}

private struct NewsTopicCard: View {
    @Environment(\.demoLanguage) private var language

    let topic: NewsTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(topic.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 170, height: 95)
                .clipped()
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(language.resolve(topic.title))
                    .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                    .foregroundStyle(Color("color-text-30"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(language.resolve(topic.subtitle))
                    .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color("color-text-60"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 12)
        .frame(width: 170, height: 164, alignment: .topLeading)
        .background(Color("color-scale-1"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private func newsStoryAccessibilityLabel(
    _ story: NewsStory,
    language: DemoLanguage
) -> String {
    [
        story.title.text(in: language),
        story.date.displayText(for: language),
        story.source.name.text(in: language)
    ]
    .joined(separator: NewsDemoCopy.accessibilitySeparator(for: language))
}

private struct NewsStoryRow: View {
    @Environment(\.demoLanguage) private var language

    let story: NewsStory

    var body: some View {
        Group {
            if let imageName = story.image {
                HStack(alignment: .top, spacing: 16) {
                    textContent
                        .frame(maxWidth: .infinity, minHeight: 72, maxHeight: 72, alignment: .topLeading)

                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 94, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityHidden(true)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    title
                    metadata
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 104, maxHeight: 104, alignment: .topLeading)
        .contentShape(Rectangle())
        .background(Color("color-base-1"))
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            Spacer(minLength: 0)
            metadata
        }
    }

    private var title: some View {
        Text(language.resolve(story.title))
            .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
            .lineSpacing(8)
            .foregroundStyle(Color("color-text-30"))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadata: some View {
        HStack(spacing: 2) {
            Text(story.date.displayText(for: language))
            Text("·")
            Text(language.resolve(story.source.name))
        }
        .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
        .foregroundStyle(Color("color-text-90"))
        .lineLimit(1)
    }
}

private struct NewsTopicArticleListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var language

    let topic: NewsTopic

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                hero
                articleSheet
                    .padding(.top, 209)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color("color-base-1"))
        .ignoresSafeArea(edges: .top)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("NewsDemoNavBack36")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(language.resolve(NewsDemoCopy.back))
            }
        }
        .accessibilityIdentifier("news.topics.detail.\(topic.id)")
    }

    private var hero: some View {
        GeometryReader { proxy in
            Image(topic.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: 225)
                .clipped()
        }
        .frame(height: 225)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.resolve(topic.title))
                    .font(.custom("PlusJakartaSans-Medium", size: 30, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(language.resolve(topic.subtitle))
                    .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 39)
        }
        .accessibilityElement(children: .combine)
    }

    private var articleSheet: some View {
        LazyVStack(spacing: 0) {
            Color.clear
                .frame(height: 16)

            ForEach(stories, id: \.id) { story in
                NavigationLink {
                    NewsDemoDetailView(articleID: story.id)
                } label: {
                    NewsStoryRow(story: story)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    newsStoryAccessibilityLabel(story, language: language)
                )
                .accessibilityHint(language.resolve(NewsDemoCopy.openArticleDetailsHint))
                .accessibilityIdentifier("news.topics.detail.article.\(story.id)")
            }

            if stories.isEmpty {
                NewsTopicsEmptyState()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color("color-base-1"))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16,
                style: .continuous
            )
        )
    }

    private var stories: [NewsStory] {
        NewsStoryCatalog.bundled
            .stories(in: .topics)
            .filter { $0.categories.contains(topic.category) }
    }
}

private struct NewsTopic: Identifiable {
    let id: String
    let title: NewsLocalizedText
    let subtitle: NewsLocalizedText
    let category: NewsCategory
    let imageName: String
}

private struct NewsTopicsEmptyState: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(spacing: 8) {
            Text(language.resolve(NewsTopicsCopy.emptyTitle))
                .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                .foregroundStyle(Color("color-text-30"))

            Text(language.resolve(NewsTopicsCopy.emptyMessage))
                .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                .foregroundStyle(Color("color-text-60"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
        .accessibilityElement(children: .combine)
    }
}

struct NewsTopicsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewsTopicsView()
        }
        .previewLayout(.fixed(width: 402, height: 740))
    }
}
