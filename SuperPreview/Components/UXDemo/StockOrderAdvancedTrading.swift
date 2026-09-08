//
//  StockOrderAdvancedTrading.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderAdvancedTradingPreferences {
    static let enabledKey = "stockOrder.highFrequencyTrading.enabled"
    static let versionKey = "stockOrder.highFrequencyTrading.version"

    // Reset once per process only when explicitly requested by UI tests.
    // Relaunching without this flag exercises the real persisted preference.
    static let prepareForUITesting: Void = {
        guard PreviewRuntime.isUITesting,
              ProcessInfo.processInfo.environment["UITEST_RESET_HIGH_FREQUENCY_TRADING"] == "1" else { return }
        UserDefaults.standard.removeObject(forKey: enabledKey)
        UserDefaults.standard.removeObject(forKey: versionKey)
    }()
}

enum StockOrderAdvancedTradingVersion: String, CaseIterable, Hashable, Identifiable {
    case v0
    case v1

    var id: Self { self }
}

/// The four peer views available after a stock has been selected.
enum StockOrderAdvancedTradingSection: String, CaseIterable, Hashable, Identifiable {
    case market
    case trade
    case orders
    case positions

    var id: Self { self }

    func title(language: DemoLanguage) -> String {
        switch self {
        case .market:
            language.text(.quote)
        case .trade:
            language.text(.trade)
        case .orders:
            language.text(.advancedTradingOrders)
        case .positions:
            language.text(.positions)
        }
    }

    var navigationBackSwipeRefreshID: Int {
        switch self {
        case .market:
            0
        case .trade:
            1
        case .orders:
            2
        case .positions:
            3
        }
    }
}

enum StockOrderAdvancedTradingLayout {
    static let toolBarGap: CGFloat = 8

    struct Metrics {
        let toolBarHeight: CGFloat
        let toolBarBottomInset: CGFloat
        let contentBottomInset: CGFloat
        let fontSize: CGFloat
        let lineHeight: CGFloat
        let segmentHeight: CGFloat
        let segmentContainerInset: CGFloat
    }

    static func metrics(
        for version: StockOrderAdvancedTradingVersion,
        bottomSafeArea: CGFloat = StockTradingBottomLayout.homeIndicatorAreaHeight
    ) -> Metrics {
        switch version {
        case .v0:
            let toolBarBottomInset = StockTradingBottomLayout.containerHeight + toolBarGap
            return Metrics(
                toolBarHeight: 40,
                toolBarBottomInset: toolBarBottomInset,
                contentBottomInset: toolBarBottomInset + 40 + 8,
                fontSize: 14,
                lineHeight: 14,
                segmentHeight: 34,
                segmentContainerInset: 3
            )
        case .v1:
            // The v1 switcher sits 5pt above the device's actual bottom safe area.
            let toolBarBottomInset = max(bottomSafeArea, 0) + 5
            return Metrics(
                toolBarHeight: 48,
                toolBarBottomInset: toolBarBottomInset,
                contentBottomInset: toolBarBottomInset + 48 + 8,
                fontSize: 16,
                lineHeight: 24,
                segmentHeight: 40,
                segmentContainerInset: 4
            )
        }
    }

    static func contentBottomInset(
        for version: StockOrderAdvancedTradingVersion,
        includesToolBar: Bool,
        bottomSafeArea: CGFloat = StockTradingBottomLayout.homeIndicatorAreaHeight
    ) -> CGFloat {
        if includesToolBar {
            return metrics(for: version, bottomSafeArea: bottomSafeArea).contentBottomInset
        }

        switch version {
        case .v0:
            return StockTradingBottomLayout.containerHeight + 16
        case .v1:
            return max(bottomSafeArea, 0) + 16
        }
    }

    static func pageSwitchAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.16)
    }
}

