# 个股图表移植记录

## 参考基线与方案

正式工程：`YFFinancial` 的 `UI重构/developer_LiquidGlass`，远端提交 `86d1d0d1b82951122a45ba2f9f02db1a47ee3055`。使用独立只读 worktree 研究，未改正式工程工作区。

正式 K 线调用链是 `CStockDetailLineGroupView → CStockDetailDrawLine → CSGTrendView → CSGKlinesDataConverter / CSGContext`；分时由 `YYMinuteView / YYMinuteViewModel / YYTrendLogic` 等绘制。`YFChartLib` 不是可直接替换整块图表的独立组件。原代码还依赖行情 SDK、股票业务模型、主题、配置与账户服务，因此 demo 抽取其布局、路径绘制、窗口交互和指标公式，在 UIKit/Core Graphics 中实现绘图区，由 SwiftUI 管理周期、指标与弹层。

实现顺序：核对正式分支与调用链 → 提取尺寸、主题、资源和翻译 → 独立 mock / 指标计算 → 实现绘图及手势 → 共用组件接入详情、Scroll 与下单 → 数据及界面回归。

## 源码对照

以下路径以正式工程根目录为基准。

| 正式源码 | demo 对应内容 |
| --- | --- |
| `BusinessModule/BrokerSDK-Quotes/BrokerQuotes/Classes/Layers/Business/StockDetail/Views/PortraitDrawViews/CStockDetailLineGroupView.m` | 32pt 周期栏、12pt 绘图区边距、分时右侧 130pt 成交栏与 12pt 间距 |
| `…/Models/ConverterModel/CSGKlinesDataConverter.m`、`…/Models/Render/CSGContext.m` | K 线窗口、坐标映射、蜡烛与均线、刻度与参考线 |
| `…/Views/TrendView/Minute/YYMinuteViewModel.swift`、`…/Views/TrendView/YYTrendLogic.swift` | 分时、五日、均价、右侧涨跌幅与分时指标 |
| `…/Processor/YYDetailTrendViewProcessor.swift`、`…/Views/DetailsInfosView/YYDetailTrendIndicatorView.swift` | 44pt 指标快捷栏、主副图多选 |
| `…/Basic/ReOrientLib/YYIndicatorsLib/YFIndicators.swift` | MA、EMA、BOLL、MACD、KDJ、RSI 公式与精度规则 |
| `…/Assets/Bundle/QuotesLocalization.bundle` | 简中源键及繁中、英文文案 |
| `…/Assets/Bundle/QuotesLightImages.bundle`、`QuotesDarkImages.bundle` | 设置及图例展开/收起图标，2x/3x、Light/Dark |
| `YFFinancial/Common/Theme/config/CommonColorConfig.plist`、`YSAColor.swift` | 正式主工程配色及涨跌色语义 |

`…` 为 `BusinessModule/BrokerSDK-Quotes/BrokerQuotes/Classes/Layers/Business/StockDetail`；指标公式路径中的 Basic 位于 `BrokerQuotes/Classes/Basic`。

## 已接入能力

- 单日分时、五日、日/周/月 K、1/5/15/30/60 分钟 K；默认最近 60 根，拖动历史、惯性、以双指中心缩放。
- 长按十字线与当前点数据，松手延迟消失；图例展开/收起；双击展开视图。
- MA/EMA/BOLL 主图多选，VOL/MACD/KDJ/RSI 副图多选，与底部快捷栏共用状态。
- 分时逐笔成交栏展示最新记录，五日和 K 线隐藏；内嵌预览的纵向手势交给页面，逐笔明细入口打开可独立滚动的完整列表。
- 简体、繁体、英文；浅色、深色；所有涨跌相关价格、蜡烛、成交量和逐笔方向颜色使用全局涨跌色，独立指标线配色保持固定。
- 普通详情、Scroll 卡片和股票下单页共用 `StockChartPanel`。下单页保留原来的弹簧展开/收起与 opacity/scale 转场；双击清空标的限于摘要区域，图表双击交由图表处理。
- Scroll 的窗口级翻页手势在当前卡的图表区域按方向分工：纵向翻股，横向操作图表；底部悬浮股票栏保留优先交互。图表设置、明细及全屏弹层打开时暂停底层翻页。独立下单页面也观察并注入全局涨跌色设置。

