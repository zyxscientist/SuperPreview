import Foundation

enum StockChartPeriod: String, CaseIterable {
    case intraday, fiveDays, day, week, month
    case minute1, minute5, minute15, minute30, minute60

    var isIntraday: Bool { self == .intraday || self == .fiveDays }
}

struct StockChartCandle {
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct StockChartDataset {
    let candles: [StockChartCandle]
    let referenceClose: Double
    // Only this file can mark a dataset as one of the immutable mock datasets.
    let mockID: StockChartPeriod?

    init(candles: [StockChartCandle], referenceClose: Double) {
        self.candles = candles
        self.referenceClose = referenceClose
        self.mockID = nil
    }

    fileprivate init(candles: [StockChartCandle], referenceClose: Double, mockID: StockChartPeriod) {
        self.candles = candles
        self.referenceClose = referenceClose
        self.mockID = mockID
    }
}

enum StockChartMainIndicator: String, CaseIterable { case none, ma, ema, boll, sar }
enum StockChartSubIndicator: String, CaseIterable { case volume, macd, kdj, rsi }

enum StockChartMock {
    // Dates and price generation are fixed, so changing stocks or revisiting a period
    // never silently changes the chart. Prices are illustrative, not market data.
    private static let cache: [StockChartPeriod: StockChartDataset] = makeDatasets()
    static func dataset(for period: StockChartPeriod) -> StockChartDataset { cache[period]! }

    private static func makeDatasets() -> [StockChartPeriod: StockChartDataset] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let end = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 12))!
        var dates: [Date] = []
        var cursor = end
        while dates.count < 1300 {
            let weekday = calendar.component(.weekday, from: cursor)
            if weekday != 1 && weekday != 7 { dates.append(cursor) }
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        dates.reverse()
        func close(_ i: Int) -> Double {
            let x = Double(i - 1299)
            return 212.45 + x * 0.055 + 6 * sin(x / 67) + 2.3 * sin(x / 17) + 0.7 * sin(x / 4.2)
        }
        var daily: [StockChartCandle] = dates.indices.map { i in
            let open = i == 0 ? close(i) - 0.3 : close(i - 1)
            let last = close(i)
            return StockChartCandle(date: dates[i], open: open,
                high: max(open, last) + 0.55 + 0.55 * abs(sin(Double(i) * 0.73)),
                low: min(open, last) - 0.5 - 0.45 * abs(cos(Double(i) * 0.51)),
                close: last, volume: 7_000_000 + 4_000_000 * abs(sin(Double(i) * 0.19)))
        }
        var sessions: [[StockChartCandle]] = []
        for i in (dates.count - 30)..<dates.count {
            let day = calendar.startOfDay(for: dates[i])
            let start = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: day)!
            let open = daily[i].open
            let target = daily[i].close
            var previous = open
            var candles: [StockChartCandle] = []
            for minute in 0..<390 {
                let progress = Double(minute + 1) / 390
                let wave = sin(progress * .pi) * (0.75 * sin(progress * 13 + Double(i) * 0.2) + 0.3 * sin(progress * 43))
                let value = open + (target - open) * progress + wave
                let spread = 0.03 + 0.025 * abs(sin(Double(minute) * 0.31))
                let volume = 12_000 + 7_000 * abs(cos(progress * .pi * 2)) + 4_000 * abs(sin(Double(minute + i) * 0.29))
                candles.append(StockChartCandle(date: start.addingTimeInterval(Double(minute) * 60), open: previous,
                    high: max(previous, value) + spread, low: min(previous, value) - spread,
                    close: value, volume: volume))
                previous = value
            }
            sessions.append(candles)
            daily[i] = aggregate(candles, date: dates[i])!
        }
        let priorClose = daily[daily.count - 2].close
        var result: [StockChartPeriod: StockChartDataset] = [
            .intraday: .init(candles: sessions.last!, referenceClose: priorClose),
            .fiveDays: .init(candles: Array(sessions.suffix(5)).flatMap { $0 }, referenceClose: daily[daily.count - 6].close),
            .day: .init(candles: daily, referenceClose: priorClose)
        ]
        for period in [StockChartPeriod.week, .month] {
            var groups: [[StockChartCandle]] = []
            var previousKey = ""
            for candle in daily {
                let key: String
                if period == .week {
                    key = "\(calendar.component(.yearForWeekOfYear, from: candle.date))-\(calendar.component(.weekOfYear, from: candle.date))"
                } else {
                    key = "\(calendar.component(.year, from: candle.date))-\(calendar.component(.month, from: candle.date))"
                }
                if key != previousKey { groups.append([]); previousKey = key }
                groups[groups.count - 1].append(candle)
            }
            let candles = groups.compactMap { aggregate($0, date: $0.last!.date) }
            result[period] = .init(candles: candles, referenceClose: candles.dropLast().last?.close ?? candles[0].open)
        }
        for (period, size) in [(StockChartPeriod.minute1, 1), (.minute5, 5), (.minute15, 15), (.minute30, 30), (.minute60, 60)] {
            let candles = sessions.flatMap { session -> [StockChartCandle] in
                stride(from: 0, to: session.count, by: size).compactMap { start in
                    let slice = Array(session[start..<min(start + size, session.count)])
                    return aggregate(slice, date: slice[0].date)
                }
            }
            result[period] = .init(candles: candles, referenceClose: priorClose)
        }
        return Dictionary(uniqueKeysWithValues: result.map { period, dataset in
            (period, StockChartDataset(candles: dataset.candles, referenceClose: dataset.referenceClose, mockID: period))
        })
    }

    private static func aggregate(_ candles: [StockChartCandle], date: Date) -> StockChartCandle? {
        guard let first = candles.first, let last = candles.last else { return nil }
        return StockChartCandle(date: date, open: first.open, high: candles.map(\.high).max()!,
                                low: candles.map(\.low).min()!, close: last.close,
                                volume: candles.reduce(0) { $0 + $1.volume })
    }
}

