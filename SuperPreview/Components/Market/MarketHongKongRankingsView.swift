//
//  MarketHongKongRankingsView.swift
//  SuperPreview
//
//  组件名称：港股榜单
//  简介：展示港股报价，支持全部、主板及创业板筛选。
//  用于：市场页港股分类；放入支持 sectionHeaders 吸顶的 LazyVStack。
//

import SwiftUI

enum MarketHongKongRankingBoard: String, CaseIterable, Identifiable {
    case all = "全部"
    case mainBoard = "主板"
    case gem = "创业板"

    var id: String {
        switch self {
        case .all: "all"
        case .mainBoard: "mainBoard"
        case .gem: "gem"
        }
    }

    var minimumTabWidth: CGFloat {
        switch self {
        case .all: 58
        case .mainBoard: 52
        case .gem: 66
        }
    }

    func title(in language: DemoLanguage) -> String {
        switch self {
        case .all: language.text(.all)
        case .mainBoard: language.text(.marketMainBoard)
        case .gem: language.text(.marketGemBoard)
        }
    }
}

struct MarketHongKongRankingItem: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let price: String
    let percentChange: Double
    let board: MarketHongKongRankingBoard

    // Local display fixtures; prices and changes are mock values.
    static let mockData: [Self] = [
        Self(id: "03690", name: "美团-W", symbol: "03690", price: "93.85", percentChange: 3.42, board: .mainBoard),
        Self(id: "01211", name: "比亚迪股份", symbol: "01211", price: "268.40", percentChange: 3.12, board: .mainBoard),
        Self(id: "02899", name: "紫金矿业", symbol: "02899", price: "19.36", percentChange: 2.46, board: .mainBoard),
        Self(id: "09988", name: "阿里巴巴-W", symbol: "09988", price: "118.60", percentChange: 2.36, board: .mainBoard),
        Self(id: "00268", name: "金蝶国际", symbol: "00268", price: "12.86", percentChange: 2.04, board: .mainBoard),
        Self(id: "08158", name: "中国再生医学", symbol: "08158", price: "0.28", percentChange: 1.82, board: .gem),
        Self(id: "00700", name: "腾讯控股", symbol: "00700", price: "382.40", percentChange: 1.38, board: .mainBoard),
        Self(id: "00069", name: "香格里拉(亚洲)", symbol: "00069", price: "5.62", percentChange: 1.15, board: .mainBoard),
        Self(id: "01299", name: "友邦保险", symbol: "01299", price: "61.35", percentChange: 0.83, board: .mainBoard),
        Self(id: "01088", name: "中国神华", symbol: "01088", price: "30.75", percentChange: 0.31, board: .mainBoard),
        Self(id: "00941", name: "中国移动", symbol: "00941", price: "75.20", percentChange: 1.62, board: .mainBoard),
        // GEM names/codes: HKEX daily quotations, 2026-09-11. Quotes below are mock values.
        Self(id: "08299", name: "GT GOLD", symbol: "08299", price: "0.30", percentChange: 4.76, board: .gem),
        Self(id: "08279", name: "AGTECH HOLDINGS", symbol: "08279", price: "1.34", percentChange: 3.18, board: .gem),
        Self(id: "08162", name: "LOCO HK", symbol: "08162", price: "0.61", percentChange: 2.85, board: .gem),
        Self(id: "08297", name: "OCEAN STAR TECH", symbol: "08297", price: "0.06", percentChange: 2.35, board: .gem),
        Self(id: "08646", name: "CHINA HONGGUANG", symbol: "08646", price: "0.24", percentChange: 2.17, board: .gem),
        Self(id: "08547", name: "PACIFIC LEGEND", symbol: "08547", price: "0.07", percentChange: 1.95, board: .gem),
        Self(id: "08275", name: "CHINA NEW CONS", symbol: "08275", price: "0.11", percentChange: 1.63, board: .gem),
        Self(id: "08431", name: "HAO BAI INTL", symbol: "08431", price: "1.38", percentChange: 1.24, board: .gem),
        Self(id: "08137", name: "HONBRIDGE", symbol: "08137", price: "0.57", percentChange: 0.72, board: .gem)
    ]

    static let figmaReference: [Self] = (0..<10).map { index in
        Self(id: "figma-\(index)", name: "Cre8 Enterprise", symbol: "CRE", price: "6.81", percentChange: 164.98, board: .mainBoard)
    }
}

/// The section shares the host's vertical scroll view so its title and board
/// filters pin together, while quote rows continue scrolling underneath.
struct MarketHongKongRankingsView: View {
    let items: [MarketHongKongRankingItem]
    let headerTopInset: CGFloat
    let minimumRowsHeight: CGFloat
    let onShowAll: () -> Void
    let onSelect: (MarketHongKongRankingItem) -> Void
    @Environment(\.demoLanguage) private var language

    @State private var selectedBoard: MarketHongKongRankingBoard = .all

