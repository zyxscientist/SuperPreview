import UIKit
import SwiftUI

/// Core Graphics chart modelled on the stock-detail chart's fixed-pixel layout.
final class StockChartCanvasView: UIView, UIGestureRecognizerDelegate {
    static func height(subchartCount: Int) -> CGFloat { 225 + 108 * CGFloat(max(0, subchartCount)) }

    var onInteraction: (() -> Void)?
    var onSelection: ((StockChartCandle?) -> Void)?
    var onExpand: (() -> Void)?

    private var dataset: StockChartDataset?
    private var period: StockChartPeriod = .day
    private var mainIndicators: [StockChartMainIndicator] = [.ma]
    private var legendExpanded = true
    private let legendButton = UIButton(type: .custom)
    private lazy var chartAccessibility = UIAccessibilityElement(accessibilityContainer: self)
    private var subIndicators: [StockChartSubIndicator] = []
    private var reversed = false
    private var language: DemoLanguage = .simplifiedChinese
    private var start: CGFloat = 0
    private var visibleCount: CGFloat = 60
    private var selectedIndex: Int?
    private var selectionDismissal: DispatchWorkItem?
    private var panOrigin: CGFloat = 0
    private var pinchOriginCount: CGFloat = 60
    private var pinchAnchorIndex: CGFloat = 0
    private var pinchAnchorFraction: CGFloat = 0.5
    private var displayLink: CADisplayLink?
    private var velocity: CGFloat = 0
    private var lastTick: CFTimeInterval = 0
    private var maLines: [[Double?]] = []
    private var emaLines: [[Double?]] = []
    private var bollLines: (middle: [Double?], upper: [Double?], lower: [Double?]) = ([], [], [])
    private var sarValues: [Double?] = []
    private var macdValues: (dif: [Double?], dea: [Double?], histogram: [Double?]) = ([], [], [])
    private var kdjValues: (k: [Double?], d: [Double?], j: [Double?]) = ([], [], [])
    private var rsiLines: [[Double?]] = []
    private var volumeMA: [[Double?]] = []
    private var averagePrices: [Double] = []