enum StockChartCalculations {
    // YFIndicators uses an integer price scale (up to eight decimal places),
    // including rounding each input before calculating the rolling window.
    private static func scaledValues(_ values: [Double], precision: Int) -> (ticks: [Int64], scale: Double)? {
        let digits = (0...255).contains(precision) ? min(precision, 8) : 0
        let scale = pow(10.0, Double(digits))
        var ticks: [Int64] = []
        ticks.reserveCapacity(values.count)
        for value in values {
            if !value.isFinite {
                ticks.append(0) // Matches the production indicator's nonfinite input handling.
            } else {
                guard let tick = Int64(exactly: (value * scale).rounded(.toNearestOrAwayFromZero)) else { return nil }
                ticks.append(tick)
            }
        }
        return (ticks, scale)
    }

    static func ma(_ values: [Double], period: Int, precision: Int = 3) -> [Double?] {
        guard period > 0 else { return Array(repeating: nil, count: values.count) }
        var out = [Double?](repeating: nil, count: values.count)
        guard period <= values.count, let scaled = scaledValues(values, precision: precision) else { return out }
        var sum: Int64 = 0
        for i in values.indices {
            let added = sum.addingReportingOverflow(scaled.ticks[i])
            guard !added.overflow else { return Array(repeating: nil, count: values.count) }
            sum = added.partialValue
            if i >= period {
                let removed = sum.subtractingReportingOverflow(scaled.ticks[i - period])
                guard !removed.overflow else { return Array(repeating: nil, count: values.count) }
                sum = removed.partialValue
            }
            if i >= period - 1 {
                // Production assumes nonnegative prices/volume and uses integer half-up.
                let rounded = sum.addingReportingOverflow(Int64(period / 2))
                guard !rounded.overflow else { return Array(repeating: nil, count: values.count) }
                out[i] = Double(rounded.partialValue / Int64(period)) / scaled.scale
            }
        }
        return out
    }

    static func ema(_ values: [Double], period: Int) -> [Double?] {
        guard period > 0 else { return Array(repeating: nil, count: values.count) }
        var result = [Double?](repeating: nil, count: values.count)
        var sum = 0.0, current = 0.0
        var count = 0
        let alpha = 2.0 / (Double(period) + 1)
        for i in values.indices where values[i].isFinite {
            count += 1
            if count <= period {
                sum += values[i]
                current = sum / Double(count)
            } else { current = alpha * values[i] + (1 - alpha) * current }
            result[i] = current
        }
        return result
    }

