<p align="center">
  <img src="Logo.png" width="128" height="128" alt="PhotoClean Icon">
</p>

<h1 align="center">PhotoClean</h1>

<p align="center">
  以滑動方式清理你的 iPhone 相簿 — 像 Tinder 一樣快速篩選照片。
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

- **滑動操作** — 左滑丟棄、右滑保留。支援照片與影片。
- **預覽列** — 畫面底部顯示接下來 6 張,點擊直接跳轉,長按快速預覽。
- **兩階段刪除** — 照片先進 app 內的垃圾桶,之後**一次性**批次送進 iOS「最近刪除」,只跳一次系統確認 dialog。
- **Undo** — 最近一次滑動隨時可以復原。
- **App 內播放影片** — 影片卡片上點播放按鈕,全螢幕 AVKit player。
- **Liquid Glass** — iOS 26 原生玻璃效果;iOS 17–25 自動 fallback 到 `.ultraThinMaterial`。
- **純 Dark Mode 設計** — 純黑襯底、極簡 UI,最適合看照片。
- **多語言** — 自動依裝置語言切換英文 / 繁體中文。
- **完全離線** — 無伺服器、無帳號、無任何追蹤。所有資料留在你的裝置上。

## 需求

- iOS 17.0 以上(iOS 26+ 才能看到完整 Liquid Glass)
- Xcode 16 以上(建議 Xcode 26+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## 建置

```bash
git clone https://github.com/Kazzx9921/PhotoClean.git
cd PhotoClean
xcodegen generate
open PhotoClean.xcodeproj
```

在 Xcode 裡:
1. 選 `PhotoClean` target → **Signing & Capabilities**
2. 勾選 *Automatically manage signing*,選你的 Team
3. 接上 iPhone,選為執行目標
4. 按 ⌘R

免費 Apple ID(Personal Team)的限制:app 每 7 天過期、同時只能裝 3 個。付費 Apple Developer($99 / 年)則無此限制。

## 專案架構

```
PhotoClean/
├─ App/                  @main 與 root 路由
├─ Core/                 PhotoLibraryService、TrashStore、UndoStack、Models、FormatHelper
├─ Features/
│  ├─ Home/              滑動主畫面 + view model + peek strip + 卡片 + 影片 player
│  ├─ Trash/             批次刪除 grid + commit 流程
│  ├─ Onboarding/        3 頁歡迎 + 權限請求
│  └─ Settings/          統計 + 關於 + GitHub 連結
├─ UI/                   Haptics、LiquidGlass(iOS 26 modifier)
├─ Resources/            Localizable.xcstrings(en + zh-Hant)
└─ Assets.xcassets/      AppIcon + AccentColor
```

## 設計決策

| 決策 | 原因 |
|---|---|
| 批次刪除而非每次滑即刪 | iOS 規定每次呼叫 `PHAssetChangeRequest.deleteAssets` 都會跳系統 dialog。每滑一張跳一次會中斷節奏,改成累積後一次批次 = 只跳一次。 |
| 不自建 asset index | `PHAsset.fetchAssets(withLocalIdentifiers:)` 用 Photos 內建索引做 O(1) 查詢,5 萬張照片省 ~5MB 記憶體。 |
| `PHPhotoLibraryChangeObserver` | 相簿變動由 iOS 主動推送,切 app 回前景不用強制 refetch。 |
| Thumbnail LRU 上限 50 | 與 peek strip 使用量一致,記憶體 footprint 可預期。 |
| 頂/底 bar 用 overlay 疊加 | Liquid Glass 要有內容在下層才會折射 — bar 浮在照片之上,玻璃才有生命力。 |

## Star History

<a href="https://www.star-history.com/#Kazzx9921/PhotoClean&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
 </picture>
</a>

## 授權

[PolyForm Noncommercial 1.0.0](LICENSE) — 可自由 clone、修改、編譯到自己裝置使用。**不可**轉賣、不可上架任何 app store。

商業授權請洽 <geekaz.net@gmail.com>。

## 使用技術

- Apple SwiftUI、Photos、AVKit、PhotosUI
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
