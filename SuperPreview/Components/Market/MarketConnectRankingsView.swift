import SwiftUI

private enum ConnectRankingTab: String, CaseIterable, Identifiable {
    case connect, turnover, ah
    var id: String { rawValue }
    var title: DemoCopyKey {
        switch self {
        case .connect: .connectRankingsTab
        case .turnover: .connectTopTurnover
        case .ah: .connectAHShares
        }
    }
}

private enum ConnectExchange: String, CaseIterable, Identifiable {
    case shanghai, shenzhen
    var id: String { rawValue }
    func title(direction: MarketConnectDirection) -> DemoCopyKey {
        switch (direction, self) {
        case (.north, .shanghai): .connectShanghaiFilter
        case (.north, .shenzhen): .connectShenzhenFilter
        case (.south, .shanghai): .connectShanghaiSouth
        case (.south, .shenzhen): .connectShenzhenSouth
        }
    }
}

private struct ConnectStock: Identifiable {
    let symbol: String
    let simplified: String
    let traditional: String
    let english: String
    let price: String
    let change: Double
    let isAH: Bool
    var id: String { symbol }

    func name(_ language: DemoLanguage) -> String {
        switch language {
        case .simplifiedChinese: simplified
        case .traditionalChinese: traditional
        case .english: english
        }
    }

    var formattedChange: String {
        String(format: "%+.2f%%", locale: Locale(identifier: "en_US_POSIX"), change)
    }