    static func boll(_ values: [Double], period: Int, precision: Int = 3) -> (middle: [Double?], upper: [Double?], lower: [Double?]) {
        var middle = [Double?](repeating: nil, count: values.count)
        var upper = [Double?](repeating: nil, count: values.count)
        var lower = upper
        guard period > 0, period <= values.count, let scaled = scaledValues(values, precision: precision) else { return (middle, upper, lower) }
        var sum: Int64 = 0
        var sumSquares = 0.0
        for i in values.indices {
            let tick = scaled.ticks[i]
            let added = sum.addingReportingOverflow(tick)
            guard !added.overflow else {
                let empty = [Double?](repeating: nil, count: values.count)
                return (empty, empty, empty)
            }
            sum = added.partialValue
            sumSquares += Double(tick) * Double(tick)
            if i >= period {
                let old = scaled.ticks[i - period]
                let removed = sum.subtractingReportingOverflow(old)
                guard !removed.overflow else {
                    let empty = [Double?](repeating: nil, count: values.count)
                    return (empty, empty, empty)
                }
                sum = removed.partialValue
                sumSquares -= Double(old) * Double(old)
            }
            if i >= period - 1 {
                let mean = Double(sum) / Double(period)
                let variance = max(0, sumSquares / Double(period) - mean * mean)
                let width = 2 * sqrt(variance)
                middle[i] = mean.rounded(.toNearestOrAwayFromZero) / scaled.scale
                upper[i] = (mean + width).rounded(.toNearestOrAwayFromZero) / scaled.scale
                lower[i] = (mean - width).rounded(.toNearestOrAwayFromZero) / scaled.scale
            }
        }
        return (middle, upper, lower)
    }

    static func macd(_ values: [Double]) -> (dif: [Double?], dea: [Double?], histogram: [Double?]) {
        let fast = ema(values, period: 12), slow = ema(values, period: 26)
        let dif = values.indices.map { i -> Double? in
            guard let a = fast[i], let b = slow[i] else { return nil }
            return a - b
        }
        let dea = ema(dif.map { $0 ?? .nan }, period: 9)
        let histogram = values.indices.map { i -> Double? in
            guard let a = dif[i], let b = dea[i] else { return nil }
            return 2 * (a - b)
        }
        return (dif, dea, histogram)
    }

    static func kdj(_ candles: [StockChartCandle]) -> (k: [Double?], d: [Double?], j: [Double?]) {
        var k = [Double?](), d = [Double?](), j = [Double?]()
        var previousK = 50.0, previousD = 50.0
        for i in candles.indices {
            let window = candles[max(0, i - 8)...i]
            let high = window.map(\.high).max()!, low = window.map(\.low).min()!
            let rsv = high == low ? 50 : (candles[i].close - low) / (high - low) * 100
            previousK = previousK * 2 / 3 + rsv / 3
            previousD = previousD * 2 / 3 + previousK / 3
            k.append(previousK); d.append(previousD); j.append(3 * previousK - 2 * previousD)
        }
        return (k, d, j)
    }

    static func rsi(_ values: [Double], period: Int) -> [Double?] {
        var result = [Double?](repeating: nil, count: values.count)
        guard period > 0, values.count > period, values.allSatisfy(\.isFinite) else { return result }
        if period == 1 {
            for i in 1..<values.count {
                let change = values[i] - values[i - 1]
                result[i - 1] = change == 0 ? 50 : (change > 0 ? 100 : 0)
            }
            return result
        }
        var gain = 0.0, loss = 0.0
        for i in 1..<period {
            let change = values[i] - values[i - 1]
            gain += max(change, 0); loss += max(-change, 0)
        }
        gain /= Double(period - 1); loss /= Double(period - 1)
        func value(_ gain: Double, _ loss: Double) -> Double { loss == 0 ? 100 : 100 - 100 / (1 + gain / loss) }
        result[period - 1] = value(gain, loss)
        for i in period..<values.count {
            let change = values[i] - values[i - 1]
            gain = (gain * Double(period - 1) + max(change, 0)) / Double(period)
            loss = (loss * Double(period - 1) + max(-change, 0)) / Double(period)
            result[i] = value(gain, loss)
        }
        return result
    }

