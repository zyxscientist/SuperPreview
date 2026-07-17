//
//  AssetChart.swift
//  SuperPreview
//

import SwiftUI

struct AssetChart: View {
    var body: some View {
        ZStack {
            centerLine

            AssetTrendShape()
                .stroke(
                    Color("color-brand-blue"),
                    style: StrokeStyle(
                        lineWidth: 1.5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        }
        .frame(width: 96, height: 55)
        .clipped()
        .accessibilityHidden(true)
    }

    private var centerLine: some View {
        GeometryReader { proxy in
            Path { path in
                let centerY = proxy.size.height / 2
                path.move(to: CGPoint(x: 0, y: centerY))
                path.addLine(to: CGPoint(x: proxy.size.width, y: centerY))
            }
            .stroke(
                Color("color-separator-20"),
                style: StrokeStyle(lineWidth: 0.5, dash: [2, 2])
            )
        }
    }
}

private struct AssetTrendShape: Shape {
    private static let viewBox = CGSize(width: 96, height: 55)

    private static let points: [CGPoint] = [
        CGPoint(x: 0, y: 55),
        CGPoint(x: 3.19994, y: 51.613),
        CGPoint(x: 6.40006, y: 36.5746),
        CGPoint(x: 9.6, y: 47.1311),
        CGPoint(x: 12.7999, y: 36.9733),
        CGPoint(x: 16.0001, y: 39.0114),
        CGPoint(x: 19.2, y: 27.6176),
        CGPoint(x: 22.3999, y: 28.4225),
        CGPoint(x: 25.6001, y: 46.6568),
        CGPoint(x: 28.8, y: 53.7422),
        CGPoint(x: 31.9999, y: 53.6197),
        CGPoint(x: 35.2001, y: 51.4464),
        CGPoint(x: 38.4, y: 51.2707),
        CGPoint(x: 41.5999, y: 51.168),
        CGPoint(x: 44.8001, y: 48.4442),
        CGPoint(x: 48, y: 47.954),
        CGPoint(x: 51.1999, y: 48.9393),
        CGPoint(x: 54.4001, y: 49.8814),
        CGPoint(x: 57.6, y: 43.586),
        CGPoint(x: 60.7999, y: 49.8239),
        CGPoint(x: 64.0001, y: 53.3078),
        CGPoint(x: 67.2, y: 49.7036),
        CGPoint(x: 70.3999, y: 51.9547),
        CGPoint(x: 73.6001, y: 54.5348),
        CGPoint(x: 76.8, y: 51.2659),
        CGPoint(x: 79.9999, y: 45.6805),
        CGPoint(x: 83.2001, y: 26.3119),
        CGPoint(x: 86.4, y: 10.202),
        CGPoint(x: 89.5999, y: 20.281),
        CGPoint(x: 93, y: 0.746185),
        CGPoint(x: 95, y: 17.5)
    ]

    func path(in rect: CGRect) -> Path {
        guard let firstPoint = Self.points.first else {
            return Path()
        }

        let scaleX = rect.width / Self.viewBox.width
        let scaleY = rect.height / Self.viewBox.height

        func scaled(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: rect.minX + point.x * scaleX,
                y: rect.minY + point.y * scaleY
            )
        }

        var path = Path()
        path.move(to: scaled(firstPoint))

        for point in Self.points.dropFirst() {
            path.addLine(to: scaled(point))
        }

        return path
    }
}

struct AssetChart_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AssetChart()
                .padding()
                .background(Color("color-base-1"))
                .previewDisplayName("Light")

            AssetChart()
                .padding()
                .background(Color("color-base-1"))
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
        .previewLayout(.sizeThatFits)
    }
}