/// The compact glass switcher from the trading design.
///
/// The selected capsule is deliberately custom because the design uses a
/// dark filled segment inside a glass surface rather than the system Picker
/// appearance. The control still exposes normal Button semantics to VoiceOver
/// and keeps all four targets equal in width for rapid switching.
struct StockOrderAdvancedTradingToolBar: View {
    @Binding var selection: StockOrderAdvancedTradingSection
    let version: StockOrderAdvancedTradingVersion
    let bottomSafeArea: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.demoLanguage) private var language

    init(
        selection: Binding<StockOrderAdvancedTradingSection>,
        version: StockOrderAdvancedTradingVersion = .v0,
        bottomSafeArea: CGFloat = StockTradingBottomLayout.homeIndicatorAreaHeight
    ) {
        _selection = selection
        self.version = version
        self.bottomSafeArea = bottomSafeArea
    }

    var body: some View {
        if PreviewRuntime.isUITesting && version == .v1 {
            toolbarSurface
                .background {
                    Color.clear
                        .accessibilityElement()
                        .accessibilityLabel("Advanced trading toolbar")
                        .accessibilityIdentifier("stockOrder.advancedTrading.toolbar.geometry")
                        .allowsHitTesting(false)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("stockOrder.advancedTrading.toolbar")
        } else {
            toolbarSurface
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("stockOrder.advancedTrading.toolbar")
        }
    }

    private var toolbarSurface: some View {
        let metrics = StockOrderAdvancedTradingLayout.metrics(
            for: version,
            bottomSafeArea: bottomSafeArea
        )

        return surface
            .frame(height: metrics.toolBarHeight)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var surface: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 0) {
                segments
                    .glassEffect(.regular, in: Capsule())
            }
        } else {
            segments
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.black.opacity(0.16), lineWidth: 0.5)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
        }
    }

    private var segments: some View {
        let metrics = StockOrderAdvancedTradingLayout.metrics(
            for: version,
            bottomSafeArea: bottomSafeArea
        )

        return HStack(spacing: 0) {
            ForEach(StockOrderAdvancedTradingSection.allCases) { section in
                Button {
                    guard selection != section else { return }
                    selection = section
                } label: {
                    Text(section.title(language: language))
                        .font(
                            .custom(
                                selection == section
                                    ? "PlusJakartaSans-Bold"
                                    : "PlusJakartaSans-Medium",
                                size: metrics.fontSize,
                                relativeTo: .subheadline
                            )
                        )
                        .foregroundColor(
                            selection == section
                                ? Color("color-text-r")
                                : Color("color-text-30")
                        )
                        .lineLimit(1)
                        .lineSpacing(max(metrics.lineHeight - metrics.fontSize, 0))
                        .frame(maxWidth: .infinity)
                        .frame(height: metrics.segmentHeight)
                        .contentShape(Capsule())
                        // Match the watchlist tabs: labels update immediately;
                        // only the single persistent selection surface moves.
                        .transaction { $0.animation = nil }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(section.title(language: language))
                .accessibilityAddTraits(selection == section ? .isSelected : [])
                .accessibilityIdentifier(
                    "stockOrder.advancedTrading.section.\(section.rawValue)"
                )
            }
        }
        .background {
            GeometryReader { geometry in
                let segmentWidth = geometry.size.width
                    / CGFloat(StockOrderAdvancedTradingSection.allCases.count)
                let selectedIndex = StockOrderAdvancedTradingSection.allCases
                    .firstIndex(of: selection) ?? 0

                Capsule()
                    .fill(Color("color-base-r"))
                    .frame(width: segmentWidth, height: geometry.size.height)
                    .offset(x: CGFloat(selectedIndex) * segmentWidth)
                    .animation(selectionAnimation, value: selection)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .padding(metrics.segmentContainerInset)
    }

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.32, extraBounce: 0)
    }
}

extension StockOrderSymbol {
    /// Converts the order page's selected symbol into the existing quote-page
    /// model without creating a second source of market data.
    var advancedTradingInstrument: StockDetailInstrument {
        let detailMarket: StockDetailInstrumentMarket
        let kind: StockDetailInstrumentKind

        switch market {
        case .hk:
            detailMarket = .hongKong
            kind = .stock
        case .us:
            detailMarket = .us
            kind = .stock
        case .china:
            detailMarket = .aShare
            kind = .stock
        case .crypto:
            detailMarket = .crypto
            kind = .crypto
        }

        let detailTrend: StockDetailQuoteTrend
        switch quote.trend {
        case .up:
            detailTrend = .up
        case .down:
            detailTrend = .down
        case .flat:
            detailTrend = .flat
        }

        let detailSession: StockDetailInstrumentSession
        switch quote.session {
        case .regular:
            detailSession = .regular
        case let .preMarket(change):
            detailSession = .preMarket(change: change)
        case let .afterHours(change):
            detailSession = .afterHours(change: change)
        }

        return StockDetailInstrument(
            symbol: id,
            fallbackName: fallbackName,
            localizationID: localizationID,
            market: detailMarket,
            kind: kind,
            quote: StockDetailInstrumentQuote(
                price: quote.price,
                secondaryPrice: quote.secondaryPrice,
                changePercent: quote.changePercent,
                trend: detailTrend,
                session: detailSession,
                miniKPoints: quote.miniKPoints
            )
        )
    }
}