    static func sar(_ candles: [StockChartCandle]) -> [Double?] {
        guard candles.count >= 2 else { return Array(repeating: nil, count: candles.count) }
        var result = [Double?](repeating: nil, count: candles.count)
        var rising = candles[1].close >= candles[0].close
        var current = rising ? candles[0].low : candles[0].high
        var extreme = rising ? max(candles[0].high, candles[1].high) : min(candles[0].low, candles[1].low)
        var acceleration = 0.02
        result[0] = current
        for i in 1..<candles.count {
            current += acceleration * (extreme - current)
            if rising {
                current = min(current, candles[i - 1].low, candles[max(0, i - 2)].low)
                if candles[i].low < current {
                    rising = false; current = extreme; extreme = candles[i].low; acceleration = 0.02
                } else if candles[i].high > extreme {
                    extreme = candles[i].high; acceleration = min(0.2, acceleration + 0.02)
                }
            } else {
                current = max(current, candles[i - 1].high, candles[max(0, i - 2)].high)
                if candles[i].high > current {
                    rising = true; current = extreme; extreme = candles[i].high; acceleration = 0.02
                } else if candles[i].low < extreme {
                    extreme = candles[i].low; acceleration = min(0.2, acceleration + 0.02)
                }
            }
            result[i] = current
        }
        return result
    }
}

/// Immutable full-length series shared by chart views for the fixed mock datasets.
struct StockChartIndicatorSeries {
    let ma: [[Double?]]
    let ema: [[Double?]]
    let boll: (middle: [Double?], upper: [Double?], lower: [Double?])
    let sar: [Double?]
    let macd: (dif: [Double?], dea: [Double?], histogram: [Double?])
    let kdj: (k: [Double?], d: [Double?], j: [Double?])
    let rsi: [[Double?]]
    let volumeMA: [[Double?]]
    let averagePrices: [Double]

    fileprivate init(candles: [StockChartCandle], period: StockChartPeriod) {
        let closes = candles.map(\.close)
        let volumes = candles.map(\.volume)
        ma = [5, 10, 20, 30, 60].map { StockChartCalculations.ma(closes, period: $0) }
        ema = [5, 10, 20, 30, 60].map { StockChartCalculations.ema(closes, period: $0) }
        boll = StockChartCalculations.boll(closes, period: 20)
        sar = StockChartCalculations.sar(candles)
        macd = StockChartCalculations.macd(closes)
        // Production minute charts use rolling price extrema, not bar high/low.
        let kdjCandles = period.isIntraday ? candles.map { candle in
            StockChartCandle(date: candle.date, open: candle.close, high: candle.close,
                             low: candle.close, close: candle.close, volume: candle.volume)
        } : candles
        kdj = StockChartCalculations.kdj(kdjCandles)
        rsi = [6, 12, 24].map { StockChartCalculations.rsi(closes, period: $0) }
        volumeMA = [5, 10, 20].map { StockChartCalculations.ma(volumes, period: $0, precision: 0) }
        var totalPriceVolume = 0.0
        var totalVolume = 0.0
        var previousDay: DateComponents?
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        averagePrices = candles.map { candle in
            let day = calendar.dateComponents([.year, .month, .day], from: candle.date)
            if previousDay != day { totalPriceVolume = 0; totalVolume = 0; previousDay = day }
            totalPriceVolume += candle.close * max(candle.volume, 0)
            totalVolume += max(candle.volume, 0)
            return totalVolume > 0 ? totalPriceVolume / totalVolume : candle.close
        }
    }
}

enum StockChartSeriesCache {
    private static let lock = NSLock()
    private static var cached: [StockChartPeriod: StockChartIndicatorSeries] = [:]

    static func series(for dataset: StockChartDataset, period: StockChartPeriod) -> StockChartIndicatorSeries {
        // Custom data, and a mock used with a different period, never share an entry.
        guard dataset.mockID == period else {
            return StockChartIndicatorSeries(candles: dataset.candles, period: period)
        }
        lock.lock()
        defer { lock.unlock() }
        if let existing = cached[period] { return existing }
        let result = StockChartIndicatorSeries(candles: dataset.candles, period: period)
        cached[period] = result
        return result
    }
}
