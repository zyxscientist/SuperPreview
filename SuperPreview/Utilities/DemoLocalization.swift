//
//  DemoLocalization.swift
//  SuperPreview
//

import SwiftUI

enum DemoLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case english = "en"

    static let storageKey = "compare.demo.interfaceLanguage"

    var id: String { rawValue }

    /// Language names stay self-described so the picker is always recoverable.
    var nativeName: String {
        switch self {
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .english:
            return "English"
        }
    }
}

private struct DemoLanguageKey: EnvironmentKey {
    static let defaultValue = DemoLanguage.simplifiedChinese
}

extension EnvironmentValues {
    var demoLanguage: DemoLanguage {
        get { self[DemoLanguageKey.self] }
        set { self[DemoLanguageKey.self] = newValue }
    }
}

enum DemoCopyKey {
    case newWatchlist, newTrade, debug, done, interfaceLanguage
    case navigateOnTap, navigateOnTapOn, navigateOnTapOff, tabBarFontSize
    case simulateQuoteUpdates, quoteUpdatesOn, quoteUpdatesOff, updateSpeed
    case slow, medium, fast, mixed
    case all, hkStocks, chinaAShares, usStocks, etfs, custom
    case name, price, changePercent, preMarket, afterHours
    case addToWatchlist, editWatchlist
    case watchlist, trade, wealth, news, markets, me
    case stocks, funds, virtualAssets, positionDetails
    case totalAssets, totalProfitLoss, netAssets, todayProfitLoss, yesterdayProfitLoss
    case securitiesMarketValue, totalCash, positionProfitLoss
    case fundsInTransit, ipoFundsInTransit, fundsOnHold
    case cashAvailable, cashWithdrawable, maximumBuyingPower
    case fundMarketValue, positionIncome, virtualAssetMarketValue
    case todayOrders, ipoCenter, deposit, more
    case transactionHistory, recurringInvestment, statements
    case internalTransfer, cashHistory
    case quote, order, details, subscribe, redeem, recurringInvestmentTag
    case expanded, collapsed, expandPositions, collapsePositions
    case expandFundPositions, collapseFundPositions
    case valuesHidden, positionDataShown, expandQuickActions, collapseQuickActions
    case showAssetValues, hideAssetValues, expandAssetDetails, collapseAssetDetails
    case legacyFundInformation, supportsTPlusZero, closePricingInformation
    case hkStockGroup, chinaStockGroup, usStockGroup
    case hkdFundGroup, usdFundGroup, cnyFundGroup
    case cryptoGroup, rwaGroup, cryptoPricingInfo
    case marketValueQuantityHeader, lastCostHeader, dayProfitLossHeader
    case positionProfitLossHeader, portfolioWeightHeader
    case marketValueYesterdayHeader, positionIncomeHeader
    case mrNotice, mrNoticeAccessibility, systemUpgrade, maintenanceDetails
    case summerCampaignAccessibility
    case limitedTime, summerCampaignHeadline, summerCampaignPeriod
    case simulateLiveData, liveDataOn, liveDataOff, mrTestMode, mrTestDetails
    case showSummerCampaign, summerCampaignDetails
    case enableDebugStateMatrix, restoreNormalAndLiveData
}

extension DemoLanguage {
    func text(_ key: DemoCopyKey) -> String {
        let values = DemoCopy.values[key] ?? ("", "", "")
        switch self {
        case .simplifiedChinese:
            return values.0
        case .traditionalChinese:
            return values.1
        case .english:
            return values.2
        }
    }

    func securityName(id: String, fallback: String) -> String {
        guard let values = DemoCopy.securityNames[id] else { return fallback }
        switch self {
        case .simplifiedChinese:
            return values.0
        case .traditionalChinese:
            return values.1
        case .english:
            return values.2
        }
    }

    func accessibilityText(_ key: DemoCopyKey) -> String {
        guard self == .english else { return text(key) }
        return DemoCopy.englishAccessibility[key] ?? text(key)
    }

    func actionAccessibilityLabel(name: String, action: String) -> String {
        switch self {
        case .simplifiedChinese, .traditionalChinese:
            return "\(name)，\(action)"
        case .english:
            return "\(name), \(action)"
        }
    }