## 数据与边界

所有股票共用一套以 AAPL 公开历史走势为参照的合成行情，不连接行情接口；价格、成交量及每根 OHLC 均为模拟值，不是历史真实逐根报价。日线覆盖 2019-12-02 至 2026-11-05，共 1,742 个交易日；最近 30 个交易日提供合成分钟数据，周/月及较长分钟 K 从模拟数据聚合。模拟日历处理纽约时区、美股休市及半日市；盘前盘后和实时推送不在范围内。逐笔和订单为模拟记录，成交额按价量估算。

大致价格区间参考 [Yahoo Finance AAPL 历史价格](https://finance.yahoo.com/quote/AAPL/history/) 和 [Apple 投资者关系股价页面](https://investor.apple.com/stock-price/)，29 个粗略季度级锚点及生成的每根行情均为近似模拟。日历只覆盖固定样本范围内的常规美股休市及已核对的特别休市，不是通用交易所日历；最近 30 个分钟数据日均为完整交易日，生成器支持但样本本身未包含半日市。

指标在完整历史上计算，再按可视区取样；同周期 mock 指标缓存共用，非 mock 数据独立计算。模拟图表数据不改各股票原有报价卡数据。

这次迁入的是正式规则的独立实现，并非完整链接正式行情 SDK。未以正式 App 同一组行情截图进行逐像素比对；不将源码对照或 demo 测试表述为正式 App 像素等同验证。

## 图表设置和分时 mock 补充（2026-11-06）

- 重新核对远端 `UI重构/developer_LiquidGlass` 的 `667d285e395919c7cbc84fc6d440766f71425c6b`：自上述参考提交以来，分时、五日及图表设置绘制逻辑未改变。交易服务拆分及真实持仓空状态变化不接入 demo。
- 设置入口包括横屏、指标设置、图表标注和日/周/月复权；指标栏可见性与绘图选中状态分离。指标参数、可见项、选中项、复权和标注开关在本地共享保存，分时和 K 线副图设置分开。
- MA、EMA、BOLL、MACD、KDJ、RSI 参数参与实际计算。RSI 周期为 1 时，本实现避免正式实现将下一根价格变化写回上一根的前视行为。
- 买卖点、持仓成本及到价提醒为固定模拟标注，不读取真实账户；财报与分红使用 AAPL 公开披露的事件及数据。复权仅处理 AAPL 2020-08-31 的 4:1 拆股，从日线调整后聚合周/月；不包含分红复权或再投资，不等同于服务端完整复权数据。
- 正式美股分时为 390 个一分钟点，五日为 1,950 点；模拟价格采用固定种子逐分钟波动，成交量有开收盘活动、随机变化及偶发放量。分时/五日成交量不画 K 线的量均线，按正式实现分别使用 1pt 和单点间距宽度。
- 按正式分时布局，分时和五日主图顶部不显示常驻的价格、均价图例，也不预留图例高度；长按时仍在选中点的信息浮层中显示价格和均价。
- 周期栏按 [Time frame tabbar 设计](https://www.figma.com/design/sSOb11JOfSPoLLKQmRshYu/YFF-%E5%85%A8%E4%B8%9A%E5%8A%A1-UI-%E9%9C%80%E6%B1%82%E7%A8%BF?node-id=2704-239202) 使用文字同宽的选中线和正式分钟选项图标。报价详情收起时不为隐藏内容额外保留间距；关联信息保持顶部 8pt、行间 2pt、底部 16pt。
- 图表仅对自身横向平移做方向过滤；详情和下单页可从画布纵向滚动。Scroll 模式从图表纵向翻股，横向拖动和双指缩放仍由图表处理。
- 美股常规交易时间参考 [NYSE 交易时间](https://www.nyse.com/trade/trading-information)；分钟量能的开收盘活跃模式参考 [日内成交量研究](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0165057)。
- 本次验证：数据与指标脚本通过；模拟器构建及运行通过；五项既有明细、涨跌色/语言、下单、手势及弹层回归通过（`/tmp/stock-chart-settings-regression.xcresult`）。三项设置可见性/参数与复权标注/跨页面及重启保存测试通过（`/tmp/superpreview-chart-ui-agent-final.xcresult`）；最终渲染版参数和现价线的像素差测试通过（`/tmp/superpreview-chart-ui-pixels.xcresult`）。这些结果为分批运行，并非全部矩阵一次全量执行。

## 图表标记与标注线对照（2026-11-06）

- 对照 [Figma 主图节点](https://www.figma.com/design/sSOb11JOfSPoLLKQmRshYu/YFF-%E5%85%A8%E4%B8%9A%E5%8A%A1-UI-%E9%9C%80%E6%B1%82%E7%A8%BF?node-id=2786-3909)及正式分支 `667d285e`：现价为蓝色虚线；成本、涨提醒和跌提醒分别使用橙色、粉色、青色虚线及正式 12pt 标记素材。正式源码未发现独立委托限价线。
- 日、周、月线按周期归并 AAPL 的业绩和分红，使用正式 12pt 图片；点按打开该周期的事件详情，重合时可切换业绩及分红。公开资料未提供正式接口的财报打点色值，灰色是未知值的展示回退，不代表实际持平；若将来提供可靠涨跌状态，图标支持跟随全局涨跌色切换。币种切换不造汇率，未提供的数据展示 `--`。
- 财报和分红数据分别参考 Apple 的[季度业绩公告](https://www.apple.com/newsroom/2026/11/apple-reports-fourth-quarter-results/)及[分红历史](https://investor.apple.com/dividend-history/)；除息日由 [AAPL 分红历史](https://www.slickcharts.com/symbol/AAPL/dividend)核对。已宣布但晚于模拟行情截止日期的事件不提前画入历史 K 线。
- B/S/T 标记使用正式 10×13pt 素材；买卖颜色跟随全局涨跌色。长按对应行情点可查看模拟成交信息和模拟订单，不读取或操作真实账户。

## 验证入口

- `Scripts/test-stock-chart-data.sh`：独立 Swift 数据/指标测试，包括 OHLC 完整性、交易时段、聚合、已知指标样本、精度边界与缓存隔离。
- `Scripts/test-stock-chart.sh`：先运行数据测试，再运行 iPhone 17 Pro / Pro Max、Light / Dark 矩阵。可用 `DEVICE_NAMES`、`APPEARANCES`、`FILTER`、`RESULTS_DIR` 限定运行范围。
- `StockDetailChartUITests` 已加入现有 `SuperPreviewUITests` target，因此现有 `Scripts/test-layout-adaptation.sh` 也包含图表回归；该入口同时先运行数据/指标测试。

## 图表区域原生滚动修复（2026-11-06）

- 原来的 `shouldBeRequiredToFailBy` 让祖先页面的 pan 等待图表 pan、pinch 和 long press 失败。之前的长距离滑动测试未覆盖这个问题：新增测试中，相同的 44pt 慢速短滑在页面留白处移动约 34pt，在原分时画布上移动 0pt（`/tmp/chart-natural-scroll-baseline.xcresult`）。
- 去掉图表连续手势与祖先 pan 之间的失败等待；纵向位移、起滑阈值、回弹和惯性仍全部由页面自身的原生滚动处理。仅保留必要的点击优先级和系统边缘返回优先级。分时、五日不支持横向移动或缩放，直接禁用对应识别器。
- 内嵌成交预览禁用用户独立滚动，仍按程序定位到最新记录；完整明细弹层保留独立滚动，避免同一图表区域出现两种纵向行为。
- 新增自动回归：详情页（分时、五日、日 K）与下单页（分时、日 K）对比普通留白与画布的 44pt 短滑、双向斜滑和反向滑动；验证画布不误平移或触发十字线、快速滑动松手后继续减速、成交预览与完整明细的滚动分工。既有测试继续覆盖横拖、双指缩放、长按、浏览翻股和弹层。
- iPhone 17 Pro 模拟器 4 项通过（`/tmp/chart-natural-scroll-fix-v1.xcresult`）；Pro Max 模拟器 7 项通过（`/tmp/chart-natural-scroll-regression.xcresult`）。后者详情页三种周期的普通区域与画布均移动约 33.67pt，下单页两种周期均移动 34pt，直滑及双向斜滑一致。
- iPhone 17 Pro 真机（iOS 27.2）5 项全部通过（`/tmp/chart-natural-scroll-device-final.xcresult`）：详情／下单短滑对照、松手惯性、横拖／缩放／长按、内嵌与完整成交明细。真机详情三种周期、下单两种周期的直滑和双向斜滑均与普通区域同为 34pt，反向同为 -34pt。上述为交互回归，未做帧率基准测试。

## 本次验证结果（2026-11-06）

- iOS Simulator 构建通过；数据/指标脚本通过；三个测试入口的 shell 语法检查及 `git diff --check` 通过。
- 11 个图表用例覆盖 iPhone 17 Pro（402pt）与 Pro Max（440pt）的浅色、深色：周期聚合、历史平移、双指缩放、长按、图例折叠、多指标、逐笔明细、三语言、涨跌色像素交换、下单展开收起、Scroll 手势及弹层隔离。
- 原有 6 个下单/Scroll 用例通过：快速切股保持展开状态与吸顶头部、单股票 Scroll 退出、点击卡片退出、翻股上下文、连续横滑跟手、短距离横滑提交。
- 追加公司事件详情与合并标签、买卖点图标与颜色反转、模拟订单、分时和五日无常驻价格图例及长按信息的 UI 回归；AAPL 合成数据另覆盖交易日、跨周期聚合及拆股。
- 录屏检查下单展开过程，原有弹簧布局、渐显与缩放转场保留。本机片段：`/tmp/stock-chart-order-expansion.mp4`。

本机测试结果包如下（不纳入 Git）：

| 环境 | 通过证据 |
| --- | --- |
| 402pt 浅色 | `/tmp/stock-chart-pro-light-final.xcresult`（8 项）；`/tmp/stock-chart-scroll-regression.xcresult`（2 个新增图表用例 + 6 个既有回归）；`/tmp/stock-chart-pro-light-modal.xcresult`（1 项） |
| 402pt 深色 | `/tmp/stock-chart-pro-dark-final.xcresult`（11 项全套通过） |
| 440pt 浅色 | `/tmp/stock-chart-promax-light.xcresult` 的 6 项通过；`/tmp/stock-chart-promax-light-final.xcresult` 的 4 项通过；`/tmp/stock-chart-promax-light-symbol-fix.xcresult`（1 项） |
| 440pt 深色 | `/tmp/stock-chart-promax-dark.xcresult` 的 9 项通过；`/tmp/stock-chart-promax-dark-final.xcresult`（2 项）；`/tmp/stock-chart-promax-dark-plot.xcresult`（末次主图留白调整后的指标折叠及平移/缩放/长按 2 项复测） |

矩阵使用全套运行与定向补跑累计验收，并非最终构建一次性跑完全部组合；历史结果包仍保留修复前的失败记录。悬浮栏测试最后明确启用第二副图，保证两种屏幕高度均实际覆盖图表后再检验手势；末次主图内部留白按正式 `kLineMarginTop` 修正为有指标 20pt、无指标 0pt，相关用例已复测。