    // CommonColorConfig.plist chartMA1...chartMA5, independent of market direction.
    private let lineColors: [UIColor] = [
        UIColor(red: 255 / 255, green: 166 / 255, blue: 80 / 255, alpha: 1),
        UIColor(red: 55 / 255, green: 155 / 255, blue: 255 / 255, alpha: 1),
        UIColor(red: 214 / 255, green: 103 / 255, blue: 205 / 255, alpha: 1),
        UIColor(red: 233 / 255, green: 208 / 255, blue: 80 / 255, alpha: 1),
        UIColor(red: 80 / 255, green: 213 / 255, blue: 227 / 255, alpha: 1)
    ]
    private var upColor: UIColor { UIColor(MarketColor.resolve("color-utility3-red", reversed: reversed)) }
    private var downColor: UIColor { UIColor(MarketColor.resolve("color-utility3-green", reversed: reversed)) }
    private var textColor: UIColor { UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.65, alpha: 1) : UIColor(white: 0.42, alpha: 1) } }
    private var gridColor: UIColor { UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.10) : UIColor(white: 0, alpha: 0.09) } }
    private var mainRect: CGRect {
        // CSGBaseConverter reserves one 20pt title band whenever any main
        // indicator is selected. Wrapped/stacked legend rows float over it.
        let top: CGFloat = period.isIntraday || !mainIndicators.isEmpty ? 20 : 0
        return CGRect(x: 0, y: top, width: bounds.width, height: 209 - top)
    }
    private var pointCount: Int { dataset?.candles.count ?? 0 }
    private var range: Range<Int> {
        let first = max(0, min(Int(start.rounded(.down)), max(0, pointCount - 1)))
        return first..<min(pointCount, first + max(1, Int(visibleCount.rounded(.up))))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isAccessibilityElement = false
        chartAccessibility.accessibilityIdentifier = "stockDetail.chart.canvas"
        chartAccessibility.accessibilityTraits = .image
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panChanged(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchChanged(_:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.delegate = self
        addGestureRecognizer(longPress)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        addGestureRecognizer(doubleTap)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.delegate = self
        tap.require(toFail: longPress)
        tap.require(toFail: doubleTap)
        addGestureRecognizer(tap)
        legendButton.frame = CGRect(x: 0, y: 2, width: 26, height: 16)
        legendButton.layer.cornerRadius = 3
        legendButton.layer.borderWidth = 0.5
        legendButton.addTarget(self, action: #selector(toggleLegend), for: .touchUpInside)
        legendButton.accessibilityIdentifier = "stockDetail.chart.indicatorFold"
        addSubview(legendButton)
        accessibilityElements = [chartAccessibility, legendButton]
        updateAccessibility()
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func configure(dataset: StockChartDataset, period: StockChartPeriod, mainIndicators: [StockChartMainIndicator], subIndicators: [StockChartSubIndicator], reversed: Bool, language: DemoLanguage) {
        let dataChanged = !sameData(self.dataset, dataset) || self.period != period
        self.dataset = dataset
        self.period = period
        self.mainIndicators = mainIndicators.filter { $0 != .none }
        self.subIndicators = subIndicators
        self.reversed = reversed
        self.language = language
        refreshLegendButton()
        if dataChanged {
            calculateIndicators(dataset, period: period)
            visibleCount = period.isIntraday ? CGFloat(max(1, dataset.candles.count)) : CGFloat(max(1, min(60, dataset.candles.count)))
            resetToLatest()
        } else {
            setNeedsDisplay()
            updateAccessibility()
        }
    }

    private func sameData(_ old: StockChartDataset?, _ new: StockChartDataset) -> Bool {
        guard let old, old.referenceClose == new.referenceClose, old.candles.count == new.candles.count else { return false }
        if let oldID = old.mockID, let newID = new.mockID { return oldID == newID }
        return zip(old.candles, new.candles).allSatisfy { a, b in
            a.date == b.date && a.open == b.open && a.high == b.high && a.low == b.low && a.close == b.close && a.volume == b.volume
        }
    }

    private func calculateIndicators(_ dataset: StockChartDataset, period: StockChartPeriod) {
        let series = StockChartSeriesCache.series(for: dataset, period: period)
        maLines = series.ma
        emaLines = series.ema
        bollLines = series.boll
        sarValues = series.sar
        macdValues = series.macd
        kdjValues = series.kdj
        rsiLines = series.rsi
        volumeMA = series.volumeMA
        averagePrices = series.averagePrices
    }

    func resetToLatest() {
        stopInertia()
        start = max(0, CGFloat(pointCount) - visibleCount)
        selectionDismissal?.cancel()
        selectedIndex = nil
        onSelection?(nil)
        updateAccessibility()
        setNeedsDisplay()
    }

    func zoom(by factor: CGFloat) {
        guard !period.isIntraday, factor.isFinite, factor > 0 else { return }
        let anchor = start + visibleCount / 2
        visibleCount = clampedVisibleCount(visibleCount / factor)
        start = anchor - visibleCount / 2
        clampStart()
        changed()
    }

    @objc private func toggleLegend() {
        legendExpanded.toggle()
        refreshLegendButton()
        setNeedsDisplay()
    }
    private func refreshLegendButton() {
        legendButton.isHidden = period.isIntraday || mainIndicators.isEmpty
        legendButton.setImage(UIImage(named: legendExpanded ? "stock_chart_indicator_up" : "stock_chart_indicator_down"), for: .normal)
        legendButton.layer.borderColor = gridColor.resolvedColor(with: traitCollection).cgColor
        legendButton.accessibilityLabel = legendExpanded ? localized("收起指标", "收起指標", "Collapse indicators") : localized("展开指标", "展開指標", "Expand indicators")
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { stopInertia() }
    }

    private func clampedVisibleCount(_ count: CGFloat) -> CGFloat {
        let upper = CGFloat(max(1, min(pointCount, 300)))
        return min(upper, max(min(12, upper), count))
    }
    private func clampStart() { start = min(max(0, start), max(0, CGFloat(pointCount) - visibleCount)) }
    private func changed() { updateAccessibility(); setNeedsDisplay(); onInteraction?() }
    private func updateAccessibility() {
        chartAccessibility.accessibilityLabel = stockChartText(.mainIndicator, language: language)
        chartAccessibility.accessibilityValue = "period=\(period.rawValue),start=\(Int(start.rounded())),count=\(Int(visibleCount.rounded())),selected=\(selectedIndex.map(String.init) ?? "none"),reversed=\(reversed),main=\(mainIndicators.map(\.rawValue).joined(separator: "+")),sub=\(subIndicators.map(\.rawValue).joined(separator: "+"))"
        chartAccessibility.accessibilityFrameInContainerSpace = bounds
        accessibilityElements = legendButton.isHidden ? [chartAccessibility] : [chartAccessibility, legendButton]
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let v = pan.velocity(in: self)
            return !period.isIntraday && abs(v.x) > abs(v.y)
        }
        if gestureRecognizer is UIPinchGestureRecognizer { return !period.isIntraday }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view, current !== self {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Preserve the host's native edge-back gesture. Ordinary page pans
        // still wait for the chart to decide whether a drag is horizontal.
        if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer { return false }
        guard let otherView = otherGestureRecognizer.view, otherView !== self, isDescendant(of: otherView) else { return false }
        if gestureRecognizer is UITapGestureRecognizer { return otherGestureRecognizer is UITapGestureRecognizer }
        return (gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIPinchGestureRecognizer || gestureRecognizer is UILongPressGestureRecognizer) && otherGestureRecognizer is UIPanGestureRecognizer
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }

    @objc private func panChanged(_ gesture: UIPanGestureRecognizer) {
        guard !period.isIntraday, bounds.width > 0 else { return }
        if gesture.state == .began { stopInertia(); panOrigin = start; selectedIndex = nil; onSelection?(nil) }
        if gesture.state == .changed {
            start = panOrigin - gesture.translation(in: self).x / bounds.width * visibleCount
            clampStart(); changed()
        } else if gesture.state == .ended {
            velocity = -gesture.velocity(in: self).x / bounds.width * visibleCount
            if abs(velocity) > 1 {
                lastTick = 0
                let link = CADisplayLink(target: self, selector: #selector(animateInertia(_:)))
                link.add(to: .main, forMode: .common)
                displayLink = link
            }
        }
    }

    @objc private func animateInertia(_ link: CADisplayLink) {
        guard lastTick > 0 else { lastTick = link.timestamp; return }
        let dt = min(link.timestamp - lastTick, 0.05)
        lastTick = link.timestamp
        let before = start
        start += velocity * CGFloat(dt)
        clampStart()
        velocity *= pow(0.95, CGFloat(dt * 60))
        changed()
        if abs(velocity) < 0.5 || start == before { stopInertia() }
    }
    private func stopInertia() { displayLink?.invalidate(); displayLink = nil; velocity = 0; lastTick = 0 }

    @objc private func pinchChanged(_ gesture: UIPinchGestureRecognizer) {
        guard !period.isIntraday, bounds.width > 0 else { return }
        if gesture.state == .began {
            stopInertia()
            pinchOriginCount = visibleCount
            pinchAnchorFraction = min(1, max(0, gesture.location(in: self).x / bounds.width))
            pinchAnchorIndex = start + pinchOriginCount * pinchAnchorFraction
        } else if gesture.state == .changed {
            visibleCount = clampedVisibleCount(pinchOriginCount / gesture.scale)
            start = pinchAnchorIndex - visibleCount * pinchAnchorFraction
            clampStart(); changed()
        }
    }
    @objc private func longPressed(_ gesture: UILongPressGestureRecognizer) {
        guard pointCount > 0, bounds.width > 0 else { return }
        if gesture.state == .began || gesture.state == .changed {
            selectionDismissal?.cancel()
            stopInertia()
            let index = Int(start + gesture.location(in: self).x / bounds.width * visibleCount)
            selectedIndex = max(0, min(pointCount - 1, index))
            if let selectedIndex { onSelection?(dataset?.candles[selectedIndex]) }
            changed()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            let work = DispatchWorkItem { [weak self] in self?.clearSelection() }
            selectionDismissal = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
        }
    }
    private func clearSelection() { selectionDismissal?.cancel(); selectedIndex = nil; onSelection?(nil); changed() }
    @objc private func tapped() { clearSelection() }
    @objc private func doubleTapped() { clearSelection(); onExpand?() }

    override func layoutSubviews() {
        super.layoutSubviews()
        chartAccessibility.accessibilityFrameInContainerSpace = bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) { refreshLegendButton(); setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext(), let dataset, !dataset.candles.isEmpty, bounds.width > 0 else { return }
        let candles = dataset.candles
        let visible = range
        guard !visible.isEmpty else { return }
        var prices = visible.flatMap { [candles[$0].high, candles[$0].low] }.filter(\.isFinite)
        if !period.isIntraday {
            for indicator in mainIndicators {
                for line in linesForMainIndicator(indicator) {
                    prices.append(contentsOf: visible.compactMap { $0 < line.count ? line[$0] : nil }.filter(\.isFinite))
                }
            }
        }
        guard let low = prices.min(), let high = prices.max() else { return }
        let extra = max((high - low) * (period.isIntraday ? 0.20 : 0.12), max(abs(high) * 0.002, 0.01))
        let yLow = max(0, low - extra), yHigh = high + extra
        let priceY: (Double) -> CGFloat = { self.mainRect.maxY - CGFloat(($0 - yLow) / (yHigh - yLow)) * self.mainRect.height }
        let step = bounds.width / max(1, visibleCount)
        let x: (Int) -> CGFloat = { (CGFloat($0) - self.start + 0.5) * step }

        drawGrid(ctx, rect: mainRect, rows: 4)
        ctx.saveGState(); ctx.clip(to: mainRect)
        if period.isIntraday {
            let closes = candles.map { Optional($0.close) }
            if let first = visible.first, let lastIndex = visible.last {
                ctx.setFillColor(UIColor(red: 0.098, green: 0.431, blue: 1, alpha: 0.047).cgColor)
                ctx.move(to: CGPoint(x: x(first), y: mainRect.maxY))
                for i in visible { ctx.addLine(to: CGPoint(x: x(i), y: priceY(candles[i].close))) }
                ctx.addLine(to: CGPoint(x: x(lastIndex), y: mainRect.maxY)); ctx.closePath(); ctx.fillPath()
            }
            drawLine(ctx, values: closes, range: visible, x: x, y: priceY, color: UIColor(red: 0.098, green: 0.431, blue: 1, alpha: 1), width: 1)
            drawLine(ctx, values: averagePrices.map(Optional.some), range: visible, x: x, y: priceY, color: lineColors[0], width: 0.7)
        } else {
            let width = max(0.5, step - (step > 1 ? 1 : 0.5))
            if visibleCount >= 150 {
                drawLine(ctx, values: candles.map { Optional($0.close) }, range: visible, x: x, y: priceY, color: lineColors[1], width: 0.7)
            } else {
                for i in visible {
                    let c = candles[i], color = c.close >= c.open ? upColor : downColor
                    ctx.setStrokeColor(color.resolvedColor(with: traitCollection).cgColor); ctx.setFillColor(color.resolvedColor(with: traitCollection).cgColor); ctx.setLineWidth(0.7)
                    ctx.move(to: CGPoint(x: x(i), y: priceY(c.high))); ctx.addLine(to: CGPoint(x: x(i), y: priceY(c.low))); ctx.strokePath()
                    let top = min(priceY(c.open), priceY(c.close)), h = abs(priceY(c.open) - priceY(c.close))
                    ctx.fill(CGRect(x: x(i) - width / 2, y: top, width: width, height: max(1, h)))
                }
            }
            for indicator in mainIndicators {
                if indicator == .sar {
                    ctx.setFillColor(lineColors[0].cgColor)
                    for i in visible where i < sarValues.count { if let value = sarValues[i], value.isFinite { ctx.fillEllipse(in: CGRect(x: x(i) - 1.5, y: priceY(value) - 1.5, width: 3, height: 3)) } }
                } else {
                    for (i, line) in linesForMainIndicator(indicator).enumerated() { drawLine(ctx, values: line, range: visible, x: x, y: priceY, color: lineColors[i % lineColors.count], width: 0.7) }
                }
            }
        }
        if period.isIntraday, dataset.referenceClose >= yLow, dataset.referenceClose <= yHigh {
            ctx.setStrokeColor(gridColor.resolvedColor(with: traitCollection).cgColor)
            ctx.setLineWidth(1); ctx.setLineDash(phase: 0, lengths: [4, 4]); ctx.move(to: CGPoint(x: 0, y: priceY(dataset.referenceClose))); ctx.addLine(to: CGPoint(x: bounds.width, y: priceY(dataset.referenceClose))); ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
        }
        let last = candles[visible.upperBound - 1].close
        if last >= yLow && last <= yHigh {
            ctx.setStrokeColor(UIColor(red: 0.098, green: 0.431, blue: 1, alpha: 1).cgColor)
            ctx.setLineWidth(1); ctx.setLineDash(phase: 0, lengths: [4, 4]); ctx.move(to: CGPoint(x: 0, y: priceY(last))); ctx.addLine(to: CGPoint(x: bounds.width, y: priceY(last))); ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
        }
        ctx.restoreGState()
        // Match production layer order: plots first, then unobscured axis text.
        for row in 0...4 {
            let value = yHigh - (yHigh - yLow) * Double(row) / 4
            let labelY = mainRect.minY + CGFloat(row) * mainRect.height / 4 - (row == 0 ? 0 : 10)
            drawText(formatPrice(value), at: CGPoint(x: 4, y: labelY), color: textColor, fontSize: 10)
            if period.isIntraday, dataset.referenceClose > 0 {
                let percent = (value / dataset.referenceClose - 1) * 100
                let label = String(format: "%+.2f%%", percent)
                let width = (label as NSString).size(withAttributes: [.font: chartFont(10)]).width
                let color = abs(percent) < 0.0001 ? textColor : percent > 0 ? upColor : downColor
                drawText(label, at: CGPoint(x: bounds.width - width - 4, y: labelY), color: color, fontSize: 10)
            }
        }
        drawMainLegend(candles: candles, index: selectedIndex ?? visible.upperBound - 1)
        drawDates(candles: candles, range: visible, x: x)
        for (index, indicator) in subIndicators.enumerated() { drawSubchart(ctx, indicator: indicator, index: index, candles: candles, visible: visible, x: x, step: step) }
        if let selectedIndex, visible.contains(selectedIndex) {
            let sx = x(selectedIndex), sy = priceY(candles[selectedIndex].close)
            ctx.setStrokeColor(textColor.resolvedColor(with: traitCollection).withAlphaComponent(0.8).cgColor); ctx.setLineWidth(0.7); ctx.setLineDash(phase: 0, lengths: [3, 3])
            ctx.move(to: CGPoint(x: sx, y: mainRect.minY)); ctx.addLine(to: CGPoint(x: sx, y: bounds.height)); ctx.move(to: CGPoint(x: 0, y: sy)); ctx.addLine(to: CGPoint(x: bounds.width, y: sy)); ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
            let label = formatPrice(candles[selectedIndex].close)
            let box = CGRect(x: max(0, bounds.width - 58), y: min(mainRect.maxY - 15, max(mainRect.minY, sy - 7)), width: 58, height: 15)
            textColor.setFill(); UIBezierPath(roundedRect: box, cornerRadius: 2).fill()
            drawText(label, at: CGPoint(x: box.minX + 3, y: box.minY + 1), color: .white, fontSize: 10)
        }
    }

    private func drawGrid(_ ctx: CGContext, rect: CGRect, rows: Int) {
        ctx.setStrokeColor(gridColor.resolvedColor(with: traitCollection).cgColor); ctx.setLineWidth(0.5)
        for row in 0...rows {
            let y = rect.minY + rect.height * CGFloat(row) / CGFloat(rows)
            ctx.move(to: CGPoint(x: rect.minX, y: y)); ctx.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        if period == .fiveDays {
            for day in 1..<5 {
                let x = rect.minX + rect.width * CGFloat(day) / 5
                ctx.move(to: CGPoint(x: x, y: rect.minY)); ctx.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
        }
        ctx.strokePath()
    }

    private func drawLine(_ ctx: CGContext, values: [Double?], range: Range<Int>, x: (Int) -> CGFloat, y: (Double) -> CGFloat, color: UIColor, width: CGFloat) {
        ctx.setStrokeColor(color.resolvedColor(with: traitCollection).cgColor); ctx.setLineWidth(width); ctx.setLineJoin(.round); ctx.setLineCap(.round)
        var started = false
        for i in range where i < values.count {
            guard let value = values[i], value.isFinite else { started = false; continue }
            let point = CGPoint(x: x(i), y: y(value))
            if started { ctx.addLine(to: point) } else { ctx.move(to: point); started = true }
        }
        ctx.strokePath()
    }

    private func drawMainLegend(candles: [StockChartCandle], index: Int) {
        guard index >= 0 && index < candles.count else { return }
        if period.isIntraday {
            let trendColor = UIColor(red: 0.098, green: 0.431, blue: 1, alpha: 1)
            drawSegments([(stockChartText(.price, language: language), trendColor), (formatPrice(candles[index].close), trendColor), (stockChartText(.averagePrice, language: language), lineColors[0]), (formatPrice(averagePrices[index]), lineColors[0])], y: 3)
            return
        }
        guard legendExpanded else { return }
        var rowY: CGFloat = 0
        for indicator in mainIndicators {
            var segments: [(String, UIColor)] = []
            let lines = linesForMainIndicator(indicator)
            let names: [String]
            switch indicator {
            case .none: continue
            case .ma: names = ["MA5", "MA10", "MA20", "MA30", "MA60"]
            case .ema: names = ["EMA5", "EMA10", "EMA20", "EMA30", "EMA60"]
            case .boll: names = ["MID", "UP", "LOW"]
            case .sar: names = ["SAR"]
            }
            for (i, line) in lines.enumerated() {
                let value = index < line.count ? line[index] : nil
                segments.append(("\(names[i]): \(value.map(formatPrice) ?? "--")", lineColors[i % lineColors.count]))
            }
            rowY += drawMainIndicatorBand(segments, y: rowY)
        }
    }

    private func drawMainIndicatorBand(_ segments: [(String, UIColor)], y: CGFloat) -> CGFloat {
        // Production stacks translucent 20/36pt bands over the main plot.
        let inset: CGFloat = 32
        var x = inset
        var line = 0
        var items: [(String, UIColor, CGFloat, Int)] = []
        for (text, color) in segments {
            let width = (text as NSString).size(withAttributes: [.font: chartFont(10)]).width
            if x + width > bounds.width, x > inset { line += 1; x = inset }
            guard line < 2 else { break }
            items.append((text, color, x, line))
            x += width + 6
        }
        let height: CGFloat = items.contains { $0.3 == 1 } ? 36 : 20
        let background = UIColor(named: "color-base-1") ?? .systemBackground
        background.resolvedColor(with: traitCollection).withAlphaComponent(0.8).setFill()
        UIRectFill(CGRect(x: inset, y: y, width: max(0, bounds.width - inset), height: height))
        for (text, color, itemX, itemLine) in items {
            let textY = itemLine == 0 ? (20 - chartFont(10).lineHeight) / 2 : 19
            drawText(text, at: CGPoint(x: itemX, y: y + textY), color: color, fontSize: 10)
        }
        return height
    }

    private func linesForMainIndicator(_ indicator: StockChartMainIndicator) -> [[Double?]] {
        switch indicator {
        case .none: return []
        case .ma: return maLines
        case .ema: return emaLines
        case .boll: return [bollLines.middle, bollLines.upper, bollLines.lower]
        case .sar: return [sarValues]
        }
    }

    @discardableResult private func drawSegments(_ segments: [(String, UIColor)], y: CGFloat, leftInset: CGFloat = 4, maxLines: Int = 1) -> CGFloat {
        var x: CGFloat = leftInset
        var line = 0
        for (text, color) in segments {
            let width = (text as NSString).size(withAttributes: [.font: chartFont(10)]).width
            if x + width > bounds.width { line += 1; x = leftInset }
            if line >= maxLines { break }
            drawText(text, at: CGPoint(x: x, y: y + CGFloat(line) * 16), color: color, fontSize: 10)
            x += width + 6
        }
        return line > 0 ? 36 : 20
    }

    private func drawDates(candles: [StockChartCandle], range: Range<Int>, x: (Int) -> CGFloat) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.timeZone = TimeZone(identifier: "America/New_York")!
        if period == .intraday {
            for (label, fraction) in [("09:30", CGFloat(0)), ("12:45", CGFloat(0.5)), ("16:00", CGFloat(1))] {
                let width = (label as NSString).size(withAttributes: [.font: chartFont(10)]).width
                drawText(label, at: CGPoint(x: min(bounds.width - width - 4, max(4, bounds.width * fraction - width / 2)), y: 211), color: textColor, fontSize: 10)
            }
            return
        }
        if period == .fiveDays {
            formatter.dateFormat = "MM/dd"
            let count = range.count
            for day in 0..<5 {
                let i = min(range.upperBound - 1, range.lowerBound + count * (2 * day + 1) / 10)
                let text = formatter.string(from: candles[i].date)
                let width = (text as NSString).size(withAttributes: [.font: chartFont(10)]).width
                drawText(text, at: CGPoint(x: max(4, min(bounds.width - width - 4, x(i) - width / 2)), y: 211), color: textColor, fontSize: 10)
            }
            return
        }
        formatter.dateFormat = [.minute1, .minute5, .minute15, .minute30, .minute60].contains(period) ? "HH:mm" : "MM/dd"
        let indices = [range.lowerBound, (range.lowerBound + range.upperBound - 1) / 2, range.upperBound - 1]
        for (position, i) in indices.enumerated() {
            let text = formatter.string(from: candles[i].date)
            let width = (text as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)]).width
            let origin = position == 0 ? 4 : position == 2 ? bounds.width - width - 4 : x(i) - width / 2
            drawText(text, at: CGPoint(x: origin, y: 211), color: textColor, fontSize: 10)
        }
    }

    private func drawSubchart(_ ctx: CGContext, indicator: StockChartSubIndicator, index: Int, candles: [StockChartCandle], visible: Range<Int>, x: (Int) -> CGFloat, step: CGFloat) {
        let top = 233 + CGFloat(index) * 108
        let graph = CGRect(x: 0, y: top + 20, width: bounds.width, height: 80)
        let chosen = selectedIndex.flatMap { visible.contains($0) ? $0 : nil } ?? visible.upperBound - 1
        var lines: [[Double?]] = []
        var names: [String] = []
        var bars: [Double?] = []
        switch indicator {
        case .volume:
            bars = candles.map { Optional($0.volume) }; lines = volumeMA; names = ["MA5", "MA10", "MA20"]
        case .macd:
            bars = macdValues.histogram; lines = [macdValues.dif, macdValues.dea]; names = ["DIF", "DEA"]
        case .kdj:
            lines = [kdjValues.k, kdjValues.d, kdjValues.j]; names = ["K", "D", "J"]
        case .rsi:
            lines = rsiLines; names = ["RSI6", "RSI12", "RSI24"]
        }
        var values = (lines + [bars]).flatMap { line in visible.compactMap { $0 < line.count ? line[$0] : nil } }.filter(\.isFinite)
        if indicator == .volume { values.append(0) }
        if indicator == .macd { values.append(0) }
        var low = values.min() ?? 0, high = values.max() ?? 1
        if indicator == .macd { let maxAbs = max(abs(low), abs(high)); low = -maxAbs; high = maxAbs }
        if high <= low { high = low + 1 }
        let y: (Double) -> CGFloat = { graph.maxY - CGFloat(($0 - low) / (high - low)) * graph.height }
        drawGrid(ctx, rect: graph, rows: 2)
        var segments: [(String, UIColor)] = [(indicator == .volume ? stockChartText(.volume, language: language) : indicator.rawValue.uppercased(), textColor)]
        if indicator == .volume, chosen < bars.count, let value = bars[chosen] { segments.append((compact(value), textColor)) }
        for (i, line) in lines.enumerated() {
            let value = chosen < line.count ? line[chosen] : nil
            segments.append(("\(names[i]): \(value.map { indicator == .volume ? compact($0) : formatPrice($0) } ?? "--")", lineColors[i]))
        }
        if indicator == .macd, chosen < bars.count, let value = bars[chosen] { segments.append(("MACD: \(formatPrice(value))", lineColors[2])) }
        drawSegments(segments, y: top + 3)
        ctx.saveGState(); ctx.clip(to: graph)
        if !bars.isEmpty {
            let width = indicator == .macd ? CGFloat(1) : max(0.5, step - (step > 1 ? 1 : 0.5))
            for i in visible where i < bars.count {
                guard let value = bars[i], value.isFinite else { continue }
                let baseline = y(0), topY = min(y(value), baseline)
                let color = indicator == .volume ? (candles[i].close >= candles[i].open ? upColor : downColor) : (value >= 0 ? upColor : downColor)
                ctx.setFillColor(color.resolvedColor(with: traitCollection).cgColor); ctx.fill(CGRect(x: x(i) - width / 2, y: topY, width: width, height: max(0.5, abs(baseline - y(value)))))
            }
        }
        for (i, line) in lines.enumerated() { drawLine(ctx, values: line, range: visible, x: x, y: y, color: lineColors[i], width: 0.7) }
        ctx.restoreGState()
        drawText(compact(high), at: CGPoint(x: 4, y: graph.minY), color: textColor, fontSize: 10)
    }

    private func localized(_ simplified: String, _ traditional: String, _ english: String) -> String {
        switch language { case .simplifiedChinese: return simplified; case .traditionalChinese: return traditional; case .english: return english }
    }
    private func formatPrice(_ value: Double) -> String { value.isFinite ? String(format: "%.3f", value) : "--" }
    private func compact(_ value: Double) -> String {
        guard value.isFinite else { return "--" }
        if abs(value) >= 1_000_000 { return String(format: "%.2fM", value / 1_000_000) }
        if abs(value) >= 1_000 { return String(format: "%.2fK", value / 1_000) }
        return String(format: "%.2f", value)
    }
    private func chartFont(_ size: CGFloat) -> UIFont { UIFont(name: "PlusJakartaSans-Regular", size: size) ?? .systemFont(ofSize: size) }
    private func drawText(_ text: String, at point: CGPoint, color: UIColor, fontSize: CGFloat) {
        (text as NSString).draw(at: point, withAttributes: [.font: chartFont(fontSize), .foregroundColor: color])
    }
}
