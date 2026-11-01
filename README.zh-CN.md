<p align="center"><img src="Resources/AppIcon-1024.png" width="160" alt="抱着白色键盘的水獭助手"></p>

# 水獭助手 · OtterMate

**切换应用，输入法跟着切换。**

一个轻量的原生 macOS 菜单栏工具，为每个应用记住指定输入法：终端用 ABC，聊天用中文，其他应用使用你设定的输入源。

[English](README.md) · [下载安装包](https://github.com/Vtous/OtterMate/releases/latest) · [隐私说明](docs/PRIVACY.md) · [源码构建](docs/BUILDING.md)

> **v1.0.0：**安装包适用于 Apple Silicon（arm64），构建最低目标为 macOS 14。目前仅在一台运行 macOS 27.2 的 Apple Silicon Mac 上实测，其他系统和机型尚未验证。当前采用 **ad-hoc 本机签名，没有 Apple Developer ID 签名或苹果公证**，首次打开可能被系统阻止。你也可以审阅源码后自行构建。应用界面目前为中文，文档提供中英文版本。

## 功能

- 为不同应用指定已经在 macOS 中启用的输入法。
- 为没有单独规则的应用设置统一默认输入法。
- 关闭某条规则，让该应用保持当前输入法，也不应用默认值。
- 在菜单栏一键暂停或恢复自动切换。
- 搜索规则、批量添加应用、导入和导出 JSON 规则备份。
- 通过苹果 SMAppService 按需开启登录启动。
- 水獭头像菜单栏图标，自动适应深色和浅色外观。

每次进入应用时执行选择，必要时有限重试；激活处理结束后，你仍可手动切换输入法，不会被持续强制改回。

## 安装与使用

1. 从 [Releases](https://github.com/Vtous/OtterMate/releases/latest) 下载 `OtterMate-macOS-arm64.zip`。
2. 使用 Finder 解压，将 **水獭助手.app** 放入“应用程序”文件夹后打开。
3. 如果系统阻止打开，请先了解上方的签名状态，再参考[苹果关于打开可信应用的说明](https://support.apple.com/zh-cn/102445)。请勿全局关闭 Gatekeeper。
4. 在设置中添加应用，选择已启用的输入法。
5. 切到其他应用，再切回来，检查输入法是否随规则改变。

关闭设置窗口后，程序继续在菜单栏运行。点击水獭图标可以打开设置、暂停或退出。登录启动默认关闭，可自行开启。

如果系统也在恢复文稿的输入源，两套行为可能互相影响。可以在“键盘 → 文本输入 → 编辑”中关闭“自动切换到文稿的输入源”。

### 配合语音输入法

可为应用指定豆包等已经安装的语音输入法，然后使用该输入法自己的语音快捷键开始录音。水獭助手只负责选择输入法，不会自动录音，不改变其他软件的权限，也不改变它们向服务商传输数据的行为。本项目与输入法厂商无隶属关系。

## 隐私与权限

当前版本没有网络通信代码、统计 SDK、账号、广告或自动更新器。不采集键盘输入内容、剪贴板、屏幕或音频，不申请辅助功能、输入监控、麦克风、屏幕录制或完全磁盘访问权限。

程序通过系统 API 接收应用激活和输入源变化通知，规则保存在本机。详情见[中英文隐私说明](docs/PRIVACY.md)。这些说明基于当前源码和实现，项目尚未接受独立安全审计。

## 自行构建

需要 Apple Silicon Mac，以及包含较新 Swift 编译器的苹果 Command Line Tools。无第三方依赖。

```sh
zsh scripts/test.sh
zsh scripts/build.sh
```

构建产物为 `dist/OtterMate-macOS-arm64.zip` 和 `dist/SHA256SUMS`。详情见[构建文档](docs/BUILDING.md)及[验证范围](docs/TESTING.md)。

## 使用边界

按应用匹配，不区分同一应用内的网站、文稿或输入框。密码框、安全输入、远程桌面和自行管理输入源的应用可能覆盖或拒绝切换。指定输入法未启用时会提示，不会擅自安装或启用它。此版本不提供 Intel 安装包。

为兼容早期本地版本，内部 bundle identifier 和 `AppInputSwitcher` 配置目录继续保留，产品名称统一为 **水獭助手 / OtterMate**。

## 许可证与反馈

采用 [MIT 许可证](LICENSE)。欢迎在 [Issues](https://github.com/Vtous/OtterMate/issues) 提交可复现的问题和兼容性反馈；分享诊断信息前，请去掉个人应用路径和规则内容。
