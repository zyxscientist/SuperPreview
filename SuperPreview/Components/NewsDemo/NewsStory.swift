//
//  NewsStory.swift
//  SuperPreview
//

import Foundation

enum NewsCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case headlines
    case live
    case watchlist
    case topics
    case crypto
    case hongKong
    case usStocks
    case aShares
    case research
    case ipoObservation
    case priceMovement
}

struct NewsSource: Codable, Hashable, Sendable {
    let name: NewsLocalizedText
    let url: URL
}

struct NewsDate: Codable, Hashable, Sendable {
    enum Precision: String, Codable, Hashable, Sendable {
        case day
    }

    let publishedAt: String
    let precision: Precision

    init(publishedAt: String, precision: Precision = .day) {
        self.publishedAt = publishedAt
        self.precision = precision
    }

    var parsedPublishedAt: Date? {
        Self.parseDay(publishedAt)
    }

    func displayText(for language: DemoLanguage) -> String {
        guard let date = parsedPublishedAt else { return publishedAt }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: language == .english ? "en_US" : language.rawValue)
        formatter.dateFormat = language == .english ? "MMM d, yyyy" : "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    private enum CodingKeys: String, CodingKey {
        case publishedAt
        case precision
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let publishedAt = try container.decode(String.self, forKey: .publishedAt)
        let precision = try container.decode(Precision.self, forKey: .precision)

        guard Self.parseDay(publishedAt) != nil else {
            throw DecodingError.dataCorruptedError(
                forKey: .publishedAt,
                in: container,
                debugDescription: "Expected publishedAt in YYYY-MM-DD format."
            )
        }

        self.init(publishedAt: publishedAt, precision: precision)
    }

    private static func parseDay(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false

        guard let date = formatter.date(from: value),
              formatter.string(from: date) == value else {
            return nil
        }
        return date
    }
}

enum NewsWatchlistRelationRole: String, Codable, Hashable, Sendable {
    case primary
    case secondary
}

struct NewsWatchlistRelation: Codable, Hashable, Sendable {
    let symbol: String
    let role: NewsWatchlistRelationRole
}

struct NewsStory: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: NewsLocalizedText
    let summary: NewsLocalizedText
    let body: NewsLocalizedText
    let source: NewsSource
    let date: NewsDate
    let categories: Set<NewsCategory>
    let relatedWatchlistAssets: [NewsWatchlistRelation]
    let image: String?

    init(
        id: String,
        title: NewsLocalizedText,
        summary: NewsLocalizedText,
        body: NewsLocalizedText,
        source: NewsSource,
        date: NewsDate,
        categories: Set<NewsCategory>,
        relatedWatchlistAssets: [NewsWatchlistRelation] = [],
        image: String?
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.body = body
        self.source = source
        self.date = date
        self.categories = categories
        self.relatedWatchlistAssets = relatedWatchlistAssets
        self.image = image
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case body
        case source
        case date
        case categories
        case relatedWatchlistAssets
        case image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(NewsLocalizedText.self, forKey: .title)
        summary = try container.decode(NewsLocalizedText.self, forKey: .summary)
        body = try container.decode(NewsLocalizedText.self, forKey: .body)
        source = try container.decode(NewsSource.self, forKey: .source)
        date = try container.decode(NewsDate.self, forKey: .date)
        categories = try container.decode(Set<NewsCategory>.self, forKey: .categories)
        relatedWatchlistAssets = try container.decodeIfPresent(
            [NewsWatchlistRelation].self,
            forKey: .relatedWatchlistAssets
        ) ?? []
        image = try container.decodeIfPresent(String.self, forKey: .image)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(body, forKey: .body)
        try container.encode(source, forKey: .source)
        try container.encode(date, forKey: .date)
        try container.encode(categories, forKey: .categories)
        try container.encode(relatedWatchlistAssets, forKey: .relatedWatchlistAssets)
        try container.encodeIfPresent(image, forKey: .image)
    }
}

struct NewsStoryCatalog: Sendable {
    enum LoadIssue: Error, Equatable, Sendable, CustomStringConvertible {
        case resourceNotFound(String)
        case unreadableResource(String)
        case decodingFailed(String)
        case duplicateID(String)

        var description: String {
            switch self {
            case .resourceNotFound(let name):
                return "News story resource \(name) was not found."
            case .unreadableResource(let message):
                return "News story resource could not be read: \(message)"
            case .decodingFailed(let message):
                return "News story resource could not be decoded: \(message)"
            case .duplicateID(let id):
                return "News story resource contains duplicate id: \(id)"
            }
        }
    }

    let stories: [NewsStory]
    let loadIssue: LoadIssue?

    private let storiesByID: [NewsStory.ID: NewsStory]

    static let bundled: NewsStoryCatalog = loadBundled()

    var isEmpty: Bool {
        stories.isEmpty
    }

    func story(id: NewsStory.ID) -> NewsStory? {
        storiesByID[id]
    }

    func stories(in category: NewsCategory) -> [NewsStory] {
        stories.filter { $0.categories.contains(category) }
    }

    private init(
        stories: [NewsStory],
        loadIssue: LoadIssue?,
        storiesByID: [NewsStory.ID: NewsStory]
    ) {
        self.stories = stories
        self.loadIssue = loadIssue
        self.storiesByID = storiesByID
    }

    private struct Document: Decodable {
        let stories: [NewsStory]
    }

    private static func loadBundled() -> NewsStoryCatalog {
        let resourceName = "NewsStories.json"
        guard let url = Bundle.main.url(
            forResource: "NewsStories",
            withExtension: "json"
        ) else {
            return failure(.resourceNotFound(resourceName))
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return failure(.unreadableResource(error.localizedDescription))
        }

        let document: Document
        do {
            document = try JSONDecoder().decode(Document.self, from: data)
        } catch {
            return failure(.decodingFailed(String(describing: error)))
        }

        var storiesByID: [NewsStory.ID: NewsStory] = [:]
        for story in document.stories {
            guard storiesByID[story.id] == nil else {
                return failure(.duplicateID(story.id))
            }
            storiesByID[story.id] = story
        }

        return NewsStoryCatalog(
            stories: document.stories,
            loadIssue: nil,
            storiesByID: storiesByID
        )
    }

    private static func failure(_ issue: LoadIssue) -> NewsStoryCatalog {
        NewsStoryCatalog(stories: [], loadIssue: issue, storiesByID: [:])
    }
}
