//
//  NewsDemoView.swift
//  SuperPreview
//

import SwiftUI

/// Hosts the redesigned news feeds inside the app's existing navigation shell.
struct NewsDemoView: View {
    @State private var selectedCategory: NewsDemoCategory = .headline
    @State private var selectedArticleID: String?
    @State private var isShowingArticle = false

    var body: some View {
        GeometryReader { geometry in
            let bottomContentClearance = geometry.safeAreaInsets.bottom + 28

            VStack(spacing: 0) {
                NewsDemoCategoryBar(selection: $selectedCategory)

                TabView(selection: $selectedCategory) {
                    NewsHeadlineView(
                        onArticle: openArticle,
                        bottomContentClearance: bottomContentClearance
                    )
                    .tag(NewsDemoCategory.headline)

                    NewsLiveView(
                        onArticle: openArticle,
                        bottomContentClearance: bottomContentClearance
                    )
                    .tag(NewsDemoCategory.live)

                    NewsWatchlistFeedView(
                        onArticle: openArticle,
                        bottomContentClearance: bottomContentClearance
                    )
                    .tag(NewsDemoCategory.watchlist)

                    NewsTopicsView(
                        onArticle: openArticle,
                        bottomContentClearance: bottomContentClearance
                    )
                    .tag(NewsDemoCategory.topics)

                    NewsCryptoFeedView(
                        onArticle: openArticle,
                        bottomContentClearance: bottomContentClearance
                    )
                    .tag(NewsDemoCategory.crypto)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("color-base-1").edgesIgnoringSafeArea(.all))
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .background(articleNavigationLink)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("news.main")
    }

    private var articleNavigationLink: some View {
        // NewsDemoDetailView uses content from the existing NavigationView root.
        NavigationLink(
            destination: articleDestination,
            isActive: $isShowingArticle
        ) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var articleDestination: some View {
        if let id = selectedArticleID {
            NewsDemoDetailView(articleID: id)
        }
    }

    private func openArticle(_ id: String?) {
        guard let id else { return }
        selectedArticleID = id
        isShowingArticle = true
    }
}

private enum NewsDemoCategory: String, CaseIterable, Identifiable {
    case headline
    case live
    case watchlist
    case topics
    case crypto

    var id: Self { self }

    func title(in language: DemoLanguage) -> String {
        switch self {
        case .headline:
            switch language {
            case .simplifiedChinese: return "要闻"
            case .traditionalChinese: return "要聞"
            case .english: return "Headlines"
            }
        case .live: return "7x24"
        case .watchlist: return language.text(.watchlist)
        case .topics:
            switch language {
            case .simplifiedChinese: return "专题"
            case .traditionalChinese: return "專題"
            case .english: return "Topics"
            }
        case .crypto: return language.text(.virtualAssets)
        }
    }
}

private struct NewsDemoCategoryBar: View {
    @Binding var selection: NewsDemoCategory
    @EnvironmentObject private var demoAppearanceStore: DemoAppearanceStore
    @Environment(\.demoLanguage) private var language

    var body: some View {
        WatchlistRedesignTabs(
            tabs: NewsDemoCategory.allCases.map(\.rawValue),
            selectedTab: sharedSelection,
            fontSize: 14,
            isReducedLiquidGlassUsageEnabled: demoAppearanceStore.isReducedLiquidGlassUsageEnabled,
            titleProvider: title(for:),
            accessibilityPrefix: "news",
            showsSortMenu: false,
            leadingPadding: 16
        )
        .accessibilityIdentifier("news.categoryBar")
    }

    private var sharedSelection: Binding<String> {
        Binding(
            get: { selection.rawValue },
            set: { rawValue in
                guard let category = NewsDemoCategory(rawValue: rawValue) else { return }
                selection = category
            }
        )
    }

    private func title(for rawValue: String) -> String {
        NewsDemoCategory(rawValue: rawValue)?.title(in: language) ?? rawValue
    }
}
