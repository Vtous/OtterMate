<p align="center"><img src="Resources/AppIcon-1024.png" width="160" alt="OtterMate: an otter holding a keyboard"></p>

# OtterMate · 水獭助手

**Your apps. Your input sources. Automatically.**

A small native macOS menu bar app that switches input sources when you enter an app. Keep ABC in your terminal, Chinese input in your messenger, and your preferred input method everywhere else.

[简体中文](README.zh-CN.md) · [Download](https://github.com/Vtous/OtterMate/releases/latest) · [Privacy](docs/PRIVACY.md) · [Build from source](docs/BUILDING.md)

> **v1.0.0:** Apple Silicon (arm64), deployment target macOS 14+. Tested on macOS 27.2 on one Apple Silicon Mac; other versions and machines have not yet been verified. The download is **ad-hoc signed, without Apple Developer ID signing or notarization**. macOS may block its first launch. Review the source or build locally if you prefer. The app interface is currently in Chinese; documentation is available in English and Chinese.

## What it does

- Assign an enabled macOS input source to each app.
- Optionally choose a default input source for apps without a rule.
- Exempt an app from the default by disabling its rule.
- Pause and resume from the menu bar.
- Search rules, add multiple apps, and import or export JSON backups.
- Optionally launch at login using Apple's SMAppService.
- Use a simple otter menu bar icon that adapts to light and dark appearances.

It selects an input source on app activation, with a bounded retry when needed. It does not continuously force the input source: after activation settles, you can switch manually and keep typing.

## Install and use

1. Download `OtterMate-macOS-arm64.zip` from [Releases](https://github.com/Vtous/OtterMate/releases/latest).
2. Unzip it with Finder and move **水獭助手.app** to Applications before opening it.
3. If macOS blocks the app, review the signing notice above and [Apple's instructions for opening trusted apps](https://support.apple.com/en-us/102445). Do not disable Gatekeeper globally.
4. Add an app in settings and choose an input source already enabled in macOS Keyboard settings.
5. Switch away from that app, then return to try the rule.

Closing settings keeps OtterMate in the menu bar. Use the menu bar icon to reopen settings, pause switching, or quit. Login startup is optional and off by default.

If macOS also restores input sources per document, the two behaviors may compete. Consider turning off **Automatically switch to a document's input source** in Keyboard → Text Input → Edit.

### Using a voice input method

You can assign Doubao or another installed voice input method to an app. OtterMate selects that input method; you still use its own voice shortcut to start recording. OtterMate does not record audio, alter another app's permissions, or change whether that input method sends data to its provider. It is an independent utility, not affiliated with an input-method vendor.

## Privacy by implementation

This version contains no networking code, analytics, accounts, advertising, or automatic updater. It does not capture keystrokes, clipboard contents, screen contents, or audio, and does not request Accessibility, Input Monitoring, microphone, Screen Recording, or Full Disk Access permissions.

It observes app activation and input-source changes through macOS APIs. Rules remain on your Mac. See the bilingual [privacy document](docs/PRIVACY.md) for the data stored locally and the scope of these claims. No independent security audit has been performed.

## Build

Requires an Apple Silicon Mac and Apple's Command Line Tools with a recent Swift compiler. No third-party dependencies or package manager are required.

```sh
zsh scripts/test.sh
zsh scripts/build.sh
```

The build script produces `dist/OtterMate-macOS-arm64.zip` and `dist/SHA256SUMS`. See [build instructions](docs/BUILDING.md) and [validation scope](docs/TESTING.md).

## Limits

Rules apply per application, not per website, document, or input field. Password fields, secure input, remote desktops, and apps that manage input sources themselves may override or reject a selection. Missing or disabled input sources are reported without installing or enabling them. Intel downloads are not provided in this release.

The internal bundle identifier and `AppInputSwitcher` configuration directory remain unchanged for compatibility with earlier local builds. The product name is **OtterMate / 水獭助手**.

## License and feedback

[MIT License](LICENSE). Bug reports and reproducible compatibility reports are welcome in [Issues](https://github.com/Vtous/OtterMate/issues). Please remove personal application paths and rules before sharing diagnostics.