    func watchlistTabTitle(_ internalTitle: String) -> String {
        let key: DemoCopyKey
        switch internalTitle {
        case "全部": key = .all
        case "港股": key = .hkStocks
        case "沪深": key = .chinaAShares
        case "美股": key = .usStocks
        case "ETFs": key = .etfs
        default: key = .custom
        }
        return text(key)
    }

    func watchlistName(symbol: String, fallback: String) -> String {
        let localizationID = DemoCopy.watchlistNameIDs[symbol]
        return localizationID.map { securityName(id: $0, fallback: fallback) } ?? fallback
    }

    func speedTitle(_ speed: WatchlistRedesignPriceSimulationSpeed) -> String {
        switch speed {
        case .slow: return text(.slow)
        case .medium: return text(.medium)
        case .fast: return text(.fast)
        case .mixed: return text(.mixed)
        }
    }

    func sessionTitle(_ internalLabel: String) -> String {
        internalLabel == "盘前" ? text(.preMarket) : text(.afterHours)
    }
}

private enum DemoCopy {
    typealias Values = (String, String, String)

    static let values: [DemoCopyKey: Values] = [
        .newWatchlist: ("新自选", "新自選", "New Watchlist"),
        .newTrade: ("新交易", "新交易", "New Trade"),
        .debug: ("调试", "除錯", "Debug"),
        .done: ("完成", "完成", "Done"),
        .interfaceLanguage: ("界面语言", "介面語言", "Interface Language"),
        .navigateOnTap: ("点按后跳转", "點按後跳轉", "Navigate on Tap"),
        .navigateOnTapOn: ("开启后，松开点按会进入空白详情页", "開啟後，放開點按會進入空白詳情頁", "When enabled, releasing a tap opens the blank detail screen."),
        .navigateOnTapOff: ("关闭后，仅展示列表的点按背景效果", "關閉後，僅顯示列表的點按背景效果", "When disabled, taps only show the row press effect."),
        .tabBarFontSize: ("Tab Bar 字号", "Tab Bar 字號", "Tab Bar Font Size"),
        .simulateQuoteUpdates: ("模拟行情刷新", "模擬行情更新", "Simulate Quote Updates"),
        .quoteUpdatesOn: ("股票价格和涨跌幅会持续变化", "股票價格及漲跌幅會持續變化", "Stock prices and percentage changes update continuously."),
        .quoteUpdatesOff: ("基金不会参与模拟刷新", "基金不會參與模擬更新", "Funds are excluded from simulated updates."),
        .updateSpeed: ("刷新速度", "更新速度", "Update Speed"),
        .slow: ("慢", "慢", "Slow"),
        .medium: ("中", "中", "Medium"),
        .fast: ("快", "快", "Fast"),
        .mixed: ("混合", "混合", "Mixed"),
        .all: ("全部", "全部", "All"),
        .hkStocks: ("港股", "港股", "Hong Kong Stocks"),
        .chinaAShares: ("沪深", "滬深", "China A-Shares"),
        .usStocks: ("美股", "美股", "U.S. Stocks"),
        .etfs: ("ETFs", "ETFs", "ETFs"),
        .custom: ("自定义", "自訂", "Custom"),
        .name: ("名称", "名稱", "Name"),
        .price: ("价格", "價格", "Price"),
        .changePercent: ("涨跌幅", "漲跌幅", "Chg%"),
        .preMarket: ("盘前", "盤前", "Pre"),
        .afterHours: ("盘后", "盤後", "Post"),
        .addToWatchlist: ("添加自选", "加入自選", "Add to Watchlist"),
        .editWatchlist: ("编辑自选", "編輯自選", "Edit Watchlist"),
        .watchlist: ("自选", "自選", "Watchlist"),
        .trade: ("交易", "交易", "Trade"),
        .wealth: ("理财", "理財", "Wealth"),
        .news: ("资讯", "資訊", "News"),
        .markets: ("市场", "市場", "Markets"),
        .me: ("我的", "我的", "Me"),
        .stocks: ("股票", "股票", "Stocks"),
        .funds: ("基金", "基金", "Funds"),
        .virtualAssets: ("虚拟资产", "虛擬資產", "Virtual Assets"),
        .positionDetails: ("持仓明细", "持倉明細", "Position Details"),
        .totalAssets: ("总资产", "總資產", "Total Assets"),
        .totalProfitLoss: ("总盈亏", "總盈虧", "Total P/L"),
        .netAssets: ("净资产", "淨資產", "Net Assets"),
        .todayProfitLoss: ("今日盈亏", "今日盈虧", "Today's P/L"),
        .yesterdayProfitLoss: ("昨日收益", "昨日收益", "Yesterday's P/L"),
        .securitiesMarketValue: ("证券市值", "證券市值", "Sec. MKV"),
        .totalCash: ("总现金", "總現金", "Total Cash"),
        .positionProfitLoss: ("持仓盈亏", "持倉盈虧", "Pos. P/L"),
        .fundsInTransit: ("在途资金", "在途資金", "In Transit"),
        .ipoFundsInTransit: ("IPO 在途资金", "IPO 在途資金", "IPO Transit"),
        .fundsOnHold: ("冻结资金", "凍結資金", "On Hold"),
        .cashAvailable: ("现金可用", "現金可用", "Available"),
        .cashWithdrawable: ("现金可取", "現金可取", "Withdrawable"),
        .maximumBuyingPower: ("最大购买力", "最大購買力", "Max. BP"),
        .fundMarketValue: ("基金市值", "基金市值", "Fund MKV"),
        .positionIncome: ("持仓收益", "持倉收益", "Pos. Income"),
        .virtualAssetMarketValue: ("虚拟资产市值", "虛擬資產市值", "Crypto MKV"),
        .todayOrders: ("今日订单", "今日訂單", "Orders"),
        .ipoCenter: ("新股中心", "新股中心", "IPO Center"),
        .deposit: ("入金", "入金", "Deposit"),
        .more: ("更多", "更多", "More"),
        .transactionHistory: ("交易记录", "交易記錄", "History"),
        .recurringInvestment: ("我的定投", "我的定投", "Auto-Invest"),
        .statements: ("结单", "結單", "Statements"),
        .internalTransfer: ("资金内转", "資金內轉", "Transfer"),
        .cashHistory: ("资金记录", "資金記錄", "Cash History"),
        .quote: ("行情", "行情", "Quote"),
        .order: ("下单", "下單", "Trade"),
        .details: ("详情", "詳情", "Details"),
        .subscribe: ("申购", "申購", "Subscribe"),
        .redeem: ("赎回", "贖回", "Redeem"),
        .recurringInvestmentTag: ("定投", "定投", "AIP"),
        .expanded: ("已展开", "已展開", "Expanded"),
        .collapsed: ("已收起", "已收起", "Collapsed"),
        .expandPositions: ("双击展开持仓", "點兩下展開持倉", "Double-tap to expand positions"),
        .collapsePositions: ("双击收起持仓", "點兩下收起持倉", "Double-tap to collapse positions"),
        .expandFundPositions: ("双击展开基金持仓", "點兩下展開基金持倉", "Double-tap to expand fund positions"),
        .collapseFundPositions: ("双击收起基金持仓", "點兩下收起基金持倉", "Double-tap to collapse fund positions"),
        .valuesHidden: ("数值已隐藏", "數值已隱藏", "Values hidden"),
        .positionDataShown: ("持仓数据已显示", "持倉資料已顯示", "Position data shown"),
        .expandQuickActions: ("双击展开快捷操作", "點兩下展開快捷操作", "Double-tap to expand quick actions"),
        .collapseQuickActions: ("双击收起快捷操作", "點兩下收起快捷操作", "Double-tap to collapse quick actions"),
        .showAssetValues: ("显示资产数字", "顯示資產數字", "Show asset values"),
        .hideAssetValues: ("隐藏资产数字", "隱藏資產數字", "Hide asset values"),
        .expandAssetDetails: ("展开资产详情", "展開資產詳情", "Expand asset details"),
        .collapseAssetDetails: ("收起资产详情", "收起資產詳情", "Collapse asset details"),
        .legacyFundInformation: ("旧基金说明", "舊基金說明", "Legacy fund information"),
        .supportsTPlusZero: ("支持 T+0", "支援 T+0", "Supports T plus zero settlement"),
        .closePricingInformation: ("关闭计价说明", "關閉計價說明", "Close pricing information"),
        .hkStockGroup: ("港股 · HKD", "港股 · HKD", "Hong Kong Stocks · HKD"),
        .chinaStockGroup: ("A股 · CNY", "A股 · CNY", "China A-Shares · CNY"),
        .usStockGroup: ("美股 · USD", "美股 · USD", "U.S. Stocks · USD"),
        .hkdFundGroup: ("港币基金", "港幣基金", "Hong Kong Dollar Funds"),
        .usdFundGroup: ("美元基金", "美元基金", "U.S. Dollar Funds"),
        .cnyFundGroup: ("人民币基金", "人民幣基金", "Renminbi Funds"),
        .cryptoGroup: ("加密货币 · USD", "加密貨幣 · USD", "Cryptocurrency · USD"),
        .rwaGroup: ("RWA · USD", "RWA · USD", "Real-World Assets (RWA) · USD"),
        .cryptoPricingInfo: ("您可以港币或美元直接买卖加密货币。成交后，加密货币持仓明细将以美元计价。", "您可以港幣或美元直接買賣加密貨幣。成交後，加密貨幣持倉明細將以美元計價。", "Trade crypto in HKD or USD. Positions are valued in USD after execution."),
        .marketValueQuantityHeader: ("市值/持有", "市值/持有", "MKV/Qty"),
        .lastCostHeader: ("现价/成本", "現價/成本", "Last/Cost"),
        .dayProfitLossHeader: ("今日盈亏", "今日盈虧", "Day P/L"),
        .positionProfitLossHeader: ("持仓盈亏", "持倉盈虧", "Pos. P/L"),
        .portfolioWeightHeader: ("持仓占比", "持倉佔比", "Weight"),
        .marketValueYesterdayHeader: ("市值/昨日收益", "市值/昨日收益", "MKV/1D P/L"),
        .positionIncomeHeader: ("持仓收益", "持倉收益", "Pos. Inc."),
        .mrNotice: ("系统维护期间无法获取总资产数据，完成后将恢复正常", "系統維護期間無法取得總資產資料，完成後將恢復正常", "Total asset data unavailable during maintenance"),
        .mrNoticeAccessibility: ("系统维护提示：系统维护期间无法获取总资产数据，完成后将恢复正常", "系統維護提示：系統維護期間無法取得總資產資料，完成後將恢復正常", "System maintenance notice: Total asset data is unavailable during maintenance and will return when complete."),
        .systemUpgrade: ("正在升级系统", "正在升級系統", "System Upgrade in Progress"),
        .maintenanceDetails: ("升级时间：YYYY/MM/DD HH:MM 至 YYYY/MM/DD HH:MM，升级期间可能影响交易与数据展示，升级完成后系统将恢复正常", "升級時間：YYYY/MM/DD HH:MM 至 YYYY/MM/DD HH:MM，升級期間可能影響交易與資料顯示，升級完成後系統將恢復正常", "Maintenance window: YYYY/MM/DD HH:MM to YYYY/MM/DD HH:MM. Trading and data display may be affected. Service will return when the upgrade is complete."),
        .summerCampaignAccessibility: ("夏季新客开户礼遇活动", "暑期新客開戶禮遇活動", "Summer new-client offer"),
        .limitedTime: ("限时活动", "活動到期即止", "LIMITED TIME"),
        .summerCampaignHeadline: ("夏季新客开户礼遇", "暑期新客開戶禮遇", "SUMMER WELCOME OFFER"),
        .summerCampaignPeriod: ("活动期限 2026.7.10–10.31", "活動期限 2026.7.10–10.31", "JUL 10 – OCT 31, 2026"),
        .simulateLiveData: ("模拟实时数据", "模擬即時資料", "Simulate Live Data"),
        .liveDataOn: ("不同资产会以各自节奏持续刷新", "不同資產會按各自節奏持續更新", "Each asset refreshes continuously at its own pace."),
        .liveDataOff: ("开启后模拟推送，数字会小幅变化", "開啟後模擬推送，數值會輕微變動", "Simulates live updates with small value changes."),
        .mrTestMode: ("MR 测试状态", "MR 測試狀態", "MR Test Mode"),
        .mrTestDetails: ("股票和基金显示系统升级状态，虚拟资产保持正常", "股票與基金顯示系統升級狀態，虛擬資產維持正常", "Stocks and funds show maintenance; virtual assets remain available."),
        .showSummerCampaign: ("显示夏季运营广告", "顯示夏季營運廣告", "Show Summer Campaign Banner"),
        .summerCampaignDetails: ("在总资产下方展示夏季新客活动图", "在總資產下方顯示夏季新客活動圖", "Show the summer new-client banner below Total Assets."),
        .enableDebugStateMatrix: ("启用调试状态矩阵", "啟用除錯狀態矩陣", "Enable Debug State Matrix"),
        .restoreNormalAndLiveData: ("恢复正常并启用实时数据", "恢復正常並啟用即時資料", "Restore Normal State and Enable Live Data")
    ]

