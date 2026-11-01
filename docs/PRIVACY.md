# Privacy / 隐私说明

Applies to OtterMate 1.0.0. This describes the implementation, not an independent audit or a guarantee about other software.

## English

OtterMate has no networking, telemetry, advertising, account system, or automatic updater. It does not capture keystrokes, typed text, clipboard data, screenshots, or audio. It requests no Accessibility, Input Monitoring, microphone, Screen Recording, or Full Disk Access permissions.

It uses `NSWorkspace` application-activation notifications to identify the active app and Carbon Text Input Services to list and select enabled input sources. The interface may show the most recently activated app and the last switch result in memory; it does not persist an app-usage history.

Your rules are stored in `~/Library/Application Support/AppInputSwitcher/rules.json`. They include app bundle identifiers, display names, app paths, selected input-source identifiers, enabled states, and the optional default input source. The file is written atomically with mode `0600`; this is a file permission, not encryption. Importing rules creates a local backup before replacement. Exported rules and backups may disclose installed-app names or user-directory paths: review them before sharing.

Login startup uses Apple's `SMAppService` and is off by default. Disable it in settings before uninstalling if enabled. Quit the app and remove its configuration directory to clear saved rules and backups. Deleting the app alone does not remove these files.

Another input method may have its own cloud processing, permissions, and privacy policy. OtterMate does not change or audit those behaviors. macOS and other installed software may independently access their own services.

## 简体中文

水獭助手没有网络通信、统计、广告、账号系统或自动更新器，不采集键盘输入、文字内容、剪贴板、屏幕或音频，不申请辅助功能、输入监控、麦克风、屏幕录制或完全磁盘访问权限。

程序通过 `NSWorkspace` 应用激活通知获取当前应用，通过 Carbon Text Input Services 列出及选择已经启用的输入源。界面会在内存中显示最近激活的应用和切换结果，不持久保存应用使用历史。

规则保存在 `~/Library/Application Support/AppInputSwitcher/rules.json`，包含应用标识、名称、路径、输入源标识、启用状态和可选默认输入源。配置采用原子写入，文件权限为 `0600`；文件权限不等于加密。导入规则前会创建本地备份。导出文件和备份可能包含已安装应用的名称和个人目录路径，分享前请自行检查。

登录启动通过苹果 `SMAppService` 实现，默认关闭。如已开启，卸载前请先在设置中关闭。退出程序并删除上述配置目录，可清除规则和备份；只删除应用不会清除这些文件。

其他输入法可能有各自的云端处理、权限及隐私政策，水獭助手不会改变或审计它们。macOS 和其他软件也可能独立连接各自的服务。
