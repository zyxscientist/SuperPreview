//
//  NewsLocalization.swift
//  SuperPreview
//

import Foundation

/// A single piece of news UI or mock content with its three supported languages.
struct NewsLocalizedText: Codable, Hashable, Sendable {
    let simplified: String
    let traditional: String
    let english: String

    init(simplified: String, traditional: String, english: String) {
        self.simplified = simplified
        self.traditional = traditional
        self.english = english
    }

    func text(in language: DemoLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            return simplified
        case .traditionalChinese:
            return traditional
        case .english:
            return english
        }
    }
}

extension DemoLanguage {
    func resolve(_ text: NewsLocalizedText) -> String {
        text.text(in: self)
    }
}

/// Static copy owned by the news demo. News headlines and bodies stay data.
enum NewsDemoCopy {
    static let detail = NewsLocalizedText(
        simplified: "详情",
        traditional: "詳情",
        english: "Details"
    )

    static let back = NewsLocalizedText(
        simplified: "返回",
        traditional: "返回",
        english: "Back"
    )

    static let addFavorite = NewsLocalizedText(
        simplified: "收藏",
        traditional: "收藏",
        english: "Add to favorites"
    )

    static let removeFavorite = NewsLocalizedText(
        simplified: "取消收藏",
        traditional: "取消收藏",
        english: "Remove from favorites"
    )

    static let favorited = NewsLocalizedText(
        simplified: "已收藏",
        traditional: "已收藏",
        english: "Saved"
    )

    static let notFavorited = NewsLocalizedText(
        simplified: "未收藏",
        traditional: "未收藏",
        english: "Not saved"
    )

    static let demoArticleNotice = NewsLocalizedText(
        simplified: "演示内容：以下正文仅用于界面展示",
        traditional: "示範內容：以下正文僅供介面展示",
        english: "Demo content: The article below is for interface demonstration only."
    )

    static let guide = NewsLocalizedText(
        simplified: "云锋导读",
        traditional: "雲鋒導讀",
        english: "Yunfeng Guide"
    )

    static let authorPrefix = NewsLocalizedText(
        simplified: "作者：",
        traditional: "作者：",
        english: "By "
    )

    static let sourcePrefix = NewsLocalizedText(
        simplified: "来源: ",
        traditional: "來源: ",
        english: "Source: "
    )

    static let articleCopyright = NewsLocalizedText(
        simplified: "本文版权归原作者/机构所有",
        traditional: "本文版權歸原作者/機構所有",
        english: "All rights belong to the original author or organization."
    )

    static let articleImageDescription = NewsLocalizedText(
        simplified: "特斯拉 Cybertruck 行驶在沙漠公路",
        traditional: "特斯拉 Cybertruck 行駛在沙漠公路",
        english: "Tesla Cybertruck driving on a desert road"
    )

    static let postMarket = NewsLocalizedText(
        simplified: "盘后",
        traditional: "盤後",
        english: "Post"
    )

    static let featuredTopics = NewsLocalizedText(
        simplified: "精选专题",
        traditional: "精選專題",
        english: "Featured Topics"
    )

    static let openArticleDetailsHint = NewsLocalizedText(
        simplified: "打开资讯详情。",
        traditional: "開啟資訊詳情。",
        english: "Open article details."
    )

    static let disclaimer = NewsLocalizedText(
        simplified: "文章内容仅代表作者观点，与云锋有鱼立场无关。本文仅供投资参考，亦不构成任何投资建议。为了提供更好的阅读体验，云锋有鱼对原网页版式进行了优化调整，您可以通过选择「原始网页」切换至源网页。如对云锋有鱼提供的“阅读模式”服务有任何疑问或建议，欢迎联系。",
        traditional: "文章內容僅代表作者觀點，與雲鋒有魚立場無關。本文僅供投資參考，亦不構成任何投資建議。為了提供更好的閱讀體驗，雲鋒有魚對原網頁版式進行了優化調整，您可以透過選擇「原始網頁」切換至來源網頁。如對雲鋒有魚提供的「閱讀模式」服務有任何疑問或建議，歡迎聯絡。",
        english: "The views expressed in this article are those of the author and do not reflect the position of Yunfeng Youyu. This article is for investment reference only and does not constitute investment advice. To improve the reading experience, Yunfeng Youyu has adapted the layout of the original webpage. Select “Original webpage” to view the source page. If you have any questions or suggestions about Yunfeng Youyu’s “Reading mode” service, please contact us."
    )

    /// Fixed copy for the original Apple/Tesla detail example.
    enum AppleCarStory {
        static let title = NewsLocalizedText(
            simplified: "苹果(AAPL.US)造车或成为特斯拉(TSLA.US)重大利空，维持目标价880美元",
            traditional: "蘋果(AAPL.US)造車或成特斯拉(TSLA.US)重大利空，維持目標價880美元",
            english: "Apple’s (AAPL.US) car project could be a major negative for Tesla (TSLA.US); US$880 target price maintained"
        )

