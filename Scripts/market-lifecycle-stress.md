市场页真机前后台压力测试
======================

使用连接并解锁的开发者模式 iPhone。测试期间请让手机用于测试，避免手动切换应用。
先在手机的“设置 → 开发者 → Hang Detection”开启 SuperPreview 的卡死检测。
测试覆盖 Home 键退后台与前台恢复，不包含自动锁屏或解锁。

在另一台 Mac 上运行：

1. 拉取本仓库最新代码，安装 Xcode 27（或支持手机当前 iOS 的版本）及 Python 3。
2. 在 Xcode 的 Settings → Accounts 登录有本项目签名权限的 Apple ID；若没有当前团队权限，
   在 App 和 SuperPreviewUITests 两个 target 的 Signing & Capabilities 中选择可用团队。
3. 确认 `xcode-select -p` 指向完整 Xcode 的 Developer 目录，而非 CommandLineTools。
4. 连接手机、解锁并信任这台 Mac，用 `xcrun devicectl list devices` 查看设备标识。
5. 在仓库根目录运行下方命令，替换 `YOUR_DEVICE_UDID`。另一台 Mac 首次运行不要加 `--skip-build`；
   脚本会重新构建测试产品，日志和结果保存在执行测试的那台 Mac 上。

短验证：

```sh
python3 Scripts/test-market-lifecycle.py --device YOUR_DEVICE_UDID --cycles 3 --background-durations 1,3
```

长测试（默认 Release，同一 App 会话内循环）：

```sh
python3 Scripts/test-market-lifecycle.py --device YOUR_DEVICE_UDID --cycles 100 --background-durations 0.5,2,10,30
```

未启用诊断的对照包：

```sh
python3 Scripts/test-market-lifecycle.py --device YOUR_DEVICE_UDID --cycles 100 --no-diagnostics
```

初次构建后可用 `--skip-build` 复用同一 configuration 的测试产品；源码变化后必须重新构建。
`--configuration Debug` 可测试原 Debug 配置，默认 Release 对照真实运行性能。
诊断仅通过 `-MarketLifecycleDiagnostics` 参数启用，不启用一般的 `-UITesting` 代码路径。
不执行失败重试，异常后停止循环；可在终端按 Ctrl-C 停止整个测试。

默认输出在 `~/Library/Logs/SuperPreview/MarketLifecycle/`，每次使用独立目录。
保存 status.json、源码版本/差异、build.log、test.log、进程时间线、周期性 App 日志快照、
新生成的 SuperPreview/Jetsam 系统报告及 stress.xcresult。
同时保留 App dSYM 与 UUID，自动生成 analysis.json / analysis.txt，汇总 watchdog、
其他 App 终止、Jetsam、GPU 错误与主线程心跳延迟；汇总不等于确认根因。
App 的每个诊断会话最多保留两份 4 MiB 日志；主线程阶段耗时每秒采样一次。
GPU 调度/完成状态、错误和独立主线程心跳用于判断渲染停止的位置。
开启 enhanced GPU 错误和诊断会增加少量开销，必须保留未启用诊断的对照结果。

返回前台前检查 App 状态，避免 activate() 静默重启已经退出的 App。
测试自身检测到异常后等待 30 秒，给系统生成 watchdog 报告的机会；随后 XCTest
仍可能清理被测 App，故仅有进程消失不能证明系统崩溃，必须与 .ips、失败原因和时序对应。
XCTest 自身超时/连接失败同样会留下 xcresult，不应被误判为目标 App 崩溃。
若卡死发生在不可返回的 XCTest API 内，测试用例中的异常处理不一定会执行，
依靠独立 Mac 进程监测、周期性日志快照和 XCTest 自动诊断补充证据。
系统报告生成有延迟，失败后会再等待并采集约 30 秒；未生成报告时仍保存现有证据。

分析时先找 `failure-candidate` 的周期和操作，以及 .ips 的 termination 字段。
`0x8BADF00D` 表示 watchdog；Jetsam 必须确认被杀进程确实是 SuperPreview。
主线程心跳正常但 frame-begin 停止：检查 DisplayLink/lifecycle/页面激活状态。
frame-begin 后缺失 frame-draw-returned：结合 Thread State Trace 查绘制路径阻塞。
submitted 持续增加但 scheduled/completed 停止：检查 GPU 调度/执行和资源状态。
测试通过只表示本轮未捕捉到异常，不证明偶发问题已修复。
