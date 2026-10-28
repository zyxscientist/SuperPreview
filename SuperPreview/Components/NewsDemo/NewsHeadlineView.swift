import SwiftUI

struct NewsHeadlineView: View {
    private static let fallbackImagePattern: [String?] = [
        "news_headline_byd",
        nil,
        "news_headline_tencent",
        nil,
        nil,
        "news_headline_cybertruck",
        nil,
        nil
    ]

    @Environment(\.demoLanguage) private var language
    private let stories: [NewsStory]
    private let onArticle: (String?) -> Void
    private let bottomContentClearance: CGFloat

    init(
        stories: [NewsStory] = NewsStoryCatalog.bundled.stories(in: .headlines),
        onArticle: @escaping (String?) -> Void = { _ in },
        bottomContentClearance: CGFloat = 28
    ) {
        self.stories = stories
        self.onArticle = onArticle
        self.bottomContentClearance = bottomContentClearance
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                if let featuredStory = stories.first {
                    headlineBanner(for: featuredStory)
                        .padding(16)

                    ForEach(articleRows) { row in
                        Button {
                            onArticle(row.story.id)
                        } label: {
                            NewsHeadlineArticleRow(
                                story: row.story,
                                imageName: row.imageName
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(accessibilityLabel(for: row.story))
                        .accessibilityHint(language.resolve(NewsDemoCopy.openArticleDetailsHint))
                        .accessibilityIdentifier("news.headline.article.\(row.story.id)")

                        if row.id != articleRows.last?.id {
                            FullWidthSeparatorView()
                                .frame(height: 0.5)
                        }
                    }
                } else {
                    emptyState
                        .containerRelativeFrame(.vertical, alignment: .center)
                }

                Color.clear
                    .frame(height: bottomContentClearance)
                    .accessibilityHidden(true)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var articleStories: [NewsStory] {
        Array(stories.dropFirst())
    }

    private var articleRows: [NewsHeadlineDisplayStory] {
        articleStories.enumerated().map { index, story in
            NewsHeadlineDisplayStory(
                story: story,
                imageName: story.image
                    ?? Self.fallbackImagePattern[index % Self.fallbackImagePattern.count]
            )
        }
    }

    private func headlineBanner(for story: NewsStory) -> some View {
        Button {
            onArticle(story.id)
        } label: {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    Image(story.image ?? "news_headline_cybertruck")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .accessibilityHidden(true)

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.50326),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(story.title.text(in: language))
                            .modifier(NewsHeadlineFont(size: 16, weight: .regular, lineHeight: 24))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 2) {
                            Text(story.date.displayText(for: language))
                            Text("·")
                            Text(story.source.name.text(in: language))
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            NewsHeadlinePagination()
                        }
                        .modifier(NewsHeadlineFont(size: 10, weight: .regular, lineHeight: 12))
                        .foregroundStyle(.white)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        alignment: .bottomLeading
                    )
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: story))
        .accessibilityHint(language.resolve(NewsDemoCopy.openArticleDetailsHint))
        .accessibilityIdentifier("news.headline.banner.\(story.id)")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(NewsHeadlineEmptyCopy.title.text(in: language))
                .modifier(NewsHeadlineFont(size: 16, weight: .medium, lineHeight: 24))
                .foregroundStyle(Color("color-text-30"))

            Text(NewsHeadlineEmptyCopy.message.text(in: language))
                .modifier(NewsHeadlineFont(size: 14, weight: .regular, lineHeight: 20))
                .foregroundStyle(Color("color-text-60"))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("news.headline.empty")
    }

    private func accessibilityLabel(for story: NewsStory) -> String {
        let values = [
            story.title.text(in: language),
            story.date.displayText(for: language),
            story.source.name.text(in: language)
        ]
        return values.joined(separator: NewsDemoCopy.accessibilitySeparator(for: language))
    }
}

private struct NewsHeadlineArticleRow: View {
    let story: NewsStory
    let imageName: String?
    @Environment(\.demoLanguage) private var language

    var body: some View {
        Group {
            if let imageName {
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        Text(story.title.text(in: language))
            .modifier(NewsHeadlineFont(size: 16, weight: .medium, lineHeight: 24))
            .foregroundStyle(Color("color-text-30"))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadata: some View {
        HStack(spacing: 2) {
            Text(story.date.displayText(for: language))
            Text("·")
            Text(story.source.name.text(in: language))
        }
        .modifier(NewsHeadlineFont(size: 12, weight: .regular, lineHeight: 12))
        .foregroundStyle(Color("color-text-90"))
        .lineLimit(1)
    }
}

private struct NewsHeadlineDisplayStory: Identifiable {
    let story: NewsStory
    let imageName: String?

    var id: String { story.id }
}

private enum NewsHeadlineEmptyCopy {
    static let title = NewsLocalizedText(
        simplified: "暂无要闻",
        traditional: "暫無要聞",
        english: "No headlines available"
    )

    static let message = NewsLocalizedText(
        simplified: "请稍后再试",
        traditional: "請稍後再試",
        english: "Please try again later"
    )
}

private struct NewsHeadlinePagination: View {
    var body: some View {
        HStack(spacing: 4) {
            indicator(width: 8, color: Color("color-text-30"))
            indicator(width: 3, color: Color("color-scale-4"))
            indicator(width: 3, color: Color("color-scale-4"))
            indicator(width: 3, color: .white)
        }
        .accessibilityHidden(true)
    }

    private func indicator(width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: 2)
    }
}

private struct NewsHeadlineFont: ViewModifier {
    let size: CGFloat
    let weight: CustomFontModifier.CustomFont
    let lineHeight: CGFloat

    func body(content: Content) -> some View {
        content.modifier(
            CustomFontModifier(
                size: size,
                font: weight,
                lineHeight: lineHeight
            )
        )
    }
}