    init(
        items: [MarketHongKongRankingItem] = MarketHongKongRankingItem.mockData,
        headerTopInset: CGFloat = 0,
        minimumRowsHeight: CGFloat = 0,
        onShowAll: @escaping () -> Void = { /* TODO: connect the full Hong Kong rankings destination. */ },
        onSelect: @escaping (MarketHongKongRankingItem) -> Void = { _ in
            /* TODO: connect the selected stock's destination. */
        }
    ) {
        self.items = items
        self.headerTopInset = headerTopInset
        self.minimumRowsHeight = minimumRowsHeight
        self.onShowAll = onShowAll
        self.onSelect = onSelect
    }

    var body: some View {
        Section {
            ForEach(filteredItems) { item in
                Button {
                    onSelect(item)
                } label: {
                    MarketHongKongRankingRow(
                        item: item,
                        name: language.marketSecurityName(code: item.symbol, fallback: item.name)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: language.text(.marketRankingAccessibilityFormat), language.marketSecurityName(code: item.symbol, fallback: item.name), item.symbol, item.price, item.formattedChange))
                .accessibilityIdentifier("market.hkRankings.stock.\(item.id)")
            }

            // Keep the header pinned when a filter has fewer than a screen of
            // results, without inserting another vertical scrolling surface.
            Color("color-base-1")
                .frame(height: max(24, minimumRowsHeight - CGFloat(filteredItems.count) * 66))
                .accessibilityHidden(true)
        } header: {
            header
        }
    }

    private var filteredItems: [MarketHongKongRankingItem] {
        Array(
            items.filter { selectedBoard == .all || $0.board == selectedBoard }
                .sorted { $0.percentChange > $1.percentChange }
                .prefix(10)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onShowAll) {
                HStack(spacing: 8) {
                    Text(language.text(.marketRankingsTitle))
                        .modifier(CustomFontModifier(size: 18, font: .bold, lineHeight: 28))
                        .foregroundStyle(Color("color-text-30"))

                    Spacer(minLength: 0)

                    Image("market_rankings_chevron")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                }
                .frame(height: 28)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(language.actionAccessibilityLabel(name: language.text(.marketRankingsTitle), action: language.text(.viewAll)))
            .accessibilityIdentifier("market.hkRankings.showAll")

            HStack(spacing: 8) {
                ForEach(MarketHongKongRankingBoard.allCases) { board in
                    boardTab(board)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.top, headerTopInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .zIndex(2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.hkRankings.header")
    }

    private func boardTab(_ board: MarketHongKongRankingBoard) -> some View {
        let isSelected = selectedBoard == board

        return Button {
            selectedBoard = board
        } label: {
            Text(board.title(in: language))
                .modifier(CustomFontModifier(size: 14, font: isSelected ? .bold : .regular, lineHeight: 20))
                .foregroundStyle(Color(isSelected ? "color-text-30" : "color-text-60"))
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .frame(minWidth: board.minimumTabWidth)
                .frame(height: 32)
                .background(
                    Color(isSelected ? "color-base-1" : "color-scale-1"),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? Color("color-base-r") : .clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("market.hkRankings.board.\(board.id)")
    }
}

private struct MarketHongKongRankingRow: View {
    let item: MarketHongKongRankingItem
    let name: String

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(geometry.size.width - 16, 0)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                        .foregroundStyle(Color("color-text-30"))
                        .frame(height: 24)

                    Text(item.symbol)
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundStyle(Color("color-text-60"))
                        .frame(height: 16)
                }
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.trailing, 4)
                .frame(width: contentWidth * 0.4, height: 66)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Image("market_rankings_hk")
                        .resizable()
                        .frame(width: 12, height: 10)
                        .padding(.top, 19)
                        .accessibilityHidden(true)
                }

                HStack(spacing: 8) {
                    Text(item.price)
                        .foregroundStyle(Color("color-text-30"))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(item.formattedChange)
                        .foregroundStyle(item.changeColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: contentWidth * 0.6, height: 66)
            }
        }
        .frame(height: 66)
        .background(Color("color-base-1"))
        .contentShape(Rectangle())
    }
}

private extension MarketHongKongRankingItem {
    var formattedChange: String {
        percentChange.formatted(
            .number.locale(Locale(identifier: "en_US"))
                .precision(.fractionLength(2))
                .sign(strategy: .always(includingZero: false))
        ) + "%"
    }

    var changeColor: Color {
        if percentChange > 0 { return Color("color-utility3-red") }
        if percentChange < 0 { return Color("color-utility3-green") }
        return Color("color-text-60")
    }
}

#Preview("港股榜单 · 设计稿") {
    ScrollView {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            MarketHongKongRankingsView(items: MarketHongKongRankingItem.figmaReference)
        }
    }
    .frame(width: 402)
    .background(Color("color-base-1"))
}

#Preview("港股榜单 · 深色") {
    ScrollView {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            MarketHongKongRankingsView()
        }
    }
    .frame(width: 402)
    .background(Color("color-base-1"))
    .preferredColorScheme(.dark)
}
