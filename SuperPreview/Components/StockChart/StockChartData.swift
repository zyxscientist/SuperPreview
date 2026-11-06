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
enum StockChartAdjustment: String, CaseIterable { case forward, backward, none }

struct ChartIndicatorLine: Hashable, Codable {
    var period: Int
    var isEnabled: Bool = true
}

extension Array where Element == ChartIndicatorLine {
    // Series omit disabled slots, but line and legend colors retain slot identity.
    var enabledSlotIndices: [Int] { indices.filter { self[$0].isEnabled } }
}

struct ChartIndicatorSettings: Hashable, Codable {
    var ma: [ChartIndicatorLine] = [5, 10, 20, 30, 60, 120, 250].enumerated().map { ChartIndicatorLine(period: $0.element, isEnabled: $0.offset < 5) }
    var ema: [ChartIndicatorLine] = [5, 10, 20, 30, 60, 120, 250].enumerated().map { ChartIndicatorLine(period: $0.element, isEnabled: $0.offset < 5) }
    var rsi: [ChartIndicatorLine] = [6, 12, 24].map { ChartIndicatorLine(period: $0) }
    var bollPeriod = 20
    var bollStandardDeviations = 2.0
    var macdFast = 12
    var macdSlow = 26
    var macdSignal = 9
    var kdjPeriod = 9
    var kdjKSmoothing = 3
    var kdjDSmoothing = 3

    // Keep externally supplied settings safe as well as settings from the UI.
    var normalized: ChartIndicatorSettings {
        var result = self
        func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int { min(range.upperBound, max(range.lowerBound, value)) }
        result.ma = ma.map { ChartIndicatorLine(period: clamp($0.period, 1...250), isEnabled: $0.isEnabled) }
        result.ema = ema.map { ChartIndicatorLine(period: clamp($0.period, 2...250), isEnabled: $0.isEnabled) }
        result.rsi = rsi.map { ChartIndicatorLine(period: clamp($0.period, 1...100), isEnabled: $0.isEnabled) }
        result.bollPeriod = clamp(bollPeriod, 1...100)
        result.bollStandardDeviations = bollStandardDeviations.isFinite ? min(5, max(0.1, bollStandardDeviations)) : 2
        result.macdFast = clamp(macdFast, 2...100)
        result.macdSlow = clamp(macdSlow, 2...100)
        result.macdSignal = clamp(macdSignal, 2...100)
        result.kdjPeriod = clamp(kdjPeriod, 2...100)
        result.kdjKSmoothing = clamp(kdjKSmoothing, 1...50)
        result.kdjDSmoothing = clamp(kdjDSmoothing, 1...50)
        return result
    }
}

enum StockChartMock {
    // Dates and price generation are fixed, so changing stocks or revisiting a period
    // never silently changes the chart. Prices are illustrative, not market data.
    private static let cache: [StockChartPeriod: StockChartDataset] = makeDatasets()
    private static let adjustmentLock = NSLock()
    private static var adjustmentCache: [StockChartPeriod: [StockChartAdjustment: StockChartDataset]] = [:]
    static func dataset(for period: StockChartPeriod) -> StockChartDataset { cache[period]! }