        static let exclusiveTag = NewsLocalizedText(
            simplified: "独家",
            traditional: "獨家",
            english: "Exclusive"
        )

        static let researchSource = NewsLocalizedText(
            simplified: "有鱼投研",
            traditional: "有魚投研",
            english: "Yunfeng Research"
        )

        static let authorNames = NewsLocalizedText(
            simplified: "刘少杰 苏扬",
            traditional: "劉少傑 蘇揚",
            english: "Liu Shaojie and Su Yang"
        )

        static let summary1 = NewsLocalizedText(
            simplified: "1.摩根士丹利发表研究报告表示，苹果(AAPL.US)造车将成为特斯拉(TSLA.US)重大利空，维持对后者目标价880美元。",
            traditional: "1.摩根士丹利發表研究報告表示，蘋果(AAPL.US)造車將成為特斯拉(TSLA.US)重大利空，維持對後者目標價880美元。",
            english: "1. Morgan Stanley said in a research report that Apple’s (AAPL.US) car project would be a major negative for Tesla (TSLA.US), and maintained its US$880 target price for Tesla."
        )

        static let summary2 = NewsLocalizedText(
            simplified: "2.摩根士丹利发表研究报告表。",
            traditional: "2.摩根士丹利發表研究報告表。",
            english: "2. Morgan Stanley published a research report."
        )

        static let summary3 = NewsLocalizedText(
            simplified: "3.分析师Adam Jonas表示:“如果苹果进入电动汽车市场，其占据的市场份额更有可能是33%，而非微弱的3%。",
            traditional: "3.分析師Adam Jonas表示：「如果蘋果進入電動汽車市場，其佔據的市場份額更有可能是33%，而非微弱的3%。」",
            english: "3. Analyst Adam Jonas said, “If Apple enters the electric vehicle market, it is more likely to capture 33% of the market, rather than a marginal 3%.”"
        )

        static let sectionHeading1 = NewsLocalizedText(
            simplified: "特斯拉以外电动车股多数再涨",
            traditional: "特斯拉以外電動車股多數再漲",
            english: "Most EV Stocks Other Than Tesla Rise Again"
        )

        static let body1 = NewsLocalizedText(
            simplified: "摩根士丹利发表研究报告表示，苹果(AAPL.US)造车将成为特斯拉(TSLA.US)重大利空，维持对后者目标价880美元。\n\n分析师Adam Jonas表示:“如果苹果进入电动汽车市场，其占据的市场份额更有可能是33%，而非微弱的3%。绝大多数客户都认为，在未来5到10年，传统OEM将是特斯拉的主要竞争对手。尽管正当的市场竞争都应该得到尊重，但苹果等公司进军新能源汽车行业将给特斯拉带来前所未有的竞争压力，”Jonas补充道。",
            traditional: "摩根士丹利發表研究報告表示，蘋果(AAPL.US)造車將成為特斯拉(TSLA.US)重大利空，維持對後者目標價880美元。\n\n分析師Adam Jonas表示：「如果蘋果進入電動汽車市場，其佔據的市場份額更有可能是33%，而非微弱的3%。絕大多數客戶都認為，在未來5到10年，傳統OEM將是特斯拉的主要競爭對手。儘管正當的市場競爭都應該得到尊重，但蘋果等公司進軍新能源汽車行業將給特斯拉帶來前所未有的競爭壓力，」Jonas補充道。",
            english: "Morgan Stanley said in a research report that Apple’s (AAPL.US) car project would be a major negative for Tesla (TSLA.US), and maintained its US$880 target price for Tesla.\n\nAnalyst Adam Jonas said, “If Apple enters the electric vehicle market, it is more likely to capture 33% of the market, rather than a marginal 3%. The vast majority of customers believe that traditional OEMs will be Tesla’s main competitors over the next five to ten years. While fair competition deserves respect, the entry of companies such as Apple into the new energy vehicle industry will place unprecedented competitive pressure on Tesla,” Jonas added."
        )

        static let sectionHeading2 = NewsLocalizedText(
            simplified: "标题",
            traditional: "標題",
            english: "Heading"
        )

        static let body2 = NewsLocalizedText(
            simplified: "对苹果和特斯拉来说，Jonas及其团队认为，其价值在于移动生态系统，尤其是数据和网络的价值，这超出了对特斯拉的正常销售单位与股价的分析。",
            traditional: "對蘋果和特斯拉來說，Jonas及其團隊認為，其價值在於移動生態系統，尤其是數據和網絡的價值，這超出了對特斯拉的正常銷售單位與股價的分析。",
            english: "For Apple and Tesla, Jonas and his team believe the value lies in the mobile ecosystem, especially the value of data and networks, which goes beyond an analysis of Tesla’s normal sales units and share price."
        )