    static let securityNames: [String: Values] = [
        "hk-tencent": ("腾讯控股", "騰訊控股", "Tencent"),
        "hk-hstech": ("南方恒生科技", "南方恆生科技", "CSOP HST"),
        "hk-alibaba": ("阿里巴巴-W", "阿里巴巴-W", "Alibaba-W"),
        "hk-xiaomi": ("小米集团-W", "小米集團-W", "Xiaomi-W"),
        "cn-tcl": ("TCL 科技", "TCL 科技", "TCL Tech"),
        "cn-powerchina": ("中国电建", "中國電建", "POWERCHINA"),
        "cn-moutai": ("贵州茅台", "貴州茅台", "Moutai"),
        "cn-byd": ("比亚迪", "比亞迪", "BYD"),
        "cn-catl": ("宁德时代", "寧德時代", "CATL"),
        "cn-cmb": ("招商银行", "招商銀行", "CMB"),
        "us-apple": ("苹果", "蘋果", "Apple"),
        "us-nvidia": ("英伟达", "英偉達", "NVIDIA"),
        "us-tesla": ("特斯拉", "特斯拉", "Tesla"),
        "us-microsoft": ("微软", "微軟", "Microsoft"),
        "fund-hkd-1": ("南方港元货币市场基金", "南方港元貨幣市場基金", "CSOP HKD Money Market Fund"),
        "fund-hkd-2": ("汇丰环球货币基金-港元", "滙豐環球貨幣基金－港元", "HSBC Global Money Fund – HKD"),
        "fund-usd-1": ("摩根美元货币基金", "摩根美元貨幣基金", "JPMorgan USD Money Market Fund"),
        "fund-usd-2": ("富兰克林美元短债基金", "富蘭克林美元短債基金", "Franklin USD Short Duration Bond Fund"),
        "fund-cny-1": ("华夏人民币货币基金", "華夏人民幣貨幣基金", "ChinaAMC RMB Money Market Fund"),
        "fund-cny-2": ("易方达稳健短债基金", "易方達穩健短債基金", "E Fund Stable Short-Term Bond Fund"),
        "crypto-btc": ("比特币", "比特幣", "Bitcoin"),
        "crypto-eth": ("以太币", "以太幣", "Ether"),
        "crypto-sol": ("Solana", "Solana", "Solana"),
        "crypto-xrp": ("瑞波币", "瑞波幣", "XRP"),
        "crypto-doge": ("狗狗币", "狗狗幣", "Dogecoin"),
        "crypto-link": ("Chainlink", "Chainlink", "Chainlink"),
        "rwa-xaua": ("黄金代币", "黃金代幣", "Tokenized Gold"),
        "wl-hk-alibaba": ("阿里巴巴-W", "阿里巴巴-W", "Alibaba-W"),
        "wl-hk-tencent": ("腾讯控股", "騰訊控股", "Tencent"),
        "wl-hk-xiaomi": ("小米集团-W", "小米集團-W", "Xiaomi-W"),
        "wl-hk-meituan": ("美团-W", "美團-W", "Meituan-W"),
        "wl-cn-catl": ("宁德时代", "寧德時代", "CATL"),
        "wl-cn-moutai": ("贵州茅台", "貴州茅台", "Moutai"),
        "wl-cn-byd": ("比亚迪", "比亞迪", "BYD"),
        "wl-cn-cmb": ("招商银行", "招商銀行", "CMB"),
        "wl-us-nvidia": ("英伟达", "英偉達", "NVIDIA"),
        "wl-us-apple": ("苹果", "蘋果", "Apple"),
        "wl-us-tesla": ("特斯拉", "特斯拉", "Tesla"),
        "wl-us-microsoft": ("微软", "微軟", "Microsoft"),
        "wl-etf-hstech": ("恒生科技ETF", "恒生科技ETF", "Hang Seng TECH ETF"),
        "wl-etf-nasdaq-cn": ("纳指100ETF", "納指100ETF", "Nasdaq-100 ETF"),
        "wl-fund-energy": ("贝莱德世界能源基金", "貝萊德世界能源基金", "World Energy Fund"),
        "wl-etf-voo": ("先锋标普500ETF", "先鋒標普500ETF", "Vanguard S&P 500"),
        "wl-etf-qqq": ("纳指100ETF", "納指100ETF", "Nasdaq-100 ETF"),
        "wl-crypto-btc": ("比特币/美元", "比特幣/美元", "Bitcoin/USD"),
        "wl-crypto-eth": ("以太坊/美元", "以太坊/美元", "Ethereum/USD"),
        "wl-us-alibaba": ("阿里巴巴", "阿里巴巴", "Alibaba"),
        "wl-etf-fxi": ("安硕中国大盘ETF", "安碩中國大型股ETF", "China Large-Cap ETF")
    ]

