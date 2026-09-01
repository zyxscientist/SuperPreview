//
//  StockDetailNavbar.swift
//  SuperPreview
//

import SwiftUI

/// The compact quote displayed beneath a symbol when the detail page scrolls.
///
/// The page owns the scroll measurement and supplies `quoteRevealProgress` to
/// `StockDetailNavbar`, keeping this component reusable for every instrument.
struct StockDetailNavbarQuote: Equatable {
    enum Trend: Equatable {
        case up
        case down
        case flat

        fileprivate var color: Color {
            switch self {
            case .up:
                Color("color-utility3-red")
            case .down:
                Color("color-utility3-green")
            case .flat:
                Color("color-text-30")
            }
        }

        fileprivate var glyphAssetName: String? {
            switch self {
            case .up:
                "watchlistItem_up_red"
            case .down:
                "watchlistItem_down_green"
            case .flat:
                nil
            }
        }
    }

    let sessionTitle: String
    let price: String
    let change: String
    let changePercent: String
    let trend: Trend
    private let session: StockDetailTradingSession?

    init(
        sessionTitle: String,
        price: String,
        change: String,
        changePercent: String,
        trend: Trend
    ) {
        self.sessionTitle = sessionTitle
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.trend = trend
        self.session = nil
    }

    init(
        session: StockDetailTradingSession,
        price: String,
        change: String,
        changePercent: String,
        trend: Trend
    ) {
        self.sessionTitle = ""
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.trend = trend
        self.session = session
    }

    func localizedSessionTitle(for language: DemoLanguage) -> String {
        guard let session else { return sessionTitle }

        switch session {
        case .trading:
            return language.text(.stockDetailTradingSession)
        case .closed:
            return language.text(.stockDetailClosedSession)
        case .halted:
            return language.text(.stockDetailHaltedSession)
        case .preMarketTrading:
            return language.text(.stockDetailPreMarketNavbar)
        case .afterHoursTrading:
            return language.text(.stockDetailAfterHoursNavbar)
        }
    }
}

enum StockDetailNavbarTrailingAction: Hashable {
    case share
    case debug
}

/// A stock-detail navigation bar with a scroll-driven quote reveal.
///
/// `quoteRevealProgress` is normalized to `0...1`. The future detail page
/// derives it from its real scroll offset and threshold, so the title and quote
/// move together without this component needing to own a `ScrollView`.
struct StockDetailNavbar: View {
    let symbol: String
    let name: String
    let quote: StockDetailNavbarQuote?
    let quoteRevealProgress: CGFloat
    let onBack: () -> Void
    let onShare: () -> Void
    let trailingAction: StockDetailNavbarTrailingAction
    let backAccessibilityLabel: String?
    let shareAccessibilityLabel: String?

    @Environment(\.demoLanguage) private var language

    init(
        symbol: String,
        name: String,
        quote: StockDetailNavbarQuote? = nil,
        quoteRevealProgress: CGFloat = 0,
        onBack: @escaping () -> Void = {},
        onShare: @escaping () -> Void = {},
        trailingAction: StockDetailNavbarTrailingAction = .share,
        backAccessibilityLabel: String? = nil,
        shareAccessibilityLabel: String? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.quote = quote
        self.quoteRevealProgress = quoteRevealProgress
        self.onBack = onBack
        self.onShare = onShare
        self.trailingAction = trailingAction
        self.backAccessibilityLabel = backAccessibilityLabel
        self.shareAccessibilityLabel = shareAccessibilityLabel
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: StockDetailNavbarLayout.leadingTitleSpacing) {
                Button(action: onBack) {
                    glyph("back-Left")
                }
                .buttonStyle(PlainButtonStyle())
                .frame(
                    width: StockDetailNavbarLayout.iconSize,
                    height: StockDetailNavbarLayout.height
                )
                .contentShape(Rectangle())
                .accessibilityLabel(backAccessibilityLabel ?? language.text(.back))
                .accessibilityIdentifier("stockDetail.navbar.back")

                titleContent
            }

            Spacer(minLength: 0)

