# TestFlight 命令行发布

脚本面向 App Store Connect 的 QuoteDemo（`com.yff.YFQuotesDemo`），上传到现有自动分发的内部测试组；不会将构建分发给外部测试组。需安装 Xcode、登录有权限的开发团队并启用自动签名。

## 一次性准备

在 App Store Connect「用户与访问 > 集成 > App Store Connect API」创建有权访问此 App、构建和内部测试组的团队 API 密钥，下载 `.p8` 私钥并妥善保存，记录 Key ID 和 Issuer ID。密钥权限不足时请由账户管理员配置。不要把私钥提交到 Git 或粘贴到聊天中。Apple 的说明：[创建 API 密钥](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)。

将 `.p8` 保存到安全的本地目录，创建 `~/.config/superpreview/testflight.json`（示例值替换成实际值；文件不包含私钥内容）：

```json
{"key_id":"YOUR_KEY_ID","issuer_id":"YOUR_ISSUER_ID","key_path":"~/.appstoreconnect/private_keys/AuthKey_YOUR_KEY_ID.p8"}
```

随后运行 `python3 Scripts/testflight.py --check`。也可以使用环境变量临时覆盖配置：

```sh
export ASC_KEY_ID='YOUR_KEY_ID'
export ASC_ISSUER_ID='YOUR_ISSUER_ID'
export ASC_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_YOUR_KEY_ID.p8"
python3 Scripts/testflight.py --check
```

`--check` 只读取 App、测试组和构建列表，以验证 API 凭据及相关读取权限，不会上传。签名和上传依赖 Xcode 登录及自动签名权限；API 密钥用于查询和校验结果。

## 发布

```sh
python3 Scripts/testflight.py
```

脚本生成以当前 Unix 时间秒数为构建号的构建，归档并上传，随后等待 Apple 处理，并且只有当构建状态为内部测试中且已加入指定内部测试组时才报告成功。生成的构建号不会写回 Git。运行时会在系统临时目录保留归档和导出文件；发生冲突或 Apple 异步处理失败时须检查 App Store Connect，不要盲目重试。默认最多等待 20 分钟，可用 `--timeout 1800` 调整。

仅查询已经上传的构建（不会重传）：

```sh
python3 Scripts/testflight.py --status 1.0 11
```

如果项目或依赖加入了非豁免加密算法，必须重新检查 `ITSAppUsesNonExemptEncryption` 和出口合规声明，不能继续沿用当前值。自动分发依赖 App Store Connect 中内部测试组的设置；脚本不修改测试组权限，也不提交外部测试审核。