    // Company names and symbols are examples. All prices and changes are mock values.
    static let shanghai: [Self] = [
        .init(symbol: "600519", simplified: "贵州茅台", traditional: "貴州茅台", english: "Kweichow Moutai", price: "1,480.00", change: 2.45, isAH: false),
        .init(symbol: "601318", simplified: "中国平安", traditional: "中國平安", english: "Ping An Insurance", price: "48.60", change: 1.88, isAH: true),
        .init(symbol: "600036", simplified: "招商银行", traditional: "招商銀行", english: "China Merchants Bank", price: "38.52", change: 1.62, isAH: true),
        .init(symbol: "601398", simplified: "工商银行", traditional: "工商銀行", english: "ICBC", price: "6.45", change: 1.35, isAH: true),
        .init(symbol: "601899", simplified: "紫金矿业", traditional: "紫金礦業", english: "Zijin Mining", price: "17.86", change: 1.24, isAH: true),
        .init(symbol: "601088", simplified: "中国神华", traditional: "中國神華", english: "China Shenhua", price: "41.25", change: 0.98, isAH: true),
        .init(symbol: "601988", simplified: "中国银行", traditional: "中國銀行", english: "Bank of China", price: "4.78", change: 0.72, isAH: true),
        .init(symbol: "601857", simplified: "中国石油", traditional: "中國石油", english: "PetroChina", price: "9.12", change: 0.56, isAH: true),
        .init(symbol: "601288", simplified: "农业银行", traditional: "農業銀行", english: "Agricultural Bank of China", price: "4.75", change: 0.31, isAH: true),
        .init(symbol: "601766", simplified: "中国中车", traditional: "中國中車", english: "CRRC", price: "7.26", change: -0.43, isAH: true)
    ]
    static let shenzhen: [Self] = [
        .init(symbol: "002594", simplified: "比亚迪", traditional: "比亞迪", english: "BYD", price: "268.40", change: 3.12, isAH: true),
        .init(symbol: "000063", simplified: "中兴通讯", traditional: "中興通訊", english: "ZTE", price: "32.68", change: 2.16, isAH: true),
        .init(symbol: "000338", simplified: "潍柴动力", traditional: "濰柴動力", english: "Weichai Power", price: "15.36", change: 1.78, isAH: true),
        .init(symbol: "000157", simplified: "中联重科", traditional: "中聯重科", english: "Zoomlion", price: "7.25", change: 1.42, isAH: true),
        .init(symbol: "000039", simplified: "中集集团", traditional: "中集集團", english: "CIMC", price: "8.18", change: 1.20, isAH: true),
        .init(symbol: "000002", simplified: "万科A", traditional: "萬科A", english: "China Vanke A", price: "8.45", change: 0.92, isAH: true),
        .init(symbol: "300750", simplified: "宁德时代", traditional: "寧德時代", english: "CATL", price: "212.68", change: 0.75, isAH: false),
        .init(symbol: "000858", simplified: "五粮液", traditional: "五糧液", english: "Wuliangye", price: "142.30", change: 0.58, isAH: false),
        .init(symbol: "000333", simplified: "美的集团", traditional: "美的集團", english: "Midea Group", price: "70.25", change: 0.35, isAH: true),
        .init(symbol: "002415", simplified: "海康威视", traditional: "海康威視", english: "Hikvision", price: "29.42", change: -0.60, isAH: false)
    ]
    static let hongKong: [Self] = [
        .init(symbol: "00700", simplified: "腾讯控股", traditional: "騰訊控股", english: "Tencent", price: "382.40", change: 2.18, isAH: false),
        .init(symbol: "09988", simplified: "阿里巴巴-W", traditional: "阿里巴巴-W", english: "Alibaba", price: "118.60", change: 1.96, isAH: false),
        .init(symbol: "03690", simplified: "美团-W", traditional: "美團-W", english: "Meituan", price: "93.85", change: 1.65, isAH: false),
        .init(symbol: "01211", simplified: "比亚迪股份", traditional: "比亞迪股份", english: "BYD", price: "268.40", change: 1.52, isAH: true),
        .init(symbol: "02899", simplified: "紫金矿业", traditional: "紫金礦業", english: "Zijin Mining", price: "19.36", change: 1.30, isAH: true),
        .init(symbol: "02318", simplified: "中国平安", traditional: "中國平安", english: "Ping An Insurance", price: "46.20", change: 1.08, isAH: true),
        .init(symbol: "03968", simplified: "招商银行", traditional: "招商銀行", english: "China Merchants Bank", price: "37.10", change: 0.87, isAH: true),
        .init(symbol: "01398", simplified: "工商银行", traditional: "工商銀行", english: "ICBC", price: "5.24", change: 0.61, isAH: true),
        .init(symbol: "01088", simplified: "中国神华", traditional: "中國神華", english: "China Shenhua", price: "30.75", change: 0.36, isAH: true),
        .init(symbol: "00941", simplified: "中国移动", traditional: "中國移動", english: "China Mobile", price: "75.20", change: -0.42, isAH: true)
    ]
    static let shanghaiAHExtra: [Self] = [
        .init(symbol: "601939", simplified: "建设银行", traditional: "建設銀行", english: "China Construction Bank", price: "7.22", change: 0.45, isAH: true)
    ]
    static let shenzhenAHExtra: [Self] = [
        .init(symbol: "000776", simplified: "广发证券", traditional: "廣發證券", english: "GF Securities", price: "15.30", change: 0.56, isAH: true),
        .init(symbol: "002202", simplified: "金风科技", traditional: "金風科技", english: "Goldwind", price: "8.62", change: 0.42, isAH: true),
        .init(symbol: "002490", simplified: "山东墨龙", traditional: "山東墨龍", english: "Shandong Molong", price: "3.35", change: -0.28, isAH: true)
    ]
    static let hongKongAHExtra: [Self] = [
        .init(symbol: "00939", simplified: "建设银行", traditional: "建設銀行", english: "China Construction Bank", price: "6.42", change: 0.55, isAH: true),
        .init(symbol: "03988", simplified: "中国银行", traditional: "中國銀行", english: "Bank of China", price: "4.02", change: 0.32, isAH: true),
        .init(symbol: "00857", simplified: "中国石油股份", traditional: "中國石油股份", english: "PetroChina", price: "6.86", change: -0.24, isAH: true)
    ]
}

/// The host provides the vertical scroll view and pins this section's header.
struct MarketConnectRankingsView: View {
    @Binding var direction: MarketConnectDirection
    let minimumRowsHeight: CGFloat
    var onShowAll: () -> Void = { /* Connect the destination when available. */ }
    var onSelect: (String) -> Void = { _ in /* Connect the stock destination when available. */ }
    @Environment(\.demoLanguage) private var language
    @State private var tab: ConnectRankingTab = .connect
    @State private var exchange: ConnectExchange = .shanghai

    init(direction: Binding<MarketConnectDirection>, minimumRowsHeight: CGFloat = 0, onShowAll: @escaping () -> Void = {}, onSelect: @escaping (String) -> Void = { _ in }) {
        self._direction = direction
        self.minimumRowsHeight = minimumRowsHeight
        self.onShowAll = onShowAll
        self.onSelect = onSelect
    }

