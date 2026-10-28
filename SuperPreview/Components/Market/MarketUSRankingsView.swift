//
//  MarketUSRankingsView.swift
//  SuperPreview
//
//  组件名称：美股榜单
//  简介：展示热门股票、中概股、科技股和 ETF 的模拟报价。
//  用于：市场页美股分类；放入支持 sectionHeaders 吸顶的 LazyVStack。
//

import SwiftUI

enum MarketUSRankingTab: String, CaseIterable, Identifiable {
    case popular
    case china
    case technology
    case etfs

    var id: String { rawValue }

    var title: DemoCopyKey {
        switch self {
        case .popular: .marketUSPopularStocks
        case .china: .marketUSChinaStocks
        case .technology: .marketUSTechStocks
        case .etfs: .marketUSETFs
        }
    }
}

struct MarketUSRankingItem: Identifiable {
    let symbol: String
    let simplifiedName: String
    let traditionalName: String
    let englishName: String
    let price: String
    let percentChange: Double

    var id: String { symbol }

    func name(in language: DemoLanguage) -> String {
        switch language {
        case .simplifiedChinese: simplifiedName
        case .traditionalChinese: traditionalName
        case .english: englishName
        }
    }

    private static func item(
        _ symbol: String,
        _ simplified: String,
        _ traditional: String,
        _ english: String,
        _ price: String,
        _ change: Double
    ) -> Self {
        Self(symbol: symbol, simplifiedName: simplified, traditionalName: traditional,
             englishName: english, price: price, percentChange: change)
    }

    // Local display fixtures. Prices and changes are mock values, not live quotes.
    static let mockData: [MarketUSRankingTab: [Self]] = [
        .popular: [
            item("NVDA", "英伟达", "英偉達", "NVIDIA", "145.24", 3.42),
            item("AVGO", "博通", "博通", "Broadcom", "176.25", 3.10),
            item("AMZN", "亚马逊", "亞馬遜", "Amazon", "192.56", 2.17),
            item("META", "Meta Platforms", "Meta Platforms", "Meta Platforms", "570.82", 2.02),
            item("AAPL", "苹果", "蘋果", "Apple", "227.48", 1.82),
            item("AMD", "超威半导体", "超微半導體", "AMD", "152.70", 1.53),
            item("MSFT", "微软", "微軟", "Microsoft", "418.23", 1.30),
            item("NFLX", "奈飞", "奈飛", "Netflix", "720.40", 1.08),
            item("GOOGL", "Alphabet", "Alphabet", "Alphabet", "175.30", 0.93),
            item("TSLA", "特斯拉", "特斯拉", "Tesla", "258.10", -1.25)
        ],
        .china: [
            item("BABA", "阿里巴巴", "阿里巴巴", "Alibaba Group", "105.28", 3.64),
            item("PDD", "拼多多", "拼多多", "PDD Holdings", "121.40", 3.18),
            item("JD", "京东", "京東", "JD.com", "37.26", 2.75),
            item("BIDU", "百度", "百度", "Baidu", "89.52", 2.12),
            item("LI", "理想汽车", "理想汽車", "Li Auto", "25.18", 1.85),
            item("XPEV", "小鹏汽车", "小鵬汽車", "XPeng", "14.32", 1.58),
            item("TCOM", "携程", "攜程", "Trip.com", "63.45", 1.26),
            item("BILI", "哔哩哔哩", "嗶哩嗶哩", "Bilibili", "22.84", 0.94),
            item("ZTO", "中通快递", "中通快遞", "ZTO Express", "21.37", 0.62),
            item("NIO", "蔚来", "蔚來", "NIO", "4.65", -0.86)
        ],
        .technology: [
            item("NVDA", "英伟达", "英偉達", "NVIDIA", "145.24", 3.42),
            item("AVGO", "博通", "博通", "Broadcom", "176.25", 3.10),
            item("META", "Meta Platforms", "Meta Platforms", "Meta Platforms", "570.82", 2.02),
            item("AAPL", "苹果", "蘋果", "Apple", "227.48", 1.82),
            item("AMD", "超威半导体", "超微半導體", "AMD", "152.70", 1.53),
            item("MSFT", "微软", "微軟", "Microsoft", "418.23", 1.30),
            item("ORCL", "甲骨文", "甲骨文", "Oracle", "165.80", 1.16),
            item("CRM", "赛富时", "賽富時", "Salesforce", "288.36", 1.04),
            item("GOOGL", "Alphabet", "Alphabet", "Alphabet", "175.30", 0.93),
            item("INTC", "英特尔", "英特爾", "Intel", "23.86", -0.74)
        ],
        .etfs: [
            item("ARKK", "方舟创新 ETF", "方舟創新 ETF", "ARK Innovation ETF", "48.21", 2.32),
            item("XLK", "科技精选板块 ETF", "科技精選板塊 ETF", "Technology Select Sector SPDR", "225.37", 1.88),
            item("QQQ", "景顺纳指100 ETF", "景順納指100 ETF", "Invesco QQQ", "485.64", 1.65),
            item("IWM", "安硕罗素2000 ETF", "安碩羅素2000 ETF", "iShares Russell 2000 ETF", "220.52", 1.34),
            item("SPY", "SPDR 标普500 ETF", "SPDR 標普500 ETF", "SPDR S&P 500 ETF", "562.18", 1.12),
            item("VOO", "先锋标普500 ETF", "先鋒標普500 ETF", "Vanguard S&P 500 ETF", "515.30", 1.10),
            item("VTI", "先锋全美股票 ETF", "先鋒全美股票 ETF", "Vanguard Total Stock Market ETF", "279.46", 1.02),
            item("DIA", "SPDR 道琼斯工业 ETF", "SPDR 道瓊斯工業 ETF", "SPDR Dow Jones Industrial Average ETF", "418.22", 0.74),
            item("XLF", "金融精选板块 ETF", "金融精選板塊 ETF", "Financial Select Sector SPDR", "47.63", 0.58),
            item("TLT", "安硕20年期以上美债 ETF", "安碩20年期以上美債 ETF", "iShares 20+ Year Treasury Bond ETF", "91.48", -0.42)
        ]
    ]
}

