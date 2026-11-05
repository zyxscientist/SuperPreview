//
//  StockDetailChart.swift
//  SuperPreview
//
//  组件名称：详情页行情图表
//  简介：展示股票详情页的静态行情图表预览。
//  用于：股票详情页报价区域下方的图表占位内容。
//

import SwiftUI
import UIKit

/// A chart placeholder for the stock-detail prototype.
///
/// The production chart is intentionally represented by the same static
/// snapshot used by the stock-order prototype until the chart interaction and
/// rendering model are implemented.
struct StockDetailChart: View {
    static let snapshotAspectRatio: CGFloat = 402.0 / 409.0

    var body: some View {
        MarketChartSnapshot()
            .aspectRatio(Self.snapshotAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Stock chart preview")
            .accessibilityIdentifier("stockDetail.chart")
    }
}

/// The prototype screenshot includes both price labels and independent trade
/// directions. Only the ten price-label rectangles are recolored.
struct MarketChartSnapshot: View {
    @Environment(\.marketColorReversed) private var reversed
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if reversed, let image = MarketChartSnapshotImages.reversed(for: colorScheme) {
            Image(uiImage: image).resizable()
        } else {
            Image("stock_order_chart_snapshot").resizable()
        }
    }
}

private enum MarketChartSnapshotImages {
    private static let light = makeReversed(dark: false)
    private static let dark = makeReversed(dark: true)

    static func reversed(for scheme: ColorScheme) -> UIImage? {
        scheme == .dark ? dark : light
    }

    private static func makeReversed(dark: Bool) -> UIImage? {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        guard let image = UIImage(named: "stock_order_chart_snapshot", in: nil, compatibleWith: traits),
              let source = image.cgImage, source.width == 1608, source.height == 1636,
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let width = source.width, height = source.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        return pixels.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return nil }
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            let red: [Double] = dark ? [245, 61, 61] : [254, 74, 74]
            let green: [Double] = dark ? [5, 167, 125] : [0, 186, 138]
            let backgrounds: [[Double]] = dark ? [[21, 21, 21], [21, 30, 44]] : [[255, 255, 255], [232, 240, 255]]
            let rows = [138...167, 319...348, 530...559, 737...766, 926...955]
            let columns = [48...160, 885...1039]
            let p = bytes.bindMemory(to: UInt8.self)
            for rowslice in rows { for y in rowslice { for columnslice in columns { for x in columnslice {
                let offset = (y * width + x) * 4
                let rgb = (0..<3).map { Double(p[offset + $0]) }
                var bestError = 5.0
                var replacement: [Double]?
                // Fit the pixel as an antialiased blend of a known label color
                // and a known screenshot background. Unmatched pixels stay intact.
                for (from, to) in [(red, green), (green, red)] { for background in backgrounds {
                    let delta = (0..<3).map { from[$0] - background[$0] }
                    let denominator = delta.reduce(0) { $0 + $1 * $1 }
                    let alpha = min(1, max(0, (0..<3).reduce(0.0) { $0 + (rgb[$1] - background[$1]) * delta[$1] } / denominator))
                    guard alpha >= 0.12 else { continue }
                    let error = (0..<3).reduce(0.0) { $0 + pow(rgb[$1] - (background[$1] + alpha * delta[$1]), 2) }.squareRoot()
                    if error < bestError {
                        bestError = error
                        replacement = (0..<3).map { background[$0] + alpha * (to[$0] - background[$0]) }
                    }
                }}
                if let replacement {
                    for channel in 0..<3 { p[offset + channel] = UInt8(clamping: Int(replacement[channel].rounded())) }
                }
            }}}}
            guard let result = context.makeImage() else { return nil }
            return UIImage(cgImage: result, scale: image.scale, orientation: image.imageOrientation)
        }
    }
}

struct StockDetailChart_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailChart()
                .previewDisplayName("Light")

            StockDetailChart()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