    static let watchlistNameIDs: [String: String] = [
        "09988": "wl-hk-alibaba",
        "00700": "wl-hk-tencent",
        "01810": "wl-hk-xiaomi",
        "03690": "wl-hk-meituan",
        "300750": "wl-cn-catl",
        "600519": "wl-cn-moutai",
        "002594": "wl-cn-byd",
        "600036": "wl-cn-cmb",
        "NVDA": "wl-us-nvidia",
        "AAPL": "wl-us-apple",
        "TSLA": "wl-us-tesla",
        "MSFT": "wl-us-microsoft",
        "03032": "wl-etf-hstech",
        "513100": "wl-etf-nasdaq-cn",
        "LU012376428": "wl-fund-energy",
        "VOO": "wl-etf-voo",
        "QQQ": "wl-etf-qqq",
        "BTC/USD": "wl-crypto-btc",
        "ETH/USD": "wl-crypto-eth",
        "BABA": "wl-us-alibaba",
        "FXI": "wl-etf-fxi"
    ]

    static let englishAccessibility: [DemoCopyKey: String] = [
        .securitiesMarketValue: "Securities Market Value",
        .positionProfitLoss: "Position Profit/Loss",
        .fundsInTransit: "Funds in Transit",
        .ipoFundsInTransit: "IPO Funds in Transit",
        .fundsOnHold: "Funds on Hold",
        .cashAvailable: "Cash Available to Trade",
        .cashWithdrawable: "Withdrawable Cash",
        .maximumBuyingPower: "Maximum Buying Power",
        .fundMarketValue: "Fund Market Value",
        .positionIncome: "Position Income",
        .virtualAssetMarketValue: "Virtual Asset Market Value",
        .todayOrders: "Today's Orders",
        .transactionHistory: "Transaction History",
        .recurringInvestment: "My Recurring Investments",
        .internalTransfer: "Internal Funds Transfer",
        .marketValueQuantityHeader: "Market Value and Quantity",
        .lastCostHeader: "Last Price and Average Cost",
        .dayProfitLossHeader: "Today's Profit/Loss",
        .positionProfitLossHeader: "Position Profit/Loss",
        .portfolioWeightHeader: "Portfolio Weight",
        .marketValueYesterdayHeader: "Market Value and One-Day Profit/Loss",
        .positionIncomeHeader: "Position Income",
        .recurringInvestmentTag: "Automatic Investment Plan"
    ]
}

struct DemoLanguagePicker: View {
    @Binding var language: DemoLanguage
    @Environment(\.demoLanguage) private var interfaceLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(interfaceLanguage.text(.interfaceLanguage))
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))

            Picker(interfaceLanguage.text(.interfaceLanguage), selection: $language) {
                ForEach(DemoLanguage.allCases) { option in
                    Text(option.nativeName)
                        .tag(option)
                        .accessibilityIdentifier("demo.language.option.\(option.rawValue)")
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("demo.language.picker")
        }
    }
}