/// The host's vertical scroll view owns the section so its tab row can pin.
struct MarketUSRankingsView: View {
    let itemsByTab: [MarketUSRankingTab: [MarketUSRankingItem]]
    let headerTopInset: CGFloat
    let minimumRowsHeight: CGFloat
    let onShowAll: () -> Void
    let onSelect: (MarketUSRankingItem) -> Void

    @Environment(\.demoLanguage) private var language
    @State private var selectedTab: MarketUSRankingTab = .popular

    init(
        itemsByTab: [MarketUSRankingTab: [MarketUSRankingItem]] = MarketUSRankingItem.mockData,
        headerTopInset: CGFloat = 0,
        minimumRowsHeight: CGFloat = 0,
        onShowAll: @escaping () -> Void = { /* TODO: connect the full US rankings destination. */ },
        onSelect: @escaping (MarketUSRankingItem) -> Void = { _ in
            /* TODO: connect the selected stock's destination. */
        }
    ) {
        self.itemsByTab = itemsByTab
        self.headerTopInset = headerTopInset
        self.minimumRowsHeight = minimumRowsHeight
        self.onShowAll = onShowAll
        self.onSelect = onSelect
    }

    var body: some View {
        Section {
            ForEach(visibleItems) { item in
                Button {
                    onSelect(item)
                } label: {
                    MarketUSRankingRow(item: item, name: item.name(in: language))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: language.text(.marketRankingAccessibilityFormat), item.name(in: language), item.symbol, item.price, item.formattedChange))
                .accessibilityIdentifier("market.usRankings.stock.\(item.id)")
            }

            // Preserve enough scrollable height to keep the header pinned.
            Color("color-base-1")
                .frame(height: max(24, minimumRowsHeight - CGFloat(visibleItems.count) * 66))
                .accessibilityHidden(true)
        } header: {
            header
        }
    }

    private var visibleItems: [MarketUSRankingItem] {
        Array((itemsByTab[selectedTab] ?? [])
            .sorted { $0.percentChange > $1.percentChange }
            .prefix(10))
    }

    private var header: some View {
        HStack(spacing: 16) {
            // Keep the design's full row when it fits. Longer translations
            // can scroll without clipping their labels.
            ViewThatFits(in: .horizontal) {
                tabButtons.fixedSize(horizontal: true, vertical: false)
                ScrollView(.horizontal, showsIndicators: false) {
                    tabButtons
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onShowAll) {
                Image("chevron_right_text30_sm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(language.actionAccessibilityLabel(name: language.text(selectedTab.title), action: language.text(.viewAll)))
            .accessibilityIdentifier("market.usRankings.showAll")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.top, headerTopInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .zIndex(2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.usRankings.header")
    }

    private var tabButtons: some View {
        HStack(spacing: 16) {
            ForEach(MarketUSRankingTab.allCases) { tab in
                tabButton(tab)
            }
        }
    }

    private func tabButton(_ tab: MarketUSRankingTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            guard selectedTab != tab else { return }
            selectedTab = tab
        } label: {
            Text(language.text(tab.title))
                .modifier(CustomFontModifier(size: isSelected ? 18 : 14, font: isSelected ? .medium : .regular, lineHeight: 28))
                .foregroundStyle(Color(isSelected ? "color-text-30" : "color-text-60"))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(height: 28)
                .padding(.horizontal, isSelected ? 2 : 0)
                .background(alignment: .bottom) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [Color("color-scale-3"), Color("color-base-1")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 8)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("market.usRankings.tab.\(tab.id)")
    }
}

private struct MarketUSRankingRow: View {
    let item: MarketUSRankingItem
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
                    Image("market_rankings_us")
                        .resizable()
                        .frame(width: 12, height: 10)
                        .padding(.top, 19)
                        .accessibilityHidden(true)
                }

                HStack(spacing: 8) {
                    Text(item.price)
                        .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                        .foregroundStyle(Color("color-text-30"))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(item.formattedChange)
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundStyle(item.changeColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
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

private extension MarketUSRankingItem {
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

#Preview("美股榜单") {
    ScrollView {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            MarketUSRankingsView()
        }
    }
    .frame(width: 402)
    .background(Color("color-base-1"))
}