    /// Synthetic 2:1 split on a Monday that is also the first of the month.
    /// The original continuous history represents forward-adjusted prices.
    static func adjustedDataset(for period: StockChartPeriod, adjustment: StockChartAdjustment) -> StockChartDataset {
        let original = dataset(for: period)
        guard [.day, .week, .month].contains(period), adjustment != .forward else { return original }
        adjustmentLock.lock()
        defer { adjustmentLock.unlock() }
        if let cached = adjustmentCache[period]?[adjustment] { return cached }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let splitDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        let daily = dataset(for: .day).candles.map { candle -> StockChartCandle in
            let scale: Double = adjustment == .backward || candle.date < splitDate ? 2 : 1
            return StockChartCandle(date: candle.date, open: candle.open * scale, high: candle.high * scale,
                                    low: candle.low * scale, close: candle.close * scale, volume: candle.volume / scale)
        }
        let adjusted: [StockChartCandle]
        if period == .day {
            adjusted = daily
        } else {
            var groups: [[StockChartCandle]] = []
            var previousKey = ""
            for candle in daily {
                let key = period == .week
                    ? "\(calendar.component(.yearForWeekOfYear, from: candle.date))-\(calendar.component(.weekOfYear, from: candle.date))"
                    : "\(calendar.component(.year, from: candle.date))-\(calendar.component(.month, from: candle.date))"
                if key != previousKey { groups.append([]); previousKey = key }
                groups[groups.count - 1].append(candle)
            }
            adjusted = groups.compactMap { aggregate($0, date: $0.last!.date) }
        }
        let reference = adjustment == .backward ? original.referenceClose * 2 : original.referenceClose
        // No mockID: the existing indicator cache is keyed only by period.
        let result = StockChartDataset(candles: adjusted, referenceClose: reference)
        adjustmentCache[period, default: [:]][adjustment] = result
        return result
    }

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
            // A seeded random walk supplies irregular minute-to-minute movement. A
            // linear bridge retains the daily close without flattening the path.
            var seed = UInt64(i + 1) &* 0x9E3779B97F4A7C15
            func random() -> Double {
                seed ^= seed >> 12
                seed ^= seed << 25
                seed ^= seed >> 27
                return Double((seed &* 2685821657736338717) >> 11) / 9_007_199_254_740_992
            }
            var path: [Double] = []
            var displacement = 0.0
            var momentum = 0.0
            for minute in 0..<390 {
                let progress = Double(minute) / 389
                let activity = 1 + 1.1 * exp(-progress * 14) + 0.65 * exp(-(1 - progress) * 12)
                let shock = (random() + random() + random() - 1.5) * 0.075 * activity
                momentum = 0.25 * momentum + shock
                displacement += momentum
                path.append(displacement)
            }
            var previous = open
            var candles: [StockChartCandle] = []
            for minute in 0..<390 {
                let progress = Double(minute + 1) / 390
                let value = open + (target - open) * progress + path[minute] - path[389] * progress
                let spread = 0.008 + random() * 0.025
                // Trading activity is normally heavier near the open and close,
                // with irregular minute volume and occasional bursts.
                let activity = 1 + 2.4 * exp(-progress * 14) + 1.6 * exp(-(1 - progress) * 12)
                let burst = random() < 0.025 ? 1.8 + random() : 1.0
                let volume = (15_000 * activity * (0.45 + random() * 1.1) * burst).rounded()
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

    static func boll(_ values: [Double], period: Int, standardDeviations: Double = 2, precision: Int = 3) -> (middle: [Double?], upper: [Double?], lower: [Double?]) {
        var middle = [Double?](repeating: nil, count: values.count)
        var upper = [Double?](repeating: nil, count: values.count)
        var lower = upper
        guard period > 0, standardDeviations.isFinite, standardDeviations > 0, period <= values.count, let scaled = scaledValues(values, precision: precision) else { return (middle, upper, lower) }
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
                let width = standardDeviations * sqrt(variance)
                middle[i] = mean.rounded(.toNearestOrAwayFromZero) / scaled.scale
                upper[i] = (mean + width).rounded(.toNearestOrAwayFromZero) / scaled.scale
                lower[i] = (mean - width).rounded(.toNearestOrAwayFromZero) / scaled.scale
            }
        }
        return (middle, upper, lower)
    }

    static func macd(_ values: [Double], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> (dif: [Double?], dea: [Double?], histogram: [Double?]) {
        let fast = ema(values, period: fastPeriod), slow = ema(values, period: slowPeriod)
        let dif = values.indices.map { i -> Double? in
            guard let a = fast[i], let b = slow[i] else { return nil }
            return a - b
        }
        let dea = ema(dif.map { $0 ?? .nan }, period: signalPeriod)
        let histogram = values.indices.map { i -> Double? in
            guard let a = dif[i], let b = dea[i] else { return nil }
            return 2 * (a - b)
        }
        return (dif, dea, histogram)
    }

    static func kdj(_ candles: [StockChartCandle], period: Int = 9, kSmoothing: Int = 3, dSmoothing: Int = 3) -> (k: [Double?], d: [Double?], j: [Double?]) {
        guard period > 0, kSmoothing > 0, dSmoothing > 0 else {
            let empty = [Double?](repeating: nil, count: candles.count)
            return (empty, empty, empty)
        }
        var k = [Double?](), d = [Double?](), j = [Double?]()
        var previousK = 50.0, previousD = 50.0
        for i in candles.indices {
            let window = candles[max(0, i - period + 1)...i]
            let high = window.map(\.high).max()!, low = window.map(\.low).min()!
            let rsv = high == low ? 50 : (candles[i].close - low) / (high - low) * 100
            previousK = (previousK * Double(kSmoothing - 1) + rsv) / Double(kSmoothing)
            previousD = (previousD * Double(dSmoothing - 1) + previousK) / Double(dSmoothing)
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
                result[i] = change == 0 ? 50 : (change > 0 ? 100 : 0)
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

    fileprivate init(candles: [StockChartCandle], period: StockChartPeriod, settings: ChartIndicatorSettings) {
        let closes = candles.map(\.close)
        let volumes = candles.map(\.volume)
        ma = settings.ma.filter(\.isEnabled).map { StockChartCalculations.ma(closes, period: $0.period) }
        ema = settings.ema.filter(\.isEnabled).map { StockChartCalculations.ema(closes, period: $0.period) }
        boll = StockChartCalculations.boll(closes, period: settings.bollPeriod, standardDeviations: settings.bollStandardDeviations)
        sar = StockChartCalculations.sar(candles)
        macd = StockChartCalculations.macd(closes, fastPeriod: settings.macdFast, slowPeriod: settings.macdSlow, signalPeriod: settings.macdSignal)
        // Production minute charts use rolling price extrema, not bar high/low.
        let kdjCandles = period.isIntraday ? candles.map { candle in
            StockChartCandle(date: candle.date, open: candle.close, high: candle.close,
                             low: candle.close, close: candle.close, volume: candle.volume)
        } : candles
        kdj = StockChartCalculations.kdj(kdjCandles, period: settings.kdjPeriod, kSmoothing: settings.kdjKSmoothing, dSmoothing: settings.kdjDSmoothing)
        rsi = settings.rsi.filter(\.isEnabled).map { StockChartCalculations.rsi(closes, period: $0.period) }
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
    private struct Key: Hashable {
        let period: StockChartPeriod
        let settings: ChartIndicatorSettings
    }
    private static var cached: [Key: StockChartIndicatorSeries] = [:]

    static func series(for dataset: StockChartDataset, period: StockChartPeriod, settings: ChartIndicatorSettings = .init()) -> StockChartIndicatorSeries {
        let settings = settings.normalized
        // Custom data, and a mock used with a different period, never share an entry.
        guard dataset.mockID == period else {
            return StockChartIndicatorSeries(candles: dataset.candles, period: period, settings: settings)
        }
        lock.lock()
        defer { lock.unlock() }
        let key = Key(period: period, settings: settings)
        if let existing = cached[key] { return existing }
        let result = StockChartIndicatorSeries(candles: dataset.candles, period: period, settings: settings)
        if cached.count >= 24 { cached.removeAll() }
        cached[key] = result
        return result
    }
}
