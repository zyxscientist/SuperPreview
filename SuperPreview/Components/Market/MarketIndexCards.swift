// Shared index cards for the three equity-market tabs.
import SwiftUI

struct MarketIndexQuote: Identifiable {
    let id: String
    let title: DemoCopyKey
    let value: String
    let change: String
    let percentage: String

    // Design fixtures, not live quotes. Keep quote data separate from presentation.
    static func previews(for tab: String) -> [Self] {
        let indices: [(String, DemoCopyKey)]
        switch tab {
        case "港股":
            indices = [("HSI", .marketIndexHangSeng), ("HSCEI", .marketIndexEnterprises), ("HSCCI", .marketIndexRedChips)]
        case "美股":
            indices = [("DJI", .marketIndexDowJones), ("IXIC", .marketIndexNasdaq), ("SPX", .marketIndexSP500)]
        case "沪深港通":
            indices = [("000001", .marketIndexShanghai), ("399001", .marketIndexShenzhen), ("000300", .marketIndexCSI300)]
        default:
            indices = []
        }
        return indices.map {
            Self(id: $0.0, title: $0.1, value: "19309.52", change: "+94.58", percentage: "+0.94%")
        }
    }
}

struct MarketIndexCards: View {
    let indices: [MarketIndexQuote]
    let reducesGlass: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        // Only the background surfaces belong to the glass compositor.
        // Render all labels and charts afterwards, outside that container.
        ZStack {
            if #available(iOS 26.0, *), !reducesGlass && !reduceTransparency {
                GlassEffectContainer(spacing: 0) {
                    surfaces(usesGlass: true)
                }
                .accessibilityHidden(true)
            } else {
                surfaces(usesGlass: false)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 12) {
                ForEach(indices) { index in
                    MarketIndexCard(quote: index)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.indices")
    }

    private func surfaces(usesGlass: Bool) -> some View {
        HStack(spacing: 12) {
            ForEach(indices) { _ in
                let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
                if #available(iOS 26.0, *), usesGlass {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 133)
                        .glassEffect(.regular, in: shape)
                } else {
                    shape.fill(Color("color-scale-1"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 133)
                }
            }
        }
    }
}

private struct MarketIndexCard: View {
    let quote: MarketIndexQuote
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(language.text(quote.title))
                .modifier(CustomFontModifier(size: 14, font: .regular))
                .foregroundStyle(Color("color-text-30"))
                .frame(height: 20)

            Text(quote.value)
                .modifier(CustomFontModifier(size: 17, font: .bold))
                .frame(height: 24)

            HStack(spacing: 4) {
                Text(quote.change)
                Text(quote.percentage)
            }
            .modifier(CustomFontModifier(size: 11, font: .regular))
            .frame(height: 12)
            .padding(.top, 2)

            MarketIndexSparkline()
                .frame(height: 40)
                .padding(.top, 13)
                .accessibilityHidden(true)
        }
        .foregroundStyle(Color("color-utility3-red"))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .frame(height: 133, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("market.index.\(quote.id)")
    }

}

/// The Figma sparkline rendered as a native path, keeping its stroke in points
/// regardless of card width. Inset the path so round caps are never clipped.
private struct MarketIndexSparkline: View {
    private static let points: [CGPoint] = [
        .init(x: 1, y: 38.5), .init(x: 5.27641, y: 34.0421),
        .init(x: 7.50007, y: 30.2211), .init(x: 10.8355, y: 30.2211),
        .init(x: 12.8121, y: 26.0944), .init(x: 14.0475, y: 28.1648),
        .init(x: 16.2711, y: 24.6068), .init(x: 18.6483, y: 35.0707),
        .init(x: 20.8709, y: 24.6068), .init(x: 26.306, y: 36.2542),
        .init(x: 30.9223, y: 28.1648), .init(x: 34.9473, y: 29.529),
        .init(x: 39.0702, y: 35.0707), .init(x: 40.6056, y: 31.7227),
        .init(x: 42.438, y: 33.3285), .init(x: 44.3385, y: 31.1244),
        .init(x: 46.634, y: 26.985), .init(x: 51.7596, y: 26.0944),
        .init(x: 56.1884, y: 22.7811), .init(x: 58.0607, y: 16.1097),
        .init(x: 62.5482, y: 19.9824), .init(x: 64.8336, y: 15.196),
        .init(x: 69.0456, y: 0.54), .init(x: 73.2244, y: 0.54),
        .init(x: 76.3479, y: 2.3947), .init(x: 78.2974, y: 6.50352),
        .init(x: 82.5929, y: 0.54), .init(x: 85.2747, y: 2.3947),
        .init(x: 88.9249, y: 0.5), .init(x: 92, y: 0.5)
    ]

    var body: some View {
        GeometryReader { geometry in
            let points = Self.points.map {
                CGPoint(x: 0.75 + ($0.x - 1) / 91 * max(geometry.size.width - 1.5, 0),
                        y: 0.75 + ($0.y - 0.5) / 38 * max(geometry.size.height - 1.5, 0))
            }
            let line = Path { path in
                path.addLines(points)
            }
            let area = Path { path in
                path.addLines(points)
                path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: geometry.size.height))
                path.addLine(to: CGPoint(x: points.first?.x ?? 0, y: geometry.size.height))
                path.closeSubpath()
            }
            area.fill(LinearGradient(
                colors: [Color("color-utility3-red").opacity(0.15), Color("color-utility3-red").opacity(0.01)],
                startPoint: .top, endPoint: .bottom
            ))
            line.stroke(Color("color-utility3-red"), style: StrokeStyle(
                lineWidth: 1.5, lineCap: .round, lineJoin: .round
            ))
        }
    }
}
