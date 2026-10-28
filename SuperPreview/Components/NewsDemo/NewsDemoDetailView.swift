//
//  NewsDemoDetailView.swift
//  SuperPreview
//

import Foundation
import SwiftUI

struct NewsDemoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var language
    @State private var isFavorite = false
    private let articleID: String?
    private let catalog: NewsStoryCatalog
    private let showsRelatedStocks: Bool

    private var pageBackground: Color { Color("color-base-1") }
    private var primaryText: Color { Color("color-text-30") }
    private var secondaryText: Color { Color("color-text-60") }
    private var tertiaryText: Color { Color("color-text-90") }
    private var brandBlue: Color { Color("color-brand-blue") }
    private var quietFill: Color { Color("color-scale-1") }

    init(articleID: String) {
        self.articleID = articleID
        self.catalog = .bundled
        self.showsRelatedStocks = false
    }

    init(showsRelatedStocks: Bool = true) {
        self.articleID = nil
        self.catalog = .bundled
        self.showsRelatedStocks = showsRelatedStocks
    }

    var body: some View {
        ScrollView {
            articleContent
            .frame(maxWidth: 402, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 20)
        }
        .scrollIndicators(.hidden)
        .background(pageBackground)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(pageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                        .foregroundStyle(primaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.resolve(NewsDemoCopy.back))
            }

            ToolbarItem(placement: .principal) {
                Text(language.resolve(NewsDemoCopy.detail))
                    .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                    .foregroundStyle(primaryText)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isFavorite.toggle()
                } label: {
                    Image(
                        isFavorite
                            ? "NewsDemoFavoriteSelected36"
                            : "NewsDemoFavorite36"
                    )
                        .renderingMode(isFavorite ? .original : .template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(primaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isFavorite
                        ? language.resolve(NewsDemoCopy.removeFavorite)
                        : language.resolve(NewsDemoCopy.addFavorite)
                )
                .accessibilityValue(
                    isFavorite
                        ? language.resolve(NewsDemoCopy.favorited)
                        : language.resolve(NewsDemoCopy.notFavorited)
                )
            }
        }
    }

    @ViewBuilder
    private var articleContent: some View {
        if let articleID {
            if let story = catalog.story(id: articleID) {
                storyContent(story)
            } else {
                unavailableContent
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                metadataSection
                if showsRelatedStocks {
                    relatedStocksSection
                }
                writerSection
                summarySection
                articleSection
            }
        }
    }

    private func storyContent(_ story: NewsStory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(language.resolve(story.title))
                .font(.custom("PlusJakartaSans-Medium", size: 24, relativeTo: .title2))
                .foregroundStyle(primaryText)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            storyMetadataSection(story)
            storySummarySection(story)

            if let image = story.image {
                storyImageSection(image)
            }

            storyBodySection(story)
        }
        .accessibilityIdentifier("news.detail.\(story.id)")
    }

    private func storyMetadataSection(_ story: NewsStory) -> some View {
        HStack(spacing: 10) {
            Text(story.date.displayText(for: language))
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundStyle(tertiaryText)
                .lineLimit(1)

            Spacer(minLength: 0)

            Link(destination: story.source.url) {
                HStack(spacing: 4) {
                    Text(language.resolve(story.source.name))
                        .lineLimit(1)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundStyle(brandBlue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(language.resolve(story.source.name))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func storySummarySection(_ story: NewsStory) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(language.resolve(NewsDemoCopy.guide))
                .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                .foregroundStyle(primaryText)

            summaryParagraph(story.summary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(quietFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func storyImageSection(_ image: String) -> some View {
        GeometryReader { proxy in
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .aspectRatio(370.0 / 208.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .accessibilityHidden(true)
    }

    private func storyBodySection(_ story: NewsStory) -> some View {
        let paragraphs = localizedParagraphs(story.body)

        return VStack(alignment: .leading, spacing: 20) {
            ForEach(paragraphs.indices, id: \.self) { index in
                Text(paragraphs[index])
                    .articleBodyStyle()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func localizedParagraphs(_ content: NewsLocalizedText) -> [String] {
        language
            .resolve(content)
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var unavailableContent: some View {
        VStack(spacing: 12) {
            Text(unavailableTitle)
                .font(.custom("PlusJakartaSans-Medium", size: 20, relativeTo: .title3))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)

            Text(unavailableMessage)
                .font(.custom("PlusJakartaSans-Regular", size: 15, relativeTo: .body))
                .foregroundStyle(secondaryText)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 72)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("news.detail.unavailable")
    }

    private var unavailableTitle: String {
        switch language {
        case .simplifiedChinese:
            return "内容暂不可用"
        case .traditionalChinese:
            return "內容暫不可用"
        case .english:
            return "Content unavailable"
        }
    }

    private var unavailableMessage: String {
        if catalog.loadIssue != nil {
            switch language {
            case .simplifiedChinese:
                return "新闻数据暂时无法加载，请稍后重试。"
            case .traditionalChinese:
                return "新聞資料暫時無法載入，請稍後再試。"
            case .english:
                return "News data could not be loaded. Please try again later."
            }
        }

        switch language {
        case .simplifiedChinese:
            return "找不到这篇新闻，或它已不可用。"
        case .traditionalChinese:
            return "找不到這篇新聞，或它已不可用。"
        case .english:
            return "This article could not be found or is no longer available."
        }
    }

    private var titleSection: some View {
        Text(language.resolve(NewsDemoCopy.AppleCarStory.title))
            .font(.custom("PlusJakartaSans-Medium", size: 24, relativeTo: .title2))
            .foregroundStyle(primaryText)
            .lineSpacing(6)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }

    private var metadataSection: some View {
        HStack(spacing: 3) {
            Text(language.resolve(NewsDemoCopy.AppleCarStory.exclusiveTag))
                .font(.custom("PlusJakartaSans-Regular", size: 10, relativeTo: .caption2))
                .foregroundStyle(brandBlue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(brandBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 2, style: .continuous))

            Text("2026/04/12")
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundStyle(tertiaryText)

            Text("14:20")
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundStyle(tertiaryText)

            Text(language.resolve(NewsDemoCopy.AppleCarStory.researchSource))
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundStyle(brandBlue)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.9)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var relatedStocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Self.relatedStocks) { stock in
                NewsDemoRelatedStockRow(stock: stock)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var writerSection: some View {
        Text(
            language.resolve(NewsDemoCopy.authorPrefix)
                + language.resolve(NewsDemoCopy.AppleCarStory.authorNames)
        )
            .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
            .foregroundStyle(tertiaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(language.resolve(NewsDemoCopy.guide))
                .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                .foregroundStyle(primaryText)

            summaryParagraph(NewsDemoCopy.AppleCarStory.summary1)
            summaryParagraph(NewsDemoCopy.AppleCarStory.summary2)
            summaryParagraph(NewsDemoCopy.AppleCarStory.summary3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(quietFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    private var articleSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            articleHeading(NewsDemoCopy.AppleCarStory.sectionHeading1)

            Text(language.resolve(NewsDemoCopy.AppleCarStory.body1))
                .articleBodyStyle()

            articleImage

            articleHeading(NewsDemoCopy.AppleCarStory.sectionHeading2)

            Text(language.resolve(NewsDemoCopy.AppleCarStory.body2))
                .articleBodyStyle()

            quoteSection

            valuationParagraph
                .articleBodyStyle()

            disclaimerSection
        }
        .padding(.horizontal, 16)
    }

    private func summaryParagraph(_ content: NewsLocalizedText) -> some View {
        Text(language.resolve(content))
            .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
            .foregroundStyle(primaryText)
            .lineSpacing(5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func articleHeading(_ content: NewsLocalizedText) -> some View {
        Text(language.resolve(content))
            .font(.custom("PlusJakartaSans-Medium", size: 22, relativeTo: .title2))
            .foregroundStyle(primaryText)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var articleImage: some View {
        GeometryReader { proxy in
            ZStack {
                Image("NewsDemoDetailHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.50326),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .aspectRatio(370.0 / 168.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel(language.resolve(NewsDemoCopy.articleImageDescription))
    }

    private var quoteSection: some View {
        HStack(alignment: .center, spacing: 10) {
            Rectangle()
                .fill(primaryText)
                .frame(width: 3)

            Text(language.resolve(NewsDemoCopy.AppleCarStory.quote))
                .font(.custom("PlusJakartaSans-Regular", size: 20, relativeTo: .title3))
                .foregroundStyle(secondaryText)
                .lineSpacing(7)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 20)
    }

    private var valuationParagraph: Text {
        Text(language.resolve(NewsDemoCopy.AppleCarStory.valuationPrefix))
            + Text(language.resolve(NewsDemoCopy.AppleCarStory.valuationDCFModel))
                .foregroundColor(brandBlue)
            + Text(language.resolve(NewsDemoCopy.AppleCarStory.valuationSuffix))
    }

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            (
                Text(language.resolve(NewsDemoCopy.sourcePrefix))
                    + Text(language.resolve(NewsDemoCopy.AppleCarStory.sourceName))
                        .foregroundColor(brandBlue)
                    + Text(" " + language.resolve(NewsDemoCopy.articleCopyright))
            )
                .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                .foregroundColor(primaryText)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)

            Text(language.resolve(NewsDemoCopy.disclaimer))
                .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                .foregroundStyle(tertiaryText)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(quietFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.vertical, 20)
    }

    private static let relatedStocks: [NewsDemoRelatedStock] = [
        .init(
            name: "摩根史丹利(MS.US)",
            movement: .loss,
            price: "100.123",
            change: "-1.02%"
        ),
        .init(
            name: "特斯拉(TSLA.US)",
            movement: .gain,
            price: "600.123",
            change: "+1.82%"
        ),
        .init(
            name: "BOSS直聘(BZ.US)",
            movement: .gain,
            price: "33.100",
            change: "+1.82%",
            afterHoursPrice: "33.200",
            afterHoursChange: "+0.01%"
        ),
        .init(
            name: "富途控股(FUTU)",
            movement: .gain,
            price: "33.100",
            change: "+1.82%",
            afterHoursPrice: "33.200",
            afterHoursChange: "+0.01%"
        ),
        .init(
            name: "伯克希尔-Class A(BRK. A)",
            movement: .gain,
            price: "42645.100",
            change: "+1.82%",
            afterHoursPrice: "426045.200",
            afterHoursChange: "+0.01%"
        )
    ]
}

private struct NewsDemoRelatedStock: Identifiable {
    enum Movement {
        case gain
        case loss

        var colorName: String {
            switch self {
            case .gain: return "color-utility3-red"
            case .loss: return "color-utility3-green"
            }
        }
    }

    let name: String
    let movement: Movement
    let price: String
    let change: String
    let afterHoursPrice: String?
    let afterHoursChange: String?

    var id: String { name }

    init(
        name: String,
        movement: Movement,
        price: String,
        change: String,
        afterHoursPrice: String? = nil,
        afterHoursChange: String? = nil
    ) {
        self.name = name
        self.movement = movement
        self.price = price
        self.change = change
        self.afterHoursPrice = afterHoursPrice
        self.afterHoursChange = afterHoursChange
    }
}

private struct NewsDemoRelatedStockRow: View {
    @Environment(\.demoLanguage) private var language
    let stock: NewsDemoRelatedStock

    private var movementColor: Color {
        Color(stock.movement.colorName)
    }

    private var tertiaryText: Color {
        Color("color-text-60")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(
                NewsDemoCopy.AppleCarStory.relatedStockName(
                    for: stock.name,
                    language: language
                )
            )
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundStyle(Color("color-brand-blue"))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: 16, alignment: .topLeading)

            if let afterHoursPrice = stock.afterHoursPrice,
               let afterHoursChange = stock.afterHoursChange {
                quoteColumn(price: stock.price, change: stock.change)
                quoteColumn(price: afterHoursPrice, change: afterHoursChange)
            } else {
                quoteValue(stock.price)
                quoteValue(stock.change)
            }
        }
        .frame(maxWidth: 370, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func quoteColumn(price: String, change: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            quoteValue(price)

            HStack(spacing: 4) {
                Text(change)
                Text(language.resolve(NewsDemoCopy.postMarket))
            }
            .modifier(CustomFontModifier(size: 11, font: .regular, lineHeight: 12))
            .foregroundStyle(tertiaryText)
            .lineLimit(1)
            .frame(width: 80, height: 12, alignment: .trailing)
        }
        .frame(width: 80, alignment: .trailing)
    }

    private func quoteValue(_ value: String) -> some View {
        Text(value)
            .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
            .foregroundStyle(movementColor)
            .lineLimit(1)
            .frame(width: 80, height: 16, alignment: .trailing)
    }
}

private extension View {
    func articleBodyStyle() -> some View {
        self
            .font(.custom("PlusJakartaSans-Regular", size: 18, relativeTo: .body))
            .foregroundStyle(Color("color-text-30"))
            .lineSpacing(6)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NewsDemoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewsDemoDetailView()
        }

        NavigationStack {
            NewsDemoDetailView(showsRelatedStocks: false)
        }
    }
}
