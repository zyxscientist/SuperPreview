import Foundation

// Offline AAPL events, sourced from Apple earnings releases and dividend history.
// Ex-dividend dates are cross-checked against published market dividend histories.
struct StockChartCorporateEarning: Identifiable {
    let id: String
    let date: Date
    let period: String
    // Date-group direction: 1 / -1 / 0, or nil for unknown. Offline values
    // are synthesized by mockColorType, not fetched from the production server.
    let colorType: Int?
    let defaultCurrency: String
    let values: [String: StockChartCorporateEarningValues]
}

struct StockChartCorporateEarningValues {
    let eps: String?
    let epsYoY: Double?
    let revenue: String?
    let revenueYoY: Double?
}

struct StockChartCorporateDividend: Identifiable {
    let id: String
    let date: Date
    let amount: String
    let recordDate: Date
    let payDate: Date
}

struct StockChartCorporateMarker: Identifiable {
    let candleIndex: Int
    let earnings: [StockChartCorporateEarning]
    let dividends: [StockChartCorporateDividend]
    var id: Int { candleIndex }
    var colorType: Int? { earnings.max(by: { $0.date < $1.date })?.colorType }
    var eventDateSummary: String {
        Set((earnings.map(\.date) + dividends.map(\.date)).map { Self.dateFormatter.string(from: $0) })
            .sorted().joined(separator: ", ")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

enum StockChartCorporateMock {
    static let events: (earnings: [StockChartCorporateEarning], dividends: [StockChartCorporateDividend]) = {
        // Published GAAP values and comparable prior-year values from each
        // quarter's Apple financial statement. Revenue is in USD millions.
        // Pre-split 2020 EPS is paired with the same report's pre-split prior EPS.
        // Full citations and date/amount conventions: Docs/AAPLCorporateActions.md.
        let earningsData: [(date: String, year: Int, quarter: Int, eps: Double, priorEPS: Double, revenue: Double, priorRevenue: Double)] = [
            ("2020-01-28", 2020, 1, 4.99, 4.18, 91819, 84310),
            ("2020-04-30", 2020, 2, 2.55, 2.46, 58313, 58015),
            ("2020-07-30", 2020, 3, 2.58, 2.18, 59685, 53809),
            ("2020-10-29", 2020, 4, 0.73, 0.76, 64698, 64040),
            ("2021-01-27", 2021, 1, 1.68, 1.25, 111439, 91819),
            ("2021-04-28", 2021, 2, 1.40, 0.64, 89584, 58313),
            ("2021-07-27", 2021, 3, 1.30, 0.65, 81434, 59685),
            ("2021-10-28", 2021, 4, 1.24, 0.73, 83360, 64698),
            ("2022-01-27", 2022, 1, 2.10, 1.68, 123945, 111439),
            ("2022-04-28", 2022, 2, 1.52, 1.40, 97278, 89584),
            ("2022-07-28", 2022, 3, 1.20, 1.30, 82959, 81434),
            ("2022-10-27", 2022, 4, 1.29, 1.24, 90146, 83360),
            ("2023-02-02", 2023, 1, 1.88, 2.10, 117154, 123945),
            ("2023-05-04", 2023, 2, 1.52, 1.52, 94836, 97278),
            ("2023-08-03", 2023, 3, 1.26, 1.20, 81797, 82959),
            ("2023-11-02", 2023, 4, 1.46, 1.29, 89498, 90146),
            ("2024-02-01", 2024, 1, 2.18, 1.88, 119575, 117154),
            ("2024-05-02", 2024, 2, 1.53, 1.52, 90753, 94836),
            ("2024-08-01", 2024, 3, 1.40, 1.26, 85777, 81797),
            ("2024-10-31", 2024, 4, 0.97, 1.46, 94930, 89498),
            ("2025-01-30", 2025, 1, 2.40, 2.18, 124300, 119575),
            ("2025-05-01", 2025, 2, 1.65, 1.53, 95359, 90753),
            ("2025-07-31", 2025, 3, 1.57, 1.40, 94036, 85777),
            ("2025-10-30", 2025, 4, 1.85, 0.97, 102466, 94930),
            ("2026-01-29", 2026, 1, 2.84, 2.40, 143756, 124300),
            ("2026-04-30", 2026, 2, 2.01, 1.65, 111184, 95359),
            ("2026-07-30", 2026, 3, 2.02, 1.57, 109417, 94036),
            ("2026-11-02", 2026, 4, 2.10, 1.85, 114477, 102466)
        ]
        // Declared per-share amounts (not split-adjusted); strings preserve
        // $0.205 without rounding it to $0.21. The last announced ex-date is
        // intentionally beyond the chart end and is filtered when bucketing.
        let dividendData: [(ex: String, record: String, pay: String, amount: String)] = [
            ("2020-02-07", "2020-02-10", "2020-02-13", "0.77"),
            ("2020-05-08", "2020-05-11", "2020-05-14", "0.82"),
            ("2020-08-07", "2020-08-10", "2020-08-13", "0.82"),
            ("2020-11-06", "2020-11-09", "2020-11-12", "0.205"),
            ("2021-02-05", "2021-02-08", "2021-02-11", "0.205"),
            ("2021-05-07", "2021-05-10", "2021-05-13", "0.22"),
            ("2021-08-06", "2021-08-09", "2021-08-12", "0.22"),
            ("2021-11-05", "2021-11-08", "2021-11-11", "0.22"),
            ("2022-02-04", "2022-02-07", "2022-02-10", "0.22"),
            ("2022-05-06", "2022-05-09", "2022-05-12", "0.23"),
            ("2022-08-05", "2022-08-08", "2022-08-11", "0.23"),
            ("2022-11-04", "2022-11-07", "2022-11-10", "0.23"),
            ("2023-02-10", "2023-02-13", "2023-02-16", "0.23"),
            ("2023-05-12", "2023-05-15", "2023-05-18", "0.24"),
            ("2023-08-11", "2023-08-14", "2023-08-17", "0.24"),
            ("2023-11-10", "2023-11-13", "2023-11-16", "0.24"),
            ("2024-02-09", "2024-02-12", "2024-02-15", "0.24"),
            ("2024-05-10", "2024-05-13", "2024-05-16", "0.25"),
            ("2024-08-12", "2024-08-12", "2024-08-15", "0.25"),
            ("2024-11-08", "2024-11-11", "2024-11-14", "0.25"),
            ("2025-02-10", "2025-02-10", "2025-02-13", "0.25"),
            ("2025-05-12", "2025-05-12", "2025-05-15", "0.26"),
            ("2025-08-11", "2025-08-11", "2025-08-14", "0.26"),
            ("2025-11-10", "2025-11-10", "2025-11-13", "0.26"),
            ("2026-02-09", "2026-02-09", "2026-02-12", "0.26"),
            ("2026-05-11", "2026-05-11", "2026-05-14", "0.27"),
            ("2026-08-10", "2026-08-10", "2026-08-13", "0.27"),
            ("2026-11-12", "2026-11-12", "2026-11-16", "0.27")
        ]
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "America/New_York")!
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        func date(_ string: String) -> Date { formatter.date(from: string)! }
        func change(_ value: Double, _ previous: Double) -> Double {
            (value / previous - 1) * 100
        }
        let earnings = earningsData.map { item in
            let epsYoY = change(item.eps, item.priorEPS)
            let values = StockChartCorporateEarningValues(
                eps: String(format: "%.2f", item.eps),
                epsYoY: epsYoY,
                revenue: String(format: "%.1fB", item.revenue / 1000),
                revenueYoY: change(item.revenue, item.priorRevenue))
            return StockChartCorporateEarning(id: "earning-\(item.date)", date: date(item.date),
                period: "\(item.year)/Q\(item.quarter)", colorType: mockColorType(epsYoY: epsYoY), defaultCurrency: "USD",
                values: ["USD": values])
        }
        let dividends = dividendData.map { item in
            StockChartCorporateDividend(id: "dividend-\(item.ex)", date: date(item.ex),
                amount: "\(item.amount) USD",
                recordDate: date(item.record), payDate: date(item.pay))
        }
        return (earnings, dividends)
    }()

    /// The production client consumes a server-provided date-group colorType;
    /// it does not define how that state is calculated. This offline demo uses
    /// the direction of published GAAP EPS YoY solely to synthesize that field.
    /// It is neither a verified server state nor an analyst-surprise/price signal.
    static func mockColorType(epsYoY: Double?) -> Int? {
        guard let epsYoY, epsYoY.isFinite else { return nil }
        return epsYoY > 0 ? 1 : (epsYoY < 0 ? -1 : 0)
    }

    static func markers(for period: StockChartPeriod, candles: [StockChartCandle],
                        earnings: [StockChartCorporateEarning] = events.earnings,
                        dividends: [StockChartCorporateDividend] = events.dividends) -> [StockChartCorporateMarker] {
        guard [.day, .week, .month].contains(period) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let component: Calendar.Component = period == .day ? .day : (period == .week ? .weekOfYear : .month)
        guard let lastCandle = candles.last,
              let lastDay = calendar.dateInterval(of: .day, for: lastCandle.date) else { return [] }
        return candles.enumerated().compactMap { index, candle in
            guard let interval = calendar.dateInterval(of: component, for: candle.date) else { return nil }
            // DateInterval.contains includes its end. Chart buckets must be
            // half-open so a Monday/month-start event cannot appear twice.
            func contains(_ date: Date) -> Bool {
                date >= interval.start && date < interval.end && date < lastDay.end
            }
            let bucketEarnings = earnings.filter { contains($0.date) }.sorted { $0.date > $1.date }
            let bucketDividends = dividends.filter { contains($0.date) }.sorted { $0.date > $1.date }
            guard !bucketEarnings.isEmpty || !bucketDividends.isEmpty else { return nil }
            return StockChartCorporateMarker(candleIndex: index, earnings: bucketEarnings, dividends: bucketDividends)
        }
    }
}
