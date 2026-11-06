import Foundation

@main
struct StockChartDataTests {
    static func near(_ actual: Double?, _ expected: Double, _ message: String, tolerance: Double = 1e-8) {
        guard let actual, actual.isFinite, abs(actual - expected) <= tolerance else {
            fatalError("\(message): expected \(expected), got \(String(describing: actual))")
        }
    }
    static func candle(_ high: Double, _ low: Double, _ close: Double) -> StockChartCandle {
        StockChartCandle(date: Date(timeIntervalSince1970: 0), open: close, high: high, low: low, close: close, volume: 1)
    }
    static func main() {
        let daily = StockChartMock.dataset(for: .day).candles
        precondition(daily.count == 1300)
        near(daily.last!.close, 212.45, "last close")
        for period in StockChartPeriod.allCases {
            let first = StockChartMock.dataset(for: period)
            let second = StockChartMock.dataset(for: period)
            precondition(!first.candles.isEmpty && first.candles.count == second.candles.count)
            for (a, b) in zip(first.candles, second.candles) {
                precondition(a.date == b.date && a.close == b.close)
                precondition(a.high >= max(a.open, a.close) && a.low <= min(a.open, a.close) && a.volume > 0)
            }
            for (a, b) in zip(first.candles, first.candles.dropFirst()) { precondition(a.date < b.date) }
        }
        let oneDay = StockChartMock.dataset(for: .intraday)
        let fiveDays = StockChartMock.dataset(for: .fiveDays)
        precondition(oneDay.candles.count == 390 && fiveDays.candles.count == 1950)
        near(oneDay.referenceClose, daily[daily.count - 2].close, "intraday reference")
        near(fiveDays.referenceClose, daily[daily.count - 6].close, "five-day reference")
        near(oneDay.candles.reduce(0) { $0 + $1.volume }, daily.last!.volume, "daily volume", tolerance: 1e-5)
        let intradaySeries = StockChartSeriesCache.series(for: oneDay, period: .intraday)
        near(intradaySeries.kdj.k[0], 50, "intraday KDJ uses price extrema")
        near(intradaySeries.averagePrices[0], oneDay.candles[0].close, "average starts each session")
        let fiveSeries = StockChartSeriesCache.series(for: fiveDays, period: .fiveDays)
        near(fiveSeries.averagePrices[390], fiveDays.candles[390].close, "average resets on next day")
        let repeatSeries = StockChartSeriesCache.series(for: oneDay, period: .intraday)
        let firstStorage = intradaySeries.ma[0].withUnsafeBufferPointer { $0.baseAddress }
        let repeatStorage = repeatSeries.ma[0].withUnsafeBufferPointer { $0.baseAddress }
        precondition(firstStorage == repeatStorage, "mock series should share cached storage")
        var modified = oneDay.candles
        let old = modified[0]
        modified[0] = StockChartCandle(date: old.date, open: old.open, high: old.high + 10,
                                       low: old.low, close: old.close + 10, volume: old.volume)
        let custom = StockChartDataset(candles: modified, referenceClose: oneDay.referenceClose)
        let customSeries = StockChartSeriesCache.series(for: custom, period: .intraday)
        near(customSeries.averagePrices[0], modified[0].close, "custom data bypasses cache")
        near(StockChartSeriesCache.series(for: oneDay, period: .intraday).averagePrices[0], old.close, "custom data does not pollute cache")
        let mismatch = StockChartSeriesCache.series(for: oneDay, period: .day)
        near(mismatch.kdj.k[0], StockChartCalculations.kdj(oneDay.candles).k[0]!, "different period bypasses mock cache")
        let dailySeries = StockChartSeriesCache.series(for: StockChartMock.dataset(for: .day), period: .day)
        precondition(dailySeries.ma[0].count == daily.count, "mismatched period must not pollute cache")
        let volumeSeed = oneDay.candles.prefix(5).map { $0.volume.rounded(.toNearestOrAwayFromZero) }.reduce(0, +)
        near(intradaySeries.volumeMA[0][4], (volumeSeed / 5).rounded(.toNearestOrAwayFromZero), "whole-unit volume MA")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        precondition(calendar.component(.hour, from: oneDay.candles.first!.date) == 9)
        precondition(calendar.component(.minute, from: oneDay.candles.first!.date) == 30)
        precondition(calendar.component(.hour, from: oneDay.candles.last!.date) == 15)
        precondition(calendar.component(.minute, from: oneDay.candles.last!.date) == 59)
        let minutes = StockChartMock.dataset(for: .minute1).candles
        let fives = StockChartMock.dataset(for: .minute5).candles
        precondition(minutes.count == 11700 && fives.count == 2340)
        near(fives[0].open, minutes[0].open, "minute open")
        near(fives[0].close, minutes[4].close, "minute close")
        near(fives[0].high, minutes.prefix(5).map(\.high).max()!, "minute high")
        near(fives[0].volume, minutes.prefix(5).reduce(0) { $0 + $1.volume }, "minute volume")
        precondition(StockChartMock.dataset(for: .minute60).candles.count == 210)
        for period in [StockChartPeriod.week, .month] {
            let aggregate = StockChartMock.dataset(for: period).candles
            let last = aggregate.last!
            let matching = daily.filter { day in
                if period == .week {
                    return calendar.component(.weekOfYear, from: day.date) == calendar.component(.weekOfYear, from: last.date)
                        && calendar.component(.yearForWeekOfYear, from: day.date) == calendar.component(.yearForWeekOfYear, from: last.date)
                }
                return calendar.component(.month, from: day.date) == calendar.component(.month, from: last.date)
                    && calendar.component(.year, from: day.date) == calendar.component(.year, from: last.date)
            }
            near(last.open, matching.first!.open, "aggregated open")
            near(last.close, matching.last!.close, "aggregated close")
            near(last.high, matching.map(\.high).max()!, "aggregated high")
            near(last.low, matching.map(\.low).min()!, "aggregated low")
            near(last.volume, matching.reduce(0) { $0 + $1.volume }, "aggregated volume", tolerance: 1e-5)
        }
        let ma = StockChartCalculations.ma([1, 2, 3, 4], period: 3)
        precondition(ma[0] == nil && ma[1] == nil)
        near(ma[2], 2, "MA"); near(ma[3], 3, "MA sliding")
        let ema = StockChartCalculations.ema([1, 2, 3, 8], period: 3)
        near(ema[0], 1, "EMA first"); near(ema[1], 1.5, "EMA cumulative")
        near(ema[2], 2, "EMA seed"); near(ema[3], 5, "EMA recursive")
        let b = StockChartCalculations.boll([1, 2, 3], period: 3)
        near(b.middle[2], 2, "BOLL middle")
        near(b.upper[2], 3.633, "BOLL upper")
        near(b.lower[2], 0.367, "BOLL lower")
        let roundedMA = StockChartCalculations.ma([202.287, 202.288], period: 2)
        near(roundedMA[1], 202.288, "MA half-up on final ticks")
        let roundedBoll = StockChartCalculations.boll([1.2344, 1.2345], period: 2)
        near(roundedBoll.middle[1], 1.235, "BOLL input and mean ticks")
        near(roundedBoll.upper[1], 1.236, "BOLL upper final ticks")
        near(roundedBoll.lower[1], 1.234, "BOLL lower final ticks")
        near(StockChartCalculations.ma([10, 11], period: 2, precision: 0)[1], 11, "volume MA precision")
        near(StockChartCalculations.ma([1.2344, 1.2345], period: 2, precision: 4)[1], 1.2345, "configurable MA precision")
        near(StockChartCalculations.ma([1.5, 2.5], period: 2, precision: -1)[1], 3, "invalid precision fallback")
        near(StockChartCalculations.ma([1, .nan], period: 2)[1], 0.5, "nonfinite treated as zero")
        precondition(StockChartCalculations.ma([Double.greatestFiniteMagnitude], period: 1).allSatisfy { $0 == nil })
        precondition(StockChartCalculations.boll([Double.greatestFiniteMagnitude], period: 1).middle.allSatisfy { $0 == nil })
        let macd = StockChartCalculations.macd(Array(repeating: 10, count: 40))
        near(macd.dif[39], 0, "MACD DIF"); near(macd.dea[39], 0, "MACD DEA"); near(macd.histogram[39], 0, "MACD bar")
        let kd = StockChartCalculations.kdj([candle(10, 0, 10), candle(10, 0, 0)])
        near(kd.k[0], 200.0 / 3, "KDJ K"); near(kd.d[0], 500.0 / 9, "KDJ D"); near(kd.j[0], 800.0 / 9, "KDJ J")
        let rsi = StockChartCalculations.rsi([1, 2, 1, 2], period: 3)
        precondition(rsi[0] == nil && rsi[1] == nil)
        near(rsi[2], 50, "RSI seed"); near(rsi[3], 200.0 / 3, "RSI Wilder")
        let sar = StockChartCalculations.sar([candle(10, 8, 9), candle(11, 9, 10), candle(12, 10, 11), candle(9, 7, 8)])
        near(sar[0], 8, "SAR initial"); near(sar[1], 8, "SAR clamp"); near(sar[3], 12, "SAR reversal")
        precondition(StockChartCalculations.ma([1, 2], period: 0).allSatisfy { $0 == nil })
        precondition(StockChartCalculations.rsi([1, 2], period: 3).allSatisfy { $0 == nil })
        precondition(StockChartCalculations.sar([]).isEmpty)
        precondition(StockChartCalculations.ema([], period: 3).isEmpty)
        print("StockChartDataTests passed")
    }
}
