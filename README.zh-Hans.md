<p align="center">
  <img src="Logo.png" width="128" height="128" alt="PhotoClean Icon">
</p>

<h1 align="center">PhotoClean</h1>

<p align="center">
  以滑动方式清理你的 iPhone 相册 — 像 Tinder 一样快速筛选照片。
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.zh-Hant.md">繁體中文</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.es.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/liquid%20glass-iOS%2026-black" alt="Liquid Glass">
  <img src="https://img.shields.io/badge/license-PolyForm%20NC%201.0-green" alt="License">
</p>

## 功能

- **滑动操作** — 左滑丢弃、右滑保留。支持照片与视频。
- **预览列** — 画面底部显示接下来 6 张,点击直接跳转,长按快速预览。
- **两阶段删除** — 照片先进 app 内的回收站,之后**一次性**批量送进 iOS「最近删除」,只弹一次系统确认 dialog。
- **Undo** — 最近一次滑动随时可以撤回。
- **App 内播放视频** — 视频卡片上点播放按钮,全屏 AVKit player。
- **Liquid Glass** — iOS 26 原生玻璃效果;iOS 17–25 自动 fallback 到 `.ultraThinMaterial`。
- **纯 Dark Mode 设计** — 纯黑背景、极简 UI,最适合看照片。
- **多语言** — 自动依据设备语言切换,支持英文、繁中、简中、日文、西班牙文。
- **完全离线** — 无服务器、无账号、无任何追踪。所有数据留在你的设备上。

## 需求

- iOS 17.0 以上(iOS 26+ 才能看到完整 Liquid Glass)
- Xcode 16 以上(建议 Xcode 26+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## 构建

```bash
git clone https://github.com/Kazzx9921/PhotoClean.git
cd PhotoClean
xcodegen generate
open PhotoClean.xcodeproj
```

在 Xcode 里:
1. 选 `PhotoClean` target → **Signing & Capabilities**
2. 勾选 *Automatically manage signing*,选你的 Team
3. 接上 iPhone,选为执行目标
4. 按 ⌘R

免费 Apple ID(Personal Team)的限制:app 每 7 天过期、同时只能装 3 个。付费 Apple Developer($99 / 年)则无此限制。

## 项目架构

```
PhotoClean/
├─ App/                  @main 与 root 路由
├─ Core/                 PhotoLibraryService、TrashStore、UndoStack、Models、FormatHelper
├─ Features/
│  ├─ Home/              滑动主画面 + view model + peek strip + 卡片 + 视频 player
│  ├─ Trash/             批量删除 grid + commit 流程
│  ├─ Onboarding/        3 页欢迎 + 权限请求
│  └─ Settings/          统计 + 关于 + GitHub 链接
├─ UI/                   Haptics、LiquidGlass(iOS 26 modifier)
├─ Resources/            Localizable.xcstrings(5 种语言)
└─ Assets.xcassets/      AppIcon + AccentColor
```

## 设计决策

| 决策 | 原因 |
|---|---|
| 批量删除而非每次滑即删 | iOS 规定每次调用 `PHAssetChangeRequest.deleteAssets` 都会弹系统 dialog。每滑一张弹一次会打断节奏,改成累积后一次批量 = 只弹一次。 |
| 不自建 asset index | `PHAsset.fetchAssets(withLocalIdentifiers:)` 用 Photos 内建索引做 O(1) 查询,5 万张照片省约 5MB 内存。 |
| `PHPhotoLibraryChangeObserver` | 相册变动由 iOS 主动推送,切 app 回前台不用强制 refetch。 |
| Thumbnail LRU 上限 50 | 与 peek strip 使用量一致,内存 footprint 可预期。 |
| 顶/底 bar 用 overlay 叠加 | Liquid Glass 要有内容在下层才会折射 — bar 浮在照片之上,玻璃才有生命力。 |

## Star History

<a href="https://www.star-history.com/#Kazzx9921/PhotoClean&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
 </picture>
</a>

## 授权

[PolyForm Noncommercial 1.0.0](LICENSE) — 可自由 clone、修改、编译到自己设备使用。**不可**转售、不可上架任何 app store。

商业授权请联系 <geekaz.net@gmail.com>。

## 使用技术

- Apple SwiftUI、Photos、AVKit、PhotosUI
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
