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
- 分时逐笔成交栏，五日和 K 线隐藏；逐笔明细入口可打开列表。
- 简体、繁体、英文；浅色、深色；所有涨跌相关价格、蜡烛、成交量和逐笔方向颜色使用全局涨跌色，独立指标线配色保持固定。
- 普通详情、Scroll 卡片和股票下单页共用 `StockChartPanel`。下单页保留原来的弹簧展开/收起与 opacity/scale 转场；双击清空标的限于摘要区域，图表双击交由图表处理。
- Scroll 的窗口级翻页手势只排除当前卡的图表区域，底部悬浮股票栏保留优先交互；图表设置、明细及全屏弹层打开时暂停底层翻页。独立下单页面也观察并注入全局涨跌色设置。

## 数据与边界

所有股票共用固定模拟行情，不连接行情接口。包含 1,300 个工作日日线和 30 个完整常规交易时段的分钟数据；周/月与分钟 K 通过真实聚合计算。交易时间按纽约时区处理；不模拟交易所节假日、半日交易、盘前盘后、实时推送与公司行动。逐笔为同组分时行情生成的固定演示记录，成交额按价量估算。

指标在完整历史上计算，再按可视区取样；同周期 mock 指标缓存共用，非 mock 数据独立计算。模拟图表数据不改各股票原有报价卡数据。

这次迁入的是正式规则的独立实现，并非完整链接正式行情 SDK。未以正式 App 同一组行情截图进行逐像素比对；不将源码对照或 demo 测试表述为正式 App 像素等同验证。

## 验证入口

- `Scripts/test-stock-chart-data.sh`：独立 Swift 数据/指标测试，包括 OHLC 完整性、交易时段、聚合、已知指标样本、精度边界与缓存隔离。
- `Scripts/test-stock-chart.sh`：先运行数据测试，再运行 iPhone 17 Pro / Pro Max、Light / Dark 矩阵。可用 `DEVICE_NAMES`、`APPEARANCES`、`FILTER`、`RESULTS_DIR` 限定运行范围。
- `StockDetailChartUITests` 的 11 个用例已加入现有 `SuperPreviewUITests` target，因此现有 `Scripts/test-layout-adaptation.sh` 也包含图表回归；该入口同时先运行数据/指标测试。

## 本次验证结果（2026-11-06）

- iOS Simulator 构建通过；数据/指标脚本通过；三个测试入口的 shell 语法检查及 `git diff --check` 通过。
- 11 个图表用例覆盖 iPhone 17 Pro（402pt）与 Pro Max（440pt）的浅色、深色：周期聚合、历史平移、双指缩放、长按、图例折叠、多指标、逐笔明细、三语言、涨跌色像素交换、下单展开收起、Scroll 手势及弹层隔离。
- 原有 6 个下单/Scroll 用例通过：快速切股保持展开状态与吸顶头部、单股票 Scroll 退出、点击卡片退出、翻股上下文、连续横滑跟手、短距离横滑提交。
- 录屏检查下单展开过程，原有弹簧布局、渐显与缩放转场保留。本机片段：`/tmp/stock-chart-order-expansion.mp4`。

本机测试结果包如下（不纳入 Git）：

| 环境 | 通过证据 |
| --- | --- |
| 402pt 浅色 | `/tmp/stock-chart-pro-light-final.xcresult`（8 项）；`/tmp/stock-chart-scroll-regression.xcresult`（2 个新增图表用例 + 6 个既有回归）；`/tmp/stock-chart-pro-light-modal.xcresult`（1 项） |
| 402pt 深色 | `/tmp/stock-chart-pro-dark-final.xcresult`（11 项全套通过） |
| 440pt 浅色 | `/tmp/stock-chart-promax-light.xcresult` 的 6 项通过；`/tmp/stock-chart-promax-light-final.xcresult` 的 4 项通过；`/tmp/stock-chart-promax-light-symbol-fix.xcresult`（1 项） |
| 440pt 深色 | `/tmp/stock-chart-promax-dark.xcresult` 的 9 项通过；`/tmp/stock-chart-promax-dark-final.xcresult`（2 项）；`/tmp/stock-chart-promax-dark-plot.xcresult`（末次主图留白调整后的指标折叠及平移/缩放/长按 2 项复测） |

矩阵使用全套运行与定向补跑累计验收，并非最终构建一次性跑完全部组合；历史结果包仍保留修复前的失败记录。悬浮栏测试最后明确启用第二副图，保证两种屏幕高度均实际覆盖图表后再检验手势；末次主图内部留白按正式 `kLineMarginTop` 修正为有指标 20pt、无指标 0pt，相关用例已复测。