    var body: some View {
        Section {
            ForEach(visibleStocks) { stock in
                Button { onSelect(stock.symbol) } label: { row(stock) }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(format: language.text(.marketRankingAccessibilityFormat), stock.name(language), stock.symbol, stock.price, stock.formattedChange))
                    .accessibilityIdentifier("market.connectRankings.stock.\(stock.symbol)")
            }
            Color("color-base-1")
                .frame(height: max(24, minimumRowsHeight - CGFloat(visibleStocks.count) * 66))
                .accessibilityHidden(true)
        } header: {
            header
        }
    }

    private var visibleStocks: [ConnectStock] {
        let stocks = direction == .south ? ConnectStock.hongKong : (exchange == .shanghai ? ConnectStock.shanghai : ConnectStock.shenzhen)
        let extras = direction == .south ? ConnectStock.hongKongAHExtra : (exchange == .shanghai ? ConnectStock.shanghaiAHExtra : ConnectStock.shenzhenAHExtra)
        let filtered = tab == .ah ? Array((stocks.filter(\.isAH) + extras).prefix(10)) : stocks
        return tab == .turnover || (direction == .south && exchange == .shenzhen) ? Array(filtered.reversed()) : filtered
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ViewThatFits(in: .horizontal) {
                    tabButtons.fixedSize(horizontal: true, vertical: false)
                    ScrollView(.horizontal, showsIndicators: false) { tabButtons }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onShowAll) {
                    Image("chevron_right_text30_sm").resizable().scaledToFit().frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.actionAccessibilityLabel(name: language.text(tab.title), action: language.text(.viewAll)))
            }
            .padding(.horizontal, 16)
            .frame(height: 28)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ConnectExchange.allCases) { option in
                        filterButton(option)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 48)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .accessibilityIdentifier("market.connectRankings.header")
    }

    private var tabButtons: some View {
        HStack(spacing: 16) {
            ForEach(ConnectRankingTab.allCases) { item in
                Button {
                    guard tab != item else { return }
                    tab = item
                } label: {
                    Text(language.text(item.title))
                        .modifier(CustomFontModifier(size: tab == item ? 18 : 14, font: tab == item ? .medium : .regular, lineHeight: 28))
                        .foregroundStyle(Color(tab == item ? "color-text-30" : "color-text-60"))
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(height: 28)
                        .padding(.horizontal, tab == item ? 2 : 0)
                        .background(alignment: .bottom) {
                            if tab == item {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [Color("color-scale-3"), Color("color-base-1")], startPoint: .leading, endPoint: .trailing))
                                    .frame(height: 8)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == item ? .isSelected : [])
                .accessibilityIdentifier("market.connectRankings.tab.\(item.id)")
            }
        }
    }

    private func filterButton(_ option: ConnectExchange) -> some View {
        let active = exchange == option
        return Button {
            guard exchange != option else { return }
            exchange = option
        } label: {
            Text(language.text(option.title(direction: direction)))
                .modifier(CustomFontModifier(size: 14, font: active ? .bold : .regular, lineHeight: 20))
                .foregroundStyle(Color(active ? "color-text-30" : "color-text-60"))
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color(active ? "color-base-1" : "color-scale-1"), in: RoundedRectangle(cornerRadius: 6))
                .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(active ? Color("color-base-r") : .clear, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
        .accessibilityIdentifier("market.connectRankings.exchange.\(option.id)")
    }

    private func row(_ stock: ConnectStock) -> some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width - 16, 0)
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.name(language))
                        .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                        .foregroundStyle(Color("color-text-30")).frame(height: 24)
                    Text(stock.symbol)
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundStyle(Color("color-text-60")).frame(height: 16)
                }
                .lineLimit(1).truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16).padding(.trailing, 4)
                .frame(width: width * 0.4, height: 66)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Image(direction == .south ? "market_rankings_hk" : (exchange == .shanghai ? "market_rankings_sh" : "market_rankings_sz"))
                        .resizable().frame(width: 12, height: 10).padding(.top, 19).accessibilityHidden(true)
                }
                HStack(spacing: 8) {
                    Text(stock.price).modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                        .foregroundStyle(Color("color-text-30")).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(stock.formattedChange).modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                        .foregroundStyle(Color(stock.change >= 0 ? "color-utility3-red" : "color-utility3-green"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(width: width * 0.6, height: 66)
            }
        }
        .frame(height: 66)
        .background(Color("color-base-1"))
        .contentShape(Rectangle())
    }
}
