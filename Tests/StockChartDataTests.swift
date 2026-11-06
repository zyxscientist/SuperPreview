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
        precondition(daily.count > 1700)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")!
        let tradingDates = Set(daily.map { dateFormatter.string(from: $0.date) })
        precondition(dateFormatter.string(from: daily.first!.date) == "2019-12-02")
        precondition(dateFormatter.string(from: daily.last!.date) == "2026-11-05")
        for closed in ["2020-04-10", "2021-12-24", "2022-06-20", "2024-07-04", "2025-01-09", "2026-11-26"] {
            precondition(!tradingDates.contains(closed), "closed market date \(closed)")
        }
        precondition(tradingDates.contains("2021-12-31"), "Saturday New Year is not observed on prior Friday")
        precondition(zip(daily.dropFirst(), daily).contains { abs($0.open - $1.close) > 0.1 }, "sessions have opening gaps")
        precondition(daily.map(\.close).max()! > 300 && daily.map(\.close).min()! < 100)
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
        func exchangeDate(_ text: String) -> Date { dateFormatter.date(from: text)! }
        for early in ["2020-11-27", "2024-07-03", "2025-11-28", "2025-12-24"] {
            let date = exchangeDate(early)
            precondition(StockChartMock.isTradingDay(date, calendar: calendar))
            precondition(StockChartMock.isEarlyClose(date, calendar: calendar))
        }
        precondition(!StockChartMock.isEarlyClose(exchangeDate("2026-11-05"), calendar: calendar))
        precondition(calendar.component(.hour, from: oneDay.candles.first!.date) == 9)
        precondition(calendar.component(.minute, from: oneDay.candles.first!.date) == 30)
        precondition(calendar.component(.hour, from: oneDay.candles.last!.date) == 15)
        precondition(calendar.component(.minute, from: oneDay.candles.last!.date) == 59)
        for dayIndex in 0..<5 {
            let session = Array(fiveDays.candles[(dayIndex * 390)..<((dayIndex + 1) * 390)])
            let matchingDaily = daily[daily.count - 5 + dayIndex]
            precondition(calendar.isDate(session[0].date, inSameDayAs: matchingDaily.date))
            for (index, bar) in session.enumerated() {
                precondition(bar.date.timeIntervalSince(session[0].date) == Double(index * 60))
                if index > 0 { near(bar.open, session[index - 1].close, "minute continuity") }
            }
            near(session.first!.open, matchingDaily.open, "session open")
            near(session.last!.close, matchingDaily.close, "session close")
            near(session.reduce(0) { $0 + $1.volume }, matchingDaily.volume, "session volume", tolerance: 1e-5)
            let changes = zip(session.dropFirst(), session).map { $0.close - $1.close }
            let reversals = zip(changes.dropFirst(), changes).filter { $0 * $1 < 0 }.count
            precondition(reversals > 70, "minute prices should have irregular reversals")
            func meanVolume(_ range: Range<Int>) -> Double {
                session[range].reduce(0) { $0 + $1.volume } / Double(range.count)
            }
            let midday = meanVolume(165..<225)
            precondition(meanVolume(0..<60) > midday * 1.4, "opening volume should exceed midday")
            precondition(meanVolume(330..<390) > midday * 1.25, "closing volume should exceed midday")
            precondition(Set(session.map(\.volume)).count > 350, "minute volume should vary")
        }
        for (intradayBar, fiveDayBar) in zip(oneDay.candles, fiveDays.candles.suffix(390)) {
            precondition(intradayBar.date == fiveDayBar.date && intradayBar.close == fiveDayBar.close
                         && intradayBar.volume == fiveDayBar.volume)
        }
        let minutes = StockChartMock.dataset(for: .minute1).candles
        let fives = StockChartMock.dataset(for: .minute5).candles
        precondition(minutes.count == 11700 && fives.count == 2340)
        near(fives[0].open, minutes[0].open, "minute open")
        near(fives[0].close, minutes[4].close, "minute close")
        near(fives[0].high, minutes.prefix(5).map(\.high).max()!, "minute high")
        near(fives[0].volume, minutes.prefix(5).reduce(0) { $0 + $1.volume }, "minute volume")
        precondition(StockChartMock.dataset(for: .minute60).candles.count == 210)
        // Every aggregated bucket stays inside its own exchange session, including
        // the final partial hour. Intraday and daily bars derive from the same path.
        let sessions = Dictionary(grouping: minutes) { dateFormatter.string(from: $0.date) }
        precondition(sessions.count == 30)
        for dailyBar in daily.suffix(30) {
            let session = sessions[dateFormatter.string(from: dailyBar.date)]!
            near(session.first!.open, dailyBar.open, "daily minute open")
            near(session.last!.close, dailyBar.close, "daily minute close")
            near(session.map(\.high).max(), dailyBar.high, "daily minute high")
            near(session.map(\.low).min(), dailyBar.low, "daily minute low")
        }
        for (period, size) in [(StockChartPeriod.minute5, 5), (.minute15, 15), (.minute30, 30), (.minute60, 60)] {
            let grouped = Dictionary(grouping: StockChartMock.dataset(for: period).candles) { dateFormatter.string(from: $0.date) }
            for (day, bars) in grouped {
                let source = sessions[day]!
                precondition(bars.count == (source.count + size - 1) / size)
                for (index, bar) in bars.enumerated() {
                    let bucket = source[(index * size)..<min((index + 1) * size, source.count)]
                    precondition(bar.date == bucket.first!.date)
                    near(bar.open, bucket.first!.open, "bucket open")
                    near(bar.close, bucket.last!.close, "bucket close")
                    near(bar.volume, bucket.reduce(0) { $0 + $1.volume }, "bucket volume", tolerance: 1e-5)
                }
            }
        }

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
        let split = calendar.date(from: DateComponents(year: 2020, month: 8, day: 31))!
        let unadjusted = StockChartMock.adjustedDataset(for: .day, adjustment: .none)
        let backward = StockChartMock.adjustedDataset(for: .day, adjustment: .backward)
        precondition(unadjusted.mockID == nil && backward.mockID == nil)
        for (index, original) in daily.enumerated() {
            let scale = original.date < split ? 4.0 : 1.0
            near(unadjusted.candles[index].close, original.close * scale, "unadjusted close")
            near(unadjusted.candles[index].volume, original.volume / scale, "unadjusted volume")
            near(backward.candles[index].close, original.close * 4, "backward close")
        }
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        for period in [StockChartPeriod.week, .month] {
            let unadjustedPeriod = StockChartMock.adjustedDataset(for: period, adjustment: .none)
            let backwardPeriod = StockChartMock.adjustedDataset(for: period, adjustment: .backward)
            precondition(unadjustedPeriod.mockID == nil && backwardPeriod.mockID == nil)
            for bar in unadjustedPeriod.candles {
                let matching = unadjusted.candles.filter { day in
                    period == .week
                        ? calendar.component(.weekOfYear, from: day.date) == calendar.component(.weekOfYear, from: bar.date)
                          && calendar.component(.yearForWeekOfYear, from: day.date) == calendar.component(.yearForWeekOfYear, from: bar.date)
                        : calendar.component(.month, from: day.date) == calendar.component(.month, from: bar.date)
                          && calendar.component(.year, from: day.date) == calendar.component(.year, from: bar.date)
                }
                near(bar.open, matching.first!.open, "unadjusted aggregate open")
                near(bar.high, matching.map(\.high).max()!, "unadjusted aggregate high")
                near(bar.low, matching.map(\.low).min()!, "unadjusted aggregate low")
                near(bar.close, matching.last!.close, "unadjusted aggregate close")
                near(bar.volume, matching.reduce(0) { $0 + $1.volume }, "unadjusted aggregate volume", tolerance: 1e-5)
            }
            for (actual, original) in zip(backwardPeriod.candles, StockChartMock.dataset(for: period).candles) {
                near(actual.close, original.close * 4, "backward aggregate")
            }
        }
        for period in [StockChartPeriod.intraday, .fiveDays, .minute1, .minute5, .minute15, .minute30, .minute60] {
            let original = StockChartMock.dataset(for: period)
            for adjustment in [StockChartAdjustment.forward, .none, .backward] {
                let adjusted = StockChartMock.adjustedDataset(for: period, adjustment: adjustment)
                precondition(adjusted.mockID == original.mockID && adjusted.candles.count == original.candles.count)
                near(adjusted.candles[0].close, original.candles[0].close, "intraday adjustment unchanged")
            }
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
        let rsiOne = StockChartCalculations.rsi([1, 3, 2, 2], period: 1)
        precondition(rsiOne[0] == nil)
        near(rsiOne[1], 100, "RSI 1 current increase")
        near(rsiOne[2], 0, "RSI 1 current decrease")
        near(rsiOne[3], 50, "RSI 1 flat")
        let narrow = StockChartCalculations.boll([1, 2, 3], period: 3, standardDeviations: 1)
        near(narrow.upper[2], 2.816, "custom BOLL multiplier")
        let customKD = StockChartCalculations.kdj([candle(10, 0, 10), candle(10, 0, 0)], period: 2, kSmoothing: 2, dSmoothing: 2)
        near(customKD.k[0], 75, "custom K smoothing")
        near(customKD.d[0], 62.5, "custom D smoothing")
        let sample = [1.0, 2, 4, 3, 7, 2, 8, 1, 9, 5]
        let customMACD = StockChartCalculations.macd(sample, fastPeriod: 2, slowPeriod: 4, signalPeriod: 3)
        let defaultMACD = StockChartCalculations.macd(sample)
        precondition(customMACD.dif.last! != defaultMACD.dif.last!)
        var settings = ChartIndicatorSettings()
        settings.ma[0].period = 3
        settings.ma[1].isEnabled = false
        settings.bollPeriod = 3
        settings.bollStandardDeviations = 1
        settings.macdFast = 2
        settings.kdjKSmoothing = 2
        settings.rsi[0].period = 3
        precondition(settings.ma.enabledSlotIndices == [0, 2, 3, 4], "disabled MA must not shift remaining color slots")
        var slotSettings = ChartIndicatorSettings()
        slotSettings.ma[0].isEnabled = false
        slotSettings.ma[5].isEnabled = true
        slotSettings.ema[0].isEnabled = false
        slotSettings.rsi[0].isEnabled = false
        precondition(slotSettings.ma.enabledSlotIndices == [1, 2, 3, 4, 5])
        precondition(slotSettings.ema.enabledSlotIndices == [1, 2, 3, 4])
        precondition(slotSettings.rsi.enabledSlotIndices == [1, 2])
        let serialized = try! JSONEncoder().encode(slotSettings)
        precondition(try! JSONDecoder().decode(ChartIndicatorSettings.self, from: serialized) == slotSettings)
        var limits = ChartIndicatorSettings()
        limits.bollPeriod = 1
        precondition(limits.normalized.bollPeriod == 1)
        limits.bollPeriod = 101
        precondition(limits.normalized.bollPeriod == 100)
        let configured = StockChartSeriesCache.series(for: oneDay, period: .intraday, settings: settings)
        let closes = oneDay.candles.map(\.close)
        precondition(configured.ma.count == 4)
        near(configured.ma[0][2], StockChartCalculations.ma(closes, period: 3)[2]!, "configured MA")
        near(configured.boll.upper[2], StockChartCalculations.boll(closes, period: 3, standardDeviations: 1).upper[2]!, "configured BOLL")
        near(configured.macd.dif[20], StockChartCalculations.macd(closes, fastPeriod: 2).dif[20]!, "configured MACD")
        precondition(configured.rsi[0][2] != nil, "configured RSI")
        let cachedConfigured = StockChartSeriesCache.series(for: oneDay, period: .intraday, settings: settings)
        precondition(configured.ma[0].withUnsafeBufferPointer { $0.baseAddress } == cachedConfigured.ma[0].withUnsafeBufferPointer { $0.baseAddress })
        precondition(intradaySeries.ma[0][2] == nil, "settings must isolate cached series")
        let sar = StockChartCalculations.sar([candle(10, 8, 9), candle(11, 9, 10), candle(12, 10, 11), candle(9, 7, 8)])
        near(sar[0], 8, "SAR initial"); near(sar[1], 8, "SAR clamp"); near(sar[3], 12, "SAR reversal")
        precondition(StockChartCalculations.ma([1, 2], period: 0).allSatisfy { $0 == nil })
        precondition(StockChartCalculations.rsi([1, 2], period: 3).allSatisfy { $0 == nil })
        precondition(StockChartCalculations.sar([]).isEmpty)
        precondition(StockChartCalculations.ema([], period: 3).isEmpty)
        let corporateColors: [(Int?, Bool, String)] = [
            (1, false, "chart_mark_finance_red_up"),
            (1, true, "chart_mark_finance_green_up"),
            (-1, false, "chart_mark_finance_green_down"),
            (-1, true, "chart_mark_finance_red_down"),
            (0, false, "chart_mark_finance_gray"),
            (0, true, "chart_mark_finance_gray"),
            (nil, false, "chart_mark_finance_gray"),
            (nil, true, "chart_mark_finance_gray"),
            (42, false, "chart_mark_finance_gray"),
            (42, true, "chart_mark_finance_gray")
        ]
        for (type, reversed, asset) in corporateColors {
            precondition(StockChartCorporateAppearance.imageName(colorType: type, reversed: reversed) == asset,
                         "Corporate marker color type \(String(describing: type)), reversed \(reversed)")
        }
        print("StockChartDataTests passed")
    }
}