        static let quote = NewsLocalizedText(
            simplified: "“对苹果和特斯拉来说，Jonas及其团队认为，其价值在于移动生态系统，尤其是数据和网络的价值，这超出了对特斯拉的正常销售单位与股价的分析。”-- Someone",
            traditional: "「對蘋果和特斯拉來說，Jonas及其團隊認為，其價值在於移動生態系統，尤其是數據和網絡的價值，這超出了對特斯拉的正常銷售單位與股價的分析。」-- Someone",
            english: "“For Apple and Tesla, Jonas and his team believe the value lies in the mobile ecosystem, especially the value of data and networks, which goes beyond an analysis of Tesla’s normal sales units and share price.” — Someone"
        )

        static let valuationPrefix = NewsLocalizedText(
            simplified: "摩根士丹利对特斯拉目标价为880美元，该目标价中有345美元来自核心汽车业务，该行预计到2030年，特斯拉汽车销售将达540万辆；另外，",
            traditional: "摩根士丹利對特斯拉目標價為880美元，該目標價中有345美元來自核心汽車業務，該行預計到2030年，特斯拉汽車銷售將達540萬輛；另外，",
            english: "Morgan Stanley’s US$880 target price for Tesla includes US$345 from the core automotive business. The bank expects Tesla to sell 5.4 million vehicles by 2030. In addition, "
        )

        static let valuationDCFModel = NewsLocalizedText(
            simplified: "基于DCF模型",
            traditional: "基於DCF模型",
            english: "using a DCF model"
        )

        static let valuationSuffix = NewsLocalizedText(
            simplified: "，该行预计到2030年，特斯拉移动服务支持业务(Tesla Mobility)的对应估值为77美元/股；此外，100美元来自第三方电池业务和电动车动力系统供应业务，75美元来自特斯拉能源的固定存储系统，36美元来自保险业务，246美元来自数据网络服务业务，该行预计到2030年该业务的每用户平均收入(ARPU)将达到100美元。",
            traditional: "，該行預計到2030年，特斯拉移動服務支持業務(Tesla Mobility)的對應估值為77美元/股；此外，100美元來自第三方電池業務和電動車動力系統供應業務，75美元來自特斯拉能源的固定存儲系統，36美元來自保險業務，246美元來自數據網絡服務業務，該行預計到2030年該業務的每用戶平均收入(ARPU)將達到100美元。",
            english: ", the bank values Tesla Mobility at US$77 per share by 2030. A further US$100 comes from third-party battery and electric-vehicle powertrain supply, US$75 from Tesla Energy’s stationary storage systems, US$36 from the insurance business, and US$246 from data-network services. The bank expects average revenue per user (ARPU) for that business to reach US$100 by 2030."
        )

        static let sourceName = NewsLocalizedText(
            simplified: "新浪财经",
            traditional: "新浪財經",
            english: "Sina Finance"
        )

        private static let relatedStockNames: [String: NewsLocalizedText] = [
            "摩根史丹利(MS.US)": NewsLocalizedText(
                simplified: "摩根史丹利(MS.US)",
                traditional: "摩根史丹利(MS.US)",
                english: "Morgan Stanley (MS.US)"
            ),
            "特斯拉(TSLA.US)": NewsLocalizedText(
                simplified: "特斯拉(TSLA.US)",
                traditional: "特斯拉(TSLA.US)",
                english: "Tesla (TSLA.US)"
            ),
            "BOSS直聘(BZ.US)": NewsLocalizedText(
                simplified: "BOSS直聘(BZ.US)",
                traditional: "BOSS直聘(BZ.US)",
                english: "BOSS Zhipin (BZ.US)"
            ),
            "富途控股(FUTU)": NewsLocalizedText(
                simplified: "富途控股(FUTU)",
                traditional: "富途控股(FUTU)",
                english: "Futu Holdings (FUTU)"
            ),
            "伯克希尔-Class A(BRK. A)": NewsLocalizedText(
                simplified: "伯克希尔-Class A(BRK. A)",
                traditional: "伯克希爾-Class A(BRK. A)",
                english: "Berkshire Hathaway Class A (BRK. A)"
            )
        ]

        static func relatedStockName(
            for originalName: String,
            language: DemoLanguage
        ) -> String {
            relatedStockNames[originalName]?.text(in: language) ?? originalName
        }
    }

    static func openTopicArticleListHint(
        topicTitle: String,
        language: DemoLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "打开\(topicTitle)文章列表。"
        case .traditionalChinese:
            return "開啟\(topicTitle)文章列表。"
        case .english:
            return "Open the article list for \(topicTitle)."
        }
    }

    static func accessibilitySeparator(for language: DemoLanguage) -> String {
        language == .english ? ", " : "，"
    }
}
