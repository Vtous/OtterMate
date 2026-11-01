# Validation scope / 验证范围

## English

Version 1.0.0 was checked on macOS 27.2 on Apple Silicon. This is not a compatibility matrix or an independent security audit.

- 22 automated core checks cover rule priority, disabled-rule exemptions, pause, missing input sources, persistence, backups, invalid imports, and corrupt configuration. Run `zsh scripts/test.sh`.
- Interactive checks covered two test applications with different input sources (ABC and an installed Chinese input method), switching between them, pause/resume, manual input-source changes after activation, and saved rules after restart.
- Login startup state and small/large app icons were checked in macOS settings and Finder.
- The archive is extracted into a fresh temporary directory and checked with `codesign --verify --strict` by the build script. This verifies signature integrity, not notarization or malware-free status.

The automated suite does not exercise system input switching or every UI state. Other macOS versions, Intel Macs, secure input fields, remote desktops, and all third-party input methods have not been comprehensively tested.

## 简体中文

1.0.0 在 Apple Silicon、macOS 27.2 上验证，不代表完整兼容性矩阵，也不等于独立安全审计。

核心自动测试共 22 项，覆盖规则优先级、停用规则的默认值豁免、暂停、缺失输入源、持久化、备份、无效导入和损坏配置。交互实测覆盖两个应用分别使用 ABC 和已安装中文输入法、应用来回切换、暂停与恢复、激活完成后手动切换，以及重启后规则保留。

另检查了登录启动状态及 Finder、系统设置中的大小图标。构建脚本会解包并用 `codesign --verify --strict` 验证完整性；这不能替代苹果公证或恶意软件检测。

核心自动测试不操作系统输入法，也不覆盖所有界面状态。其他系统版本、Intel、安全输入、远程桌面和全部第三方输入法尚未全面验证。
