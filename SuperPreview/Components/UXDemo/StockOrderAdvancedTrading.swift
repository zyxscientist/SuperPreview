//
//  StockOrderAdvancedTrading.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderAdvancedTradingPreferences {
    static let enabledKey = "stockOrder.highFrequencyTrading.enabled"

    // Reset once per process only when explicitly requested by UI tests.
    // Relaunching without this flag exercises the real persisted preference.
    static let prepareForUITesting: Void = {
        guard PreviewRuntime.isUITesting,
              ProcessInfo.processInfo.environment["UITEST_RESET_HIGH_FREQUENCY_TRADING"] == "1" else { return }
        UserDefaults.standard.removeObject(forKey: enabledKey)
    }()
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
    static let toolBarHeight: CGFloat = 40
    static let toolBarGap: CGFloat = 8
    // Reserve the action-bar slot even on pages that have no bottom actions.
    static let toolBarBottomInset = StockTradingBottomLayout.containerHeight + toolBarGap
    static let contentBottomInset = toolBarBottomInset + toolBarHeight + 8

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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.demoLanguage) private var language

    var body: some View {
        surface
            .frame(height: StockOrderAdvancedTradingLayout.toolBarHeight)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockOrder.advancedTrading.toolbar")
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
        HStack(spacing: 0) {
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
                                size: 14,
                                relativeTo: .subheadline
                            )
                        )
                        .foregroundColor(
                            selection == section
                                ? Color("color-text-r")
                                : Color("color-text-30")
                        )
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
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
        .padding(3)
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
