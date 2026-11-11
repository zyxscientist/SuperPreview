// Stock detail chart labels from BrokerQuotes QuotesLocalization.bundle.
// Simplified Chinese is the source key used by QuotesLocal.
import Foundation

enum StockChartText: String {
    case intraday = "分时", fiveDay = "五日", daily = "日K", weekly = "周K", monthly = "月K", minute = "分钟"
    case minute1 = "1分", minute3 = "3分", minute5 = "5分", minute15 = "15分", minute30 = "30分", minute60 = "60分"
    case preMarket = "盘前", regularMarket = "盘中", afterHours = "盘后", allDay = "全天"
    case adjustedForward = "前复权", unadjusted = "不复权", adjustedBackward = "后复权"
    case indicatorSettings = "指标设置", mainIndicator = "主图指标", subIndicator = "副图指标", priceAdjustment = "除复权设置", landscapeMode = "横屏模式"
    case chartAnnotations = "图表标注", tradeMarks = "买卖打点", currentPriceLine = "现价线", positionCostLine = "持仓成本线", priceAlertLine = "到价提醒线", corporateAction = "公司行动"
    case parameterSettings = "参数设置", save = "保存", movingAveragePeriod = "移动平均周期", parameterPeriod = "周期", standardDeviation = "标准差倍数"
    case fastPeriod = "快线周期", slowPeriod = "慢线周期", signalPeriod = "信号线周期", calculationPeriod = "计算周期", smoothing1 = "移动平均周期1", smoothing2 = "移动平均周期2"
    case resetParameters = "恢复默认参数", confirmReset = "确定恢复为默认参数？", cancel = "取消", confirm = "确定"
    case time = "时间", price = "价格", averagePrice = "均价", open = "开盘", high = "最高", low = "最低", close = "收盘"
    case transactionDetails = "逐笔明细", latestTrades = "回到最新↓"
    case volume = "成交量", turnover = "成交额", changePercent = "涨跌幅", change = "涨跌额"
    case compactOpen = "开", compactHigh = "高", compactLow = "低", compactClose = "收", compactVolume = "量", compactChange = "额", compactChangePercent = "幅"
}

func stockChartText(_ key: StockChartText, language: DemoLanguage) -> String {
    if language == .simplifiedChinese { return key.rawValue }
    let translated: (traditional: String, english: String)
    switch key {
    case .intraday: translated = ("分時", "1D")
    case .fiveDay: translated = ("五日", "5D")
    case .daily: translated = ("日K", "Daily")
    case .weekly: translated = ("週K", "Weekly")
    case .monthly: translated = ("月K", "Monthly")
    case .minute: translated = ("分鐘", "Min")
    case .minute1: translated = ("1分", "1m")
    case .minute3: translated = ("3分", "3m")
    case .minute5: translated = ("5分", "5m")
    case .minute15: translated = ("15分", "15m")
    case .minute30: translated = ("30分", "30m")
    case .minute60: translated = ("60分", "60m")
    case .preMarket: translated = ("盤前", "Pre")
    case .regularMarket: translated = ("盤中", "RTH")
    case .afterHours: translated = ("盤後", "After")
    case .allDay: translated = ("全天", "All")
    case .adjustedForward: translated = ("前復權", "Adj Fwd")
    case .unadjusted: translated = ("不復權", "Actual")
    case .adjustedBackward: translated = ("後復權", "Adj Bwd")
    case .indicatorSettings: translated = ("指標設定", "Indicator Settings")
    case .mainIndicator: translated = ("主圖指標", "Main Chart")
    case .subIndicator: translated = ("副圖指標", "Sub Chart")
    case .priceAdjustment: translated = ("除復權設定", "Price adjustment")
    case .landscapeMode: translated = ("橫屏模式", "Landscape mode")
    case .chartAnnotations: translated = ("圖表標註", "Chart Annotations")
    case .tradeMarks: translated = ("買賣打點", "Trade Marks")
    case .currentPriceLine: translated = ("現價線", "Current Price Line")
    case .positionCostLine: translated = ("持倉成本線", "Position Cost Line")
    case .priceAlertLine: translated = ("到價提醒線", "Price Alert Line")
    case .corporateAction: translated = ("公司行動", "Corporate Action")
    case .parameterSettings: translated = ("參數設定", "Setting")
    case .save: translated = ("保存", "Save")
    case .movingAveragePeriod: translated = ("移動平均週期", "Moving average period")
    case .parameterPeriod: translated = ("週期", "Period")
    case .standardDeviation: translated = ("標准差倍數", "StdDev")
    case .fastPeriod: translated = ("快線週期", "Fast length")
    case .slowPeriod: translated = ("慢線週期", "Slow length")
    case .signalPeriod: translated = ("信號線週期", "Signal length")
    case .calculationPeriod: translated = ("計算週期", "%K period")
    case .smoothing1: translated = ("移動平均週期1", "%K smoothing")
    case .smoothing2: translated = ("移動平均週期2", "%D smoothing")
    case .resetParameters: translated = ("恢覆默認參數", "Reset to Default")
    case .confirmReset: translated = ("確定恢覆默認參數？", "Reset parameters to default?")
    case .cancel: translated = ("取消", "Cancel")
    case .confirm: translated = ("確定", "Confirm")
    case .time: translated = ("時間", "Date")
    case .price: translated = ("價格", "Price")
    case .averagePrice: translated = ("均價", "Avg Price")
    case .open: translated = ("開盤", "Open")
    case .high: translated = ("最高", "High")
    case .low: translated = ("最低", "Low")
    case .close: translated = ("收盤", "Close")
    case .transactionDetails: translated = ("逐筆明細", "Details")
    case .latestTrades: translated = ("回到最新↓", "Latest↓")
    case .volume: translated = ("成交量", "Volume")
    case .turnover: translated = ("成交額", "Turnover")
    case .changePercent: translated = ("漲跌幅", "Chg%")
    case .change: translated = ("漲跌額", "Chg")
    case .compactOpen: translated = ("開", "Open")
    case .compactHigh: translated = ("高", "High")
    case .compactLow: translated = ("低", "Low")
    case .compactClose: translated = ("收", "Close")
    case .compactVolume: translated = ("量", "Vol.")
    case .compactChange: translated = ("額", "Chg")
    case .compactChangePercent: translated = ("幅", "Chg%")
    }
    return language == .traditionalChinese ? translated.traditional : translated.english
}
