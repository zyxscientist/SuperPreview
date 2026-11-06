import SwiftUI

/// The stock-detail intraday trade tape. All rows are deterministic preview data.
struct StockChartTrades: View {
    @Environment(\.demoLanguage) private var language
    @Environment(\.marketColorReversed) private var reversed
    var onDetails: (() -> Void)? = nil
    var showsDetails = true

    private struct Trade: Identifiable {
        let id: Int
        let time: Date
        let price: Double
        let amount: Int
        let direction: Int // -1: sell, 0: neutral, 1: buy
    }

    private static let dataset = StockChartMock.dataset(for: .intraday)
    private static let rows: [Trade] = {
        let candles = dataset.candles.suffix(80)
        return candles.enumerated().map { index, candle in
            Trade(id: index, time: candle.date, price: candle.close,
                  amount: 100 + (index * 137 % 1900), direction: [1, -1, 0, 1, -1][index % 5])
        }
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/New_York")!
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 7) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Self.rows) { trade in
                            tradeRow(trade).id(trade.id)
                        }
                    }
                }
                // The inline tape is a latest-trades preview. Vertical drags
                // belong to its page; the dedicated details sheet browses the
                // full tape independently. Programmatic positioning is kept.
                .scrollDisabled(showsDetails)
                .onAppear {
                    if let id = Self.rows.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                }
                .accessibilityIdentifier("stockDetail.chart.trades.list")
            }
            if showsDetails { detailsControl
                .padding(.trailing, 12)
                .padding(.bottom, 7)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(showsDetails ? "stockDetail.chart.trades" : "stockDetail.chart.trades.list")
    }

    @ViewBuilder private var detailsControl: some View {
        let label = stockChartText(.transactionDetails, language: language)
        if let onDetails {
            Button(action: onDetails) { detailsLabel(label) }
                .buttonStyle(.plain)
                .accessibilityIdentifier("stockDetail.chart.trades.details")
        } else {
            detailsLabel(label)
                .accessibilityLabel(label)
        }
    }

    private func detailsLabel(_ label: String) -> some View {
        Text(label)
            .font(.custom("PlusJakartaSans-Regular", size: language == .english ? 10 : 14))
            .foregroundStyle(Color("color-text-60"))
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 4))
    }

    private func tradeRow(_ trade: Trade) -> some View {
        let directionColor = trade.direction == 0 ? Color("color-text-60") : marketColor(up: trade.direction > 0)
        let priceColor = abs(trade.price - Self.dataset.referenceClose) < 0.00001 ? Color("color-text-60") : marketColor(up: trade.price > Self.dataset.referenceClose)
        return HStack(spacing: 0) {
            Text(Self.timeFormatter.string(from: trade.time))
                .foregroundStyle(Color("color-text-60"))
                .fixedSize(horizontal: true, vertical: false)
            Text(String(format: "%.3f", trade.price))
                .foregroundStyle(priceColor)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.leading, 4)
            Text(trade.amount.formatted())
                .foregroundStyle(directionColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.leading, 2)
            Image(trade.direction > 0 ? "direction_buy" : trade.direction < 0 ? "direction_sale" : "direction_neutral")
                .renderingMode(.template)
                .resizable()
                .frame(width: 7, height: 6)
                .foregroundStyle(directionColor)
                .padding(.leading, 1)
                .padding(.trailing, 12)
        }
        .font(.custom("PlusJakartaSans-Medium", size: 10).monospacedDigit())
        .frame(height: 20)
        .accessibilityElement(children: .combine)
    }

    private func marketColor(up: Bool) -> Color {
        MarketColor.resolve(up ? "color-utility3-red" : "color-utility3-green", reversed: reversed)
    }
}
