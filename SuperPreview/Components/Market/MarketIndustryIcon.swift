//
//  MarketIndustryIcon.swift
//  SuperPreview
//
//  行业图标分类及简体、繁体、英文行业名称映射。
//  来源：钉钉「港股与美股行业」分类版与去重版；详见 DesignReferences/MarketIndustryIcons.json。
//

import Foundation

enum MarketIndustryIcon: String, CaseIterable {
    case preciousMetals = "precious_metals"
    case marineShipping = "marine_shipping"
    case industrialManufacturing = "industrial_manufacturing"
    case industrialMachinery = "industrial_machinery"
    case mining = "mining"
    case textiles = "textiles"
    case officeSupplies = "office_supplies"
    case electronicEquipment = "electronic_equipment"
    case homeImprovementChains = "home_improvement_chains"
    case constructionEngineering = "construction_engineering"
    case miscellaneous = "miscellaneous"
    case autoPartsAftermarket = "auto_parts_aftermarket"
    case oilGas = "oil_gas"
    case railroads = "railroads"
    case leisure = "leisure"
    case semiconductorsComponents = "semiconductors_components"
    case insurance = "insurance"
    case gaming = "gaming"
    case distributors = "distributors"
    case airlines = "airlines"
    case aerospaceDefense = "aerospace_defense"
    case airFreight = "air_freight"
    case dataProcessing = "data_processing"
    case investmentManagers = "investment_managers"
    case tobacco = "tobacco"
    case drugstoreChains = "drugstore_chains"
    case generalGovernment = "general_government"
    case commercialPrinting = "commercial_printing"
    case advertisingMarketing = "advertising_marketing"
    case electricUtilities = "electric_utilities"
    case aluminum = "aluminum"
    case gasDistributors = "gas_distributors"
    case meatFishDairy = "meat_fish_dairy"
    case waterUtilities = "water_utilities"
    case specialtyFoodCandy = "specialty_food_candy"
    case television = "television"
    case nonAlcoholicBeverages = "non_alcoholic_beverages"
    case apparelFootwear = "apparel_footwear"
    case steel = "steel"
    case alcoholicBeverages = "alcoholic_beverages"
    case broadcasting = "broadcasting"
    case mediaEntertainment = "media_entertainment"
    case specializedTechnology = "specialized_technology"
    case publishing = "publishing"
    case apparelLuxuryGoods = "apparel_luxury_goods"
    case telecommunications = "telecommunications"
    case toolsHardware = "tools_hardware"
    case chemicals = "chemicals"
    case environmentalServices = "environmental_services"
    case realEstate = "real_estate"
    case truckingLogistics = "trucking_logistics"
    case householdGoods = "household_goods"
    case internetRetail = "internet_retail"
    case homeAppliances = "home_appliances"
    case constructionMaterials = "construction_materials"
    case hotelsRestaurants = "hotels_restaurants"
    case retail = "retail"
    case coal = "coal"
    case agriculturalProducts = "agricultural_products"
    case automobiles = "automobiles"
    case containersPackaging = "containers_packaging"
    case softwareInternetServices = "software_internet_services"
    case commercialServices = "commercial_services"
    case foodBeverages = "food_beverages"
    case healthCare = "health_care"
    case banks = "banks"
    case paperForestProducts = "paper_forest_products"
    case pharmaceuticalsBiotechnology = "pharmaceuticals_biotechnology"
    case diversifiedFinancials = "diversified_financials"
    case utilitiesAlternativeEnergy = "utilities_alternative_energy"
    case conglomerates = "conglomerates"
    case computerHardware = "computer_hardware"
    case farmMachinery = "farm_machinery"

    var assetName: String { "market_industry_\(rawValue)" }

    static func matching(industryName: String) -> Self {
        industryNames[normalized(industryName)] ?? .miscellaneous
    }

