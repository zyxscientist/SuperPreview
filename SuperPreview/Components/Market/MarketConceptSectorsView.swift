//
//  MarketConceptSectorsView.swift
//  SuperPreview
//
//  组件名称：概念板块
//  简介：以三列两行展示美股热门概念与代表股票。
//  用于：新市场页的美股分类。
//

import SwiftUI

struct MarketConceptSector: Identifiable {
    let id: String
    let title: DemoCopyKey
    let percentChange: Double
    let leadingStockSymbol: String
    let leadingStockPercentChange: Double

    static let figmaReferenceRows: [[Self]] = [
        [
            Self(id: "artificial-intelligence", title: .marketConceptAI, percentChange: 3.06,
                 leadingStockSymbol: "NVDA", leadingStockPercentChange: 9.73),
            Self(id: "semiconductors", title: .marketConceptSemiconductors, percentChange: 2.48,
                 leadingStockSymbol: "AMD", leadingStockPercentChange: 4.82),
            Self(id: "cloud-computing", title: .marketConceptCloudComputing, percentChange: 1.72,
                 leadingStockSymbol: "MSFT", leadingStockPercentChange: 2.31)
        ],
        [
            Self(id: "electric-vehicles", title: .marketConceptElectricVehicles, percentChange: 1.05,
                 leadingStockSymbol: "TSLA", leadingStockPercentChange: 3.57),
            Self(id: "cybersecurity", title: .marketConceptCybersecurity, percentChange: 2.20,
                 leadingStockSymbol: "CRWD", leadingStockPercentChange: 5.02),
            Self(id: "big-tech", title: .marketConceptBigTech, percentChange: 0.89,
                 leadingStockSymbol: "AAPL", leadingStockPercentChange: 1.32)
        ]
    ]
}

struct MarketConceptSectorsView: View {
    let rows: [[MarketConceptSector]]
    let onShowAll: () -> Void
    let onSelect: (MarketConceptSector) -> Void

    @Environment(\.demoLanguage) private var language

    init(
        rows: [[MarketConceptSector]] = MarketConceptSector.figmaReferenceRows,
        onShowAll: @escaping () -> Void = { /* TODO: connect the concepts destination. */ },
        onSelect: @escaping (MarketConceptSector) -> Void = { _ in
            /* TODO: connect the selected concept destination. */
        }
    ) {
        self.rows = rows
        self.onShowAll = onShowAll
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            VStack(spacing: 24) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    conceptRow(row)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.usConceptSectors")
    }

    private var header: some View {
        Button(action: onShowAll) {
            HStack(spacing: 8) {
                Text(language.text(.marketConceptSectorsTitle))
                    .modifier(CustomFontModifier(size: 18, font: .bold, lineHeight: 28))
                    .foregroundStyle(Color("color-text-30"))

                Spacer(minLength: 0)

                Image("chevron_right_text30_sm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language.actionAccessibilityLabel(
            name: language.text(.marketConceptSectorsTitle),
            action: language.text(.viewAll)
        ))
        .accessibilityIdentifier("market.usConceptSectors.showAll")
    }

    private func conceptRow(_ sectors: [MarketConceptSector]) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(sectors.enumerated()), id: \.element.id) { index, sector in
                if index > 0 {
                    Rectangle()
                        .fill(Color("color-separator-10"))
                        .frame(width: 1, height: 40)
                        .accessibilityHidden(true)
                }

                sectorCell(sector)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectorCell(_ sector: MarketConceptSector) -> some View {
        let title = language.text(sector.title)
        let change = formattedChange(sector.percentChange)
        let leadingChange = formattedChange(sector.leadingStockPercentChange)

        return Button {
            onSelect(sector)
        } label: {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(title)
                        .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))
                        .foregroundStyle(Color("color-text-30"))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)

                    Text(change)
                        .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 24))
                        .foregroundStyle(changeColor(sector.percentChange))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                }

                VStack(spacing: 4) {
                    Text(sector.leadingStockSymbol)
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundStyle(Color("color-text-30"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 76, height: 16)

                    Text(leadingChange)
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundStyle(changeColor(sector.leadingStockPercentChange))
                        .frame(width: 76, height: 16)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: language.text(.marketConceptAccessibilityFormat), title, change, sector.leadingStockSymbol, leadingChange))
        .accessibilityIdentifier("market.usConceptSectors.sector.\(sector.id)")
    }

    private func changeColor(_ change: Double) -> Color {
        Color(change >= 0 ? "color-utility3-red" : "color-utility3-green")
    }

    private func formattedChange(_ change: Double) -> String {
        String(format: "%+.2f%%", locale: Locale(identifier: "en_US_POSIX"), change)
    }
}

struct MarketConceptSectorsView_Previews: PreviewProvider {
    static var previews: some View {
        MarketConceptSectorsView()
            .previewLayout(.fixed(width: 402, height: 272))
            .previewDisplayName("美股概念板块")
    }
}