            Button(action: onShare) {
                trailingActionContent
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minWidth: StockDetailNavbarLayout.iconSize)
            .frame(height: StockDetailNavbarLayout.height)
            .contentShape(Rectangle())
            .accessibilityLabel(shareAccessibilityLabel ?? trailingActionAccessibilityLabel)
            .accessibilityIdentifier(trailingActionAccessibilityIdentifier)
        }
        .padding(.horizontal, StockDetailNavbarLayout.horizontalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockDetailNavbarLayout.height,
            maxHeight: StockDetailNavbarLayout.height
        )
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.navbar")
    }

    private var titleContent: some View {
        ZStack(alignment: .topLeading) {
            titleRow
                .frame(height: StockDetailNavbarLayout.titleHeight, alignment: .leading)
                .offset(y: StockDetailNavbarLayout.titleRestingOffset - titleLift)

            if let quote {
                quoteRow(quote)
                    .frame(height: StockDetailNavbarLayout.quoteHeight, alignment: .leading)
                    .offset(y: StockDetailNavbarLayout.quoteRestingOffset - quoteLift)
                    .opacity(revealProgress)
                    .accessibilityHidden(revealProgress < 0.5)
            }
        }
        .frame(
            width: StockDetailNavbarLayout.titleWidth,
            height: StockDetailNavbarLayout.height,
            alignment: .topLeading
        )
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(titleAccessibilityLabel)
        .accessibilityIdentifier("stockDetail.navbar.title")
    }

    private var titleRow: some View {
        HStack(spacing: StockDetailNavbarLayout.titleSpacing(for: revealProgress)) {
            Text(symbol)
            Text(displayName)
        }
        .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 24))
        .foregroundColor(Color("color-text-30"))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .frame(
            width: StockDetailNavbarLayout.titleWidth,
            height: StockDetailNavbarLayout.titleHeight,
            alignment: .leading
        )
    }

    private func quoteRow(_ quote: StockDetailNavbarQuote) -> some View {
        HStack(spacing: StockDetailNavbarLayout.quoteGroupSpacing) {
            Text(quote.localizedSessionTitle(for: language))
                .foregroundColor(Color("color-text-30"))

            HStack(spacing: StockDetailNavbarLayout.quoteValueSpacing) {
                Text(quote.price)

                if let glyphAssetName = quote.trend.glyphAssetName {
                    Image(glyphAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockDetailNavbarLayout.quoteTrendIconSize,
                            height: StockDetailNavbarLayout.quoteTrendIconSize
                        )
                        .accessibilityHidden(true)
                }

                Text(quote.change)
                Text(quote.changePercent)
            }
            .foregroundColor(quote.trend.color)
        }
        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(
            width: StockDetailNavbarLayout.titleWidth,
            height: StockDetailNavbarLayout.quoteHeight,
            alignment: .leading
        )
    }

    private func glyph(_ assetName: String) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(
                width: StockDetailNavbarLayout.iconSize,
                height: StockDetailNavbarLayout.iconSize
            )
    }

    @ViewBuilder
    private var trailingActionContent: some View {
        switch trailingAction {
        case .share:
            glyph("share-Right")
        case .debug:
            Text(language.text(.debug))
                .modifier(
                    CustomFontModifier(
                        size: 13,
                        font: .medium,
                        lineHeight: 16
                    )
                )
                .foregroundColor(Color("color-text-30"))
        }
    }

    private var trailingActionAccessibilityLabel: String {
        switch trailingAction {
        case .share:
            language.text(.share)
        case .debug:
            language.text(.debug)
        }
    }

    private var trailingActionAccessibilityIdentifier: String {
        switch trailingAction {
        case .share:
            "stockDetail.navbar.share"
        case .debug:
            "stockDetail.navbar.debug"
        }
    }

    private var revealProgress: CGFloat {
        guard quote != nil else { return 0 }
        return min(max(quoteRevealProgress, 0), 1)
    }

    private var titleLift: CGFloat {
        StockDetailNavbarLayout.titleLift * revealProgress
    }

    private var quoteLift: CGFloat {
        StockDetailNavbarLayout.quoteLift * revealProgress
    }

    private var titleAccessibilityLabel: String {
        guard let quote, revealProgress >= 0.5 else {
            return "\(symbol) \(displayName)"
        }

        let separator = language == .english ? ", " : "，"
        return [
            "\(symbol) \(displayName)",
            quote.localizedSessionTitle(for: language),
            quote.price,
            quote.change,
            quote.changePercent
        ].joined(separator: separator)
    }

    private var displayName: String {
        language.watchlistName(symbol: symbol, fallback: name)
    }
}

private enum StockDetailNavbarLayout {
    static let horizontalPadding: CGFloat = 16
    static let leadingTitleSpacing: CGFloat = 2
    static let iconSize: CGFloat = 24
    static let titleWidth: CGFloat = 240
    static let titleHeight: CGFloat = 24
    static let quoteHeight: CGFloat = 16
    static let height: CGFloat = 44
    static let titleRestingOffset: CGFloat = 10
    static let quoteRestingOffset: CGFloat = 42
    static let titleLift: CGFloat = 8
    static let quoteLift: CGFloat = 16
    static let quoteGroupSpacing: CGFloat = 8
    static let quoteValueSpacing: CGFloat = 4
    static let quoteTrendIconSize: CGFloat = 12

    static func titleSpacing(for progress: CGFloat) -> CGFloat {
        4 + (4 * progress)
    }
}

private struct StockDetailNavbarPreviewHarness: View {
    @State private var revealProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            StockDetailNavbar(
                symbol: "TSLA",
                name: "特斯拉",
                quote: .preview,
                quoteRevealProgress: revealProgress
            )

            Slider(value: $revealProgress, in: 0...1)
                .padding(.horizontal, 16)
        }
        .background(Color("color-base-1"))
    }
}

private extension StockDetailNavbarQuote {
    static let preview = StockDetailNavbarQuote(
        session: .trading,
        price: "1,776.740",
        change: "+1.079",
        changePercent: "+0.25%",
        trend: .up
    )
}

struct StockDetailNavbar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailNavbar(
                symbol: "TSLA",
                name: "特斯拉",
                quote: .preview
            )
            .previewDisplayName("Default")

            StockDetailNavbar(
                symbol: "TSLA",
                name: "特斯拉",
                quote: .preview,
                quoteRevealProgress: 1
            )
            .previewDisplayName("Scrolled")

            StockDetailNavbarPreviewHarness()
                .previewDisplayName("Interactive Reveal")
        }
        .previewLayout(.fixed(width: 402, height: 120))
    }
}