    private static func normalized(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static let industryNames: [String: Self] = {
        let groups: [(Self, [String])] = [
            (.preciousMetals, ["贵金属", "貴金屬", "Precious Metals", "黄金与贵金属", "黃金與貴金屬", "Gold & Precious Metals"]),
            (.marineShipping, ["海上运输", "海上航运", "海上航運", "Marine Shipping"]),
            (.industrialManufacturing, ["工业制造", "工业制品", "工業製品", "Industrial Products", "工业专业产品", "工業專業產品", "Industrial Specialties", "工业综合企业", "工業綜合企業", "Industrial Conglomerates", "其他制造业", "其他製造業", "Miscellaneous Manufacturing"]),
            (.industrialMachinery, ["工业机械", "工業機械", "Industrial Machinery", "工业机械与设备", "工業機械與設備", "Industrial Machinery & Equipment"]),
            (.mining, ["矿产", "金属加工", "金屬加工", "Metal Fabrication", "金属与采矿", "金屬與採礦", "Metals & Mining", "其他金属/矿产", "其他金屬/礦產", "Other Metals/Minerals"]),
            (.textiles, ["纺织品", "紡織品", "Textiles"]),
            (.officeSupplies, ["办公用品", "办公设备/用品", "辦公設備/用品", "Office Equipment/Supplies"]),
            (.electronicEquipment, ["电子设备", "电子设备/仪器", "電子設備/儀器", "Electronic Equipment/Instruments", "电子生产设备", "電子生產設備", "Electronic Production Equipment", "计算机外围设备", "電腦周邊設備", "Computer Peripherals"]),
            (.homeImprovementChains, ["家居装修连锁店", "家居裝修連鎖店", "Home Improvement Chains"]),
            (.constructionEngineering, ["建筑与工程", "工程与建筑", "工程與建築", "Engineering & Construction", "建筑", "建築", "Construction"]),
            (.miscellaneous, ["其他", "Miscellaneous"]),
            (.autoPartsAftermarket, ["汽车零部件与售后", "汽车零部件：原厂", "汽車零部件：原廠", "Auto Parts: OEM", "汽车售后市场", "汽車售後市場", "Automotive Aftermarket"]),
            (.oilGas, ["石油与天然气", "合约钻井", "合約鑽井", "Contract Drilling", "炼油/营销", "煉油/營銷", "Oil Refining/Marketing", "石油與天然氣", "Oil & Gas", "石油与天然气管道", "石油與天然氣管道", "Oil & Gas Pipelines", "石油与天然气生产", "石油與天然氣生產", "Oil & Gas Production", "油田服务/设备", "油田服務/設備", "Oilfield Services/Equipment", "综合石油", "綜合石油", "Integrated Oil"]),
            (.railroads, ["铁路", "鐵路", "Railroads"]),
            (.leisure, ["休闲", "休闲产品", "休閒產品", "Recreational Products", "休闲设备与用品", "休閒設備與用品", "Leisure Products"]),
            (.semiconductorsComponents, ["半导体与电子元件", "半导体", "半導體", "Semiconductors", "电子元件", "電子元件", "Electronic Components"]),
            (.insurance, ["保险", "保險", "Insurance", "保险经纪/服务", "保險經紀/服務", "Insurance Brokers/Services", "财产/意外保险", "財產/意外保險", "Property/Casualty Insurance", "多元保险", "多元保險", "Multi-Line Insurance", "人寿/健康保险", "人壽/健康保險", "Life/Health Insurance", "专业保险", "專業保險", "Specialty Insurance"]),
            (.gaming, ["博彩", "赌场/博彩", "賭場/博彩", "Casinos/Gaming"]),
            (.distributors, ["分销商", "电子产品分销商", "電子產品分銷商", "Electronics Distributors", "目录/专业分销", "目錄/專業分銷", "Catalog/Specialty Distribution", "批发分销商", "批發分銷商", "Wholesale Distributors", "食品分销商", "食品分銷商", "Food Distributors", "医疗分销商", "醫療分銷商", "Medical Distributors"]),
            (.airlines, ["航空公司", "Airlines"]),
            (.aerospaceDefense, ["航空航天与国防", "航空航天與國防", "Aerospace & Defense"]),
            (.airFreight, ["航空货运", "航空货运/快递", "航空貨運/速遞", "Air Freight/Couriers"]),
            (.dataProcessing, ["数据处理服务", "數據處理服務", "Data Processing Services"]),
            (.investmentManagers, ["投资管理人", "投資管理人", "Investment Managers", "投资银行/经纪", "投資銀行/經紀", "Investment Banks/Brokers"]),
            (.tobacco, ["烟草", "煙草", "Tobacco"]),
            (.drugstoreChains, ["药房连锁店", "藥房連鎖店", "Drugstore Chains"]),
            (.generalGovernment, ["一般政府", "General Government"]),
            (.commercialPrinting, ["商业印刷/表格", "商業印刷/表格", "Commercial Printing/Forms"]),
            (.advertisingMarketing, ["广告/营销服务", "廣告/營銷服務", "Advertising/Marketing Services"]),
            (.electricUtilities, ["电力公用事业", "電力公用事業", "Electric Utilities", "电气产品", "電氣產品", "Electrical Products"]),
            (.aluminum, ["铝", "鋁", "Aluminum"]),
            (.gasDistributors, ["燃气分销商", "燃氣分銷商", "Gas Distributors"]),
            (.meatFishDairy, ["食品：肉类+鱼类+乳制品", "食品：肉类/鱼类/乳制品", "食品：肉類/魚類/乳製品", "Food: Meat/Fish/Dairy"]),
            (.waterUtilities, ["水务公用事业", "水務公用事業", "Water Utilities"]),
            (.specialtyFoodCandy, ["特色食品+糖果", "特色食品/糖果", "Food: Specialty/Candy"]),
            (.television, ["电视", "有线/卫星电视", "有線/衛星電視", "Cable/Satellite TV"]),
            (.nonAlcoholicBeverages, ["非酒精饮料", "非酒精飲料", "Beverages: Non-Alcoholic"]),
            (.apparelFootwear, ["服装+鞋类", "服装/鞋类", "服裝/鞋類", "Apparel/Footwear", "服装/鞋类零售", "服裝/鞋類零售", "Apparel/Footwear Retail"]),
            (.steel, ["钢铁", "鋼鐵", "Steel"]),
            (.alcoholicBeverages, ["酒精饮料", "酒精飲料", "Beverages: Alcoholic"]),
            (.broadcasting, ["广播", "廣播", "Broadcasting"]),
            (.mediaEntertainment, ["影视与广播电视", "电影/娱乐", "電影/娛樂", "Movies/Entertainment", "媒体与娱乐", "媒體與娛樂", "Media & Entertainment", "媒体综合企业", "媒體綜合企業", "Media Conglomerates"]),
            (.specializedTechnology, ["特专科技", "特專科技", "Specialized Technology"]),
            (.publishing, ["出版", "出版：报纸", "出版：報紙", "Publishing: Newspapers", "出版：书籍/杂志", "出版：書籍/雜誌", "Publishing: Books/Magazines"]),
            (.apparelLuxuryGoods, ["服装、鞋类与奢侈品", "纺织品、服装与奢侈品", "紡織品、服裝與奢侈品", "Textiles, Apparel & Luxury Goods"]),
            (.telecommunications, ["电信", "电信设备", "電訊設備", "Telecommunications Equipment", "电讯业", "電訊業", "Telecommunications", "计算机通信", "電腦通訊", "Computer Communications", "无线电信", "無線電訊", "Wireless Telecommunications", "主要电信", "主要電訊", "Major Telecommunications", "专业电信", "專業電訊", "Specialty Telecommunications"]),
            (.toolsHardware, ["工具与五金", "工具與五金", "Tools & Hardware"]),
            (.chemicals, ["化工", "大型综合化工", "大型綜合化工", "Chemicals: Major Diversified", "化工产品", "化工產品", "Chemicals", "农业化学品", "農業化學品", "Chemicals: Agricultural", "特种化学品", "特種化學品", "Chemicals: Specialty"]),
            (.environmentalServices, ["环境服务", "環境服務", "Environmental Services"]),
            (.realEstate, ["房地产", "地产", "地產", "Real Estate", "房地产开发", "房地產開發", "Real Estate Development", "住宅建筑", "住宅建築", "Homebuilding"]),
            (.truckingLogistics, ["公路货运与物流", "货运卡车", "貨運卡車", "Trucking", "其他运输", "其他運輸", "Other Transportation", "运输", "運輸", "Transportation"]),
            (.householdGoods, ["家庭日用品", "家居用品", "Home Furnishings", "家庭/个人护理", "家庭/個人護理", "Household/Personal Care", "家庭耐用消费品", "家庭耐用消費品", "Household Durables", "家庭与个人用品", "家庭與個人用品", "Household & Personal Products", "其他特色消费品", "其他特色消費品", "Other Consumer Specialties", "日用消费品", "日用消費品", "Consumer Sundries"]),
            (.internetRetail, ["互联网零售", "互聯網零售", "Internet Retail"]),
            (.homeAppliances, ["家电", "电子产品/家电", "電子產品/家電", "Electronics/Appliances", "电子产品/家电商店", "電子產品/家電商店", "Electronics/Appliance Stores"]),
            (.constructionMaterials, ["建筑材料", "建築材料", "Construction Materials", "建筑产品", "建築產品", "Building Products"]),
            (.hotelsRestaurants, ["酒店餐馆", "餐馆", "餐館", "Restaurants", "酒店/度假村/邮轮", "酒店/度假村/郵輪", "Hotels/Resorts/Cruise lines", "酒店、餐馆与休闲", "酒店、餐館與休閒", "酒店餐馆与休闲", "Hotels, Restaurants & Leisure"]),
            (.retail, ["零售业", "百货商店", "百貨公司", "Department Stores", "零售業", "Retailing", "食品零售", "Food Retail", "折扣店", "Discount Stores", "专业商店", "專業商店", "Specialty Stores"]),
            (.coal, ["煤炭", "Coal"]),
            (.agriculturalProducts, ["农产品", "農產品", "Agricultural Products", "农业商品/制粉", "農業商品/製粉", "Agricultural Commodities/Milling"]),
            (.automobiles, ["汽车", "汽車", "Automobiles", "Motor Vehicles", "Automobiles / Motor Vehicles"]),
            (.containersPackaging, ["容器与包装", "容器與包裝", "Containers & Packaging", "Containers/Packaging", "Containers & Packaging / Containers/Packaging"]),
            (.softwareInternetServices, ["软件与互联网服务", "互联网软件/服务", "互聯網軟件/服務", "Internet Software/Services", "软件服务", "軟件服務", "Software Services", "套装软件", "套裝軟件", "Packaged Software", "信息技术服务", "資訊科技服務", "Information Technology Services", "互联网内容与信息"]),
            (.commercialServices, ["商业服务", "其他商业服务", "其他商業服務", "Miscellaneous Commercial Services", "其他消费者服务", "其他消費者服務", "Other Consumer Services", "人力服务", "人力服務", "Personnel Services", "支援服务", "支援服務", "Support Services"]),
            (.foodBeverages, ["食品与饮料", "大型综合食品", "大型綜合食品", "Food: Major Diversified", "食品與飲料", "Food & Beverage"]),
            (.healthCare, ["医疗健康", "管理式医疗保健", "管理式醫療保健", "Managed Health Care", "医疗/护理服务", "醫療/護理服務", "Medical/Nursing Services", "医疗保健设备与服务", "醫療保健設備與服務", "Health Care Equipment & Services", "医疗行业服务", "醫療行業服務", "Services to the Health Industry", "医疗专科", "醫療專科", "Medical Specialties", "医院/护理管理", "醫院/護理管理", "Hospital/Nursing Management"]),
            (.banks, ["银行", "储蓄银行", "儲蓄銀行", "Savings Banks", "大型银行", "大型銀行", "Major Banks", "地区银行", "地區銀行", "Regional Banks", "銀行", "Banks"]),
            (.paperForestProducts, ["纸业与林业", "林业产品", "林業產品", "Forest Products", "纸浆与造纸", "紙漿與造紙", "Pulp & Paper", "纸类与林业产品", "紙類與林業產品", "Paper & Forest Products"]),
            (.pharmaceuticalsBiotechnology, ["制药与生物科技", "制药", "大型制药", "大型製藥", "Pharmaceuticals: Major", "仿制药", "仿製藥", "Pharmaceuticals: Generic", "其他制药", "其他製藥", "Pharmaceuticals: Other", "生物科技", "Biotechnology", "製藥與生物科技", "Pharmaceuticals & Biotechnology"]),
            (.diversifiedFinancials, ["综合金融", "房地产投资信托基金", "房地產投資信託基金", "Real Estate Investment Trusts", "金融/租赁", "金融/租賃", "Finance/Rental/Leasing", "金融出版/服务", "金融出版/服務", "Financial Publishing/Services", "投资信托/共同基金", "投資信託/互惠基金", "Investment Trusts/Mutual Funds", "综合金融服务", "綜合金融服務", "Diversified Financials"]),
            (.utilitiesAlternativeEnergy, ["公用事业与替代能源", "公用事业", "公用事業", "Utilities", "替代能源发电", "替代能源發電", "Alternative Power Generation"]),
            (.conglomerates, ["综合企业", "金融综合企业", "金融綜合企業", "Financial Conglomerates", "綜合企業", "Conglomerates"]),
            (.computerHardware, ["计算机硬件", "计算机处理硬件", "電腦處理硬件", "Computer Processing Hardware", "资讯科技硬件与设备", "資訊科技硬件與設備", "Information Technology Hardware & Equipment"]),
            (.farmMachinery, ["农业机械", "卡车/建筑/农业机械", "卡車/建築/農業機械", "Trucks/Construction/Farm Machinery"]),
        ]
        var result: [String: Self] = [:]
        for (icon, names) in groups {
            for name in names { result[normalized(name)] = icon }
        }
        return result
    }()
}
