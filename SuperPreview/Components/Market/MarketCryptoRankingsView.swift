import SwiftUI

private enum CryptoRankingMetric: String, CaseIterable, Identifiable {
    case marketCap, gainers, losers, turnover
    var id: String { rawValue }
    var title: DemoCopyKey {
        switch self {
        case .marketCap: .cryptoMarketCap
        case .gainers: .cryptoGainers
        case .losers: .cryptoLosers
        case .turnover: .cryptoTurnover
        }
    }
}

private struct CryptoRankingItem: Identifiable {
    let symbol: String
    let nameID: String
    let fallbackName: String
    let price: String
    let change: Double
    let marketCap: Double
    let turnover: Double
    var id: String { symbol }
    var imageName: String { "market_crypto_\(symbol.lowercased())" }

    // Prices and ranking metrics are display fixtures, not live quotations.
    static let mockData: [Self] = [
        .init(symbol: "BTC", nameID: "crypto-btc", fallbackName: "Bitcoin", price: "67,250.80", change: -0.94, marketCap: 1320, turnover: 32.40),
        .init(symbol: "ETH", nameID: "crypto-eth", fallbackName: "Ether", price: "3,520.65", change: -1.40, marketCap: 423, turnover: 15.80),
        .init(symbol: "SOL", nameID: "crypto-sol", fallbackName: "Solana", price: "148.32", change: 2.89, marketCap: 68, turnover: 3.20),
        .init(symbol: "LINK", nameID: "crypto-link", fallbackName: "Chainlink", price: "14.35", change: 1.26, marketCap: 14.2, turnover: 0.56),
        .init(symbol: "AVAX", nameID: "crypto-avax", fallbackName: "Avalanche", price: "28.72", change: -0.76, marketCap: 11.2, turnover: 0.48),
        .init(symbol: "AAVE", nameID: "crypto-aave", fallbackName: "Aave", price: "102.46", change: 2.35, marketCap: 4.0, turnover: 0.25),
        .init(symbol: "ARB", nameID: "crypto-arb", fallbackName: "Arbitrum", price: "0.78", change: 1.75, marketCap: 3.0, turnover: 0.31),
        .init(symbol: "OP", nameID: "crypto-op", fallbackName: "Optimism", price: "1.52", change: 0.68, marketCap: 2.0, turnover: 0.18),
        .init(symbol: "IMX", nameID: "crypto-imx", fallbackName: "Immutable", price: "1.23", change: -2.18, marketCap: 1.5, turnover: 0.12),
        .init(symbol: "IOTX", nameID: "crypto-iotx", fallbackName: "IoTeX", price: "0.04", change: -3.12, marketCap: 0.5, turnover: 0.05)
    ]
}

/// Five-row illustrative 24-hour market ranking.
struct MarketCryptoRankingsView: View {
    var onShowAll: () -> Void = { /* Connect the full ranking when available. */ }
    var onSelect: (String) -> Void = { _ in /* Connect the asset destination when available. */ }
    @Environment(\.demoLanguage) private var language
    @State private var selectedMetric: CryptoRankingMetric = .marketCap

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onShowAll) {
                HStack(spacing: 8) {
                    Text(language.text(.crypto24hRankings))
                        .modifier(CustomFontModifier(size: 18, font: .bold, lineHeight: 28))
                        .foregroundStyle(Color("color-text-30"))
                    Spacer(minLength: 0)
                    Image("chevron_right_text30_sm")
                        .resizable().scaledToFit().frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                }
                .frame(height: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .accessibilityLabel(language.actionAccessibilityLabel(name: language.text(.crypto24hRankings), action: language.text(.viewAll)))

            VStack(spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    metricButtons.fixedSize(horizontal: true, vertical: false)
                    ScrollView(.horizontal, showsIndicators: false) { metricButtons }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 48)

                ForEach(sortedItems) { item in
                    Button { onSelect(item.symbol) } label: { row(item) }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("market.cryptoRankings.asset.\(item.symbol)")
                }
            }
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("market.cryptoRankings")
    }

    private var sortedItems: [CryptoRankingItem] {
        let items = CryptoRankingItem.mockData
        switch selectedMetric {
        case .marketCap: return Array(items.sorted { $0.marketCap > $1.marketCap }.prefix(5))
        case .gainers: return Array(items.filter { $0.change > 0 }.sorted { $0.change > $1.change }.prefix(5))
        case .losers: return Array(items.filter { $0.change < 0 }.sorted { $0.change < $1.change }.prefix(5))
        case .turnover: return Array(items.sorted { $0.turnover > $1.turnover }.prefix(5))
        }
    }

    private var metricButtons: some View {
        HStack(spacing: 8) {
            ForEach(CryptoRankingMetric.allCases) { metric in
                metricButton(metric)
            }
        }
        .padding(.horizontal, 16)
    }

    private func metricButton(_ metric: CryptoRankingMetric) -> some View {
        let active = selectedMetric == metric
        return Button { selectedMetric = metric } label: {
            Text(language.text(metric.title))
                .modifier(CustomFontModifier(size: 14, font: active ? .bold : .regular, lineHeight: 20))
                .foregroundStyle(Color(active ? "color-text-30" : "color-text-60"))
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color(active ? "color-base-1" : "color-scale-1"), in: RoundedRectangle(cornerRadius: 6))
                .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(active ? Color("color-base-r") : .clear, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
        .accessibilityIdentifier("market.cryptoRankings.metric.\(metric.id)")
    }

    private func row(_ item: CryptoRankingItem) -> some View {
        GeometryReader { geometry in
            let contentWidth = max(geometry.size.width - 16, 0)
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(item.imageName).resizable().scaledToFit().frame(width: 34, height: 34).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.securityName(id: item.nameID, fallback: item.fallbackName))
                            .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                            .foregroundStyle(Color("color-text-30")).frame(height: 24)
                        Text(item.symbol)
                            .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                            .foregroundStyle(Color("color-text-60")).frame(height: 16)
                    }
                    .lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 16).padding(.trailing, 4)
                .frame(width: contentWidth * 0.4, height: 66)
                .clipped()

                HStack(spacing: 8) {
                    Text(item.price)
                        .foregroundStyle(Color(item.change >= 0 ? "color-utility3-red" : "color-utility3-green"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(metricValue(item))
                        .foregroundStyle(Color(selectedMetric == .gainers || selectedMetric == .losers ? (item.change >= 0 ? "color-utility3-red" : "color-utility3-green") : "color-text-30"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(width: contentWidth * 0.6, height: 66)
            }
        }
        .frame(height: 66)
        .background(Color("color-base-1"))
        .contentShape(Rectangle())
    }

    private func metricValue(_ item: CryptoRankingItem) -> String {
        if selectedMetric == .gainers || selectedMetric == .losers {
            return String(format: "%+.2f%%", locale: Locale(identifier: "en_US_POSIX"), item.change)
        }
        let billions = selectedMetric == .marketCap ? item.marketCap : item.turnover
        if language == .english {
            return String(format: "%.2fB", locale: Locale(identifier: "en_US_POSIX"), billions)
        }
        return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), billions * 10) + (language == .traditionalChinese ? "億" : "亿")
    }
}
