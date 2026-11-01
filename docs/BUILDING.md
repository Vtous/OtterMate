# Building / 构建

## English

Use an Apple Silicon Mac with Apple's Command Line Tools and a recent Swift compiler. There are no third-party dependencies. The app uses AppKit, SwiftUI, Carbon Text Input Services, and ServiceManagement.

```sh
git clone https://github.com/Vtous/OtterMate.git
cd OtterMate
zsh scripts/test.sh
zsh scripts/build.sh
(cd dist && shasum -a 256 -c SHA256SUMS)
```

The script targets `arm64-apple-macos14.0`, stages the app in a temporary directory, ad-hoc signs it, verifies the signature, packages it, then extracts and verifies it again. Output: `dist/OtterMate-macOS-arm64.zip`. No Developer ID certificate, notarization credentials, or personal rules are required or bundled.

Unzip with Finder and move **水獭助手.app** into Applications. Alternatively, `zsh scripts/install.sh` installs into `~/Applications` and refuses to overwrite an existing copy. The optional `启动水獭助手.command` launcher opens the installed app's settings. Locally building is separate from Apple's notarization process.

`OtterMate --list-sources` lists enabled input-source identifiers without selecting one. For development only, set `APPINPUT_CONFIG_PATH` to a separate test JSON path to isolate saved rules. This does not isolate system-wide input-source changes when you actually run the app, so use a dedicated test session for interactive testing.

After changing `Resources/AppIcon-1024.png`, regenerate the ICNS with Apple's tools:

```sh
xcrun swift scripts/make-icon.swift Resources/AppIcon-1024.png Resources/AppIcon.icns
```

The icon script generates all ten standard/Retina representations, uses `iconutil`, and round-trip checks them. `Resources/MenuBarIcon.png` is an independent transparent monochrome template, displayed at 18 points.

## 简体中文

需要 Apple Silicon Mac、苹果 Command Line Tools 和较新 Swift 编译器，无第三方依赖。以上命令会运行核心测试、构建并校验 ZIP 校验和。

构建目标为 `arm64-apple-macos14.0`，安装包在独立临时目录生成，完成 ad-hoc 签名验证后打包，再解包复验。不会使用 Developer ID、公证凭据或个人规则。

推荐用 Finder 解压后，将“水獭助手.app”放进“应用程序”。也可用 `zsh scripts/install.sh` 安装到 `~/Applications`，脚本不会覆盖已有同名应用。`启动水獭助手.command` 用于打开已安装版本的设置。本机构建不等于苹果公证。

开发时可用 `APPINPUT_CONFIG_PATH` 指定独立配置文件；它只隔离配置，不隔离实际运行时对系统输入源的切换。交互验证请使用专门测试会话。核心测试使用临时目录，不修改日常规则，也不切换系统输入源。

修改主图后可运行上方图标命令，使用苹果官方工具生成完整多尺寸 ICNS 并解包验证。菜单栏使用独立透明模板图标。
