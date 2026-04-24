<p align="center">
  <img src="Logo.png" width="128" height="128" alt="PhotoClean Icon">
</p>

<h1 align="center">PhotoClean</h1>

<p align="center">
  A swipe-to-clean photo library app for iOS. Tinder-style triage for your Camera Roll.
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

## Features

- **Swipe UI** — Swipe left to trash, right to keep. Works on photos and videos.
- **Peek strip** — See the next 6 photos at the bottom. Tap to jump, long-press to preview.
- **Two-step delete** — Photos go to an in-app trash first, then a single confirmation batches everything into iOS Recently Deleted. No more one-dialog-per-delete.
- **Undo** — The last swipe is always reversible.
- **Inline video playback** — Tap the play button on any video card for a full-screen AVKit player.
- **Liquid Glass** — Native iOS 26 glass effects, gracefully falling back to `.ultraThinMaterial` on iOS 17–25.
- **Dark-only by design** — Black letterbox, minimal chrome. Tuned for photo viewing.
- **Multi-language** — English and 繁體中文, auto-switching by device language.
- **100% offline** — No servers, no accounts, no telemetry. Every byte stays on your device.

## Requirements

- iOS 17.0+ (iOS 26+ for the full Liquid Glass effect)
- Xcode 16+ (Xcode 26+ recommended)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build

```bash
git clone https://github.com/Kazzx9921/PhotoClean.git
cd PhotoClean
xcodegen generate
open PhotoClean.xcodeproj
```

In Xcode:
1. Select the `PhotoClean` target → **Signing & Capabilities**
2. Enable *Automatically manage signing* and pick your Team
3. Connect your iPhone, select it as run destination
4. Press ⌘R

Using a free Apple ID (Personal Team)? Apps expire after 7 days and you can only sideload 3 at a time. A paid Apple Developer account ($99/year) removes these limits.

## Forking for your own release

If you want to ship your own build to the App Store (subject to the [license](#license)), you must change these so Xcode and App Store Connect don't collide with the original:

1. **Bundle identifier** — in `project.yml`, change `PRODUCT_BUNDLE_IDENTIFIER: com.geekaz.PhotoClean` to your own reverse-DNS ID, then run `xcodegen generate`.
2. **In-app purchase product ID** — in `PhotoClean/Features/Paywall/PaywallStore.swift`, change the `productID` constant. Register the matching non-consumable IAP in App Store Connect.
3. **Local StoreKit test config** — update `productID` inside `PhotoClean.storekit` to match, so the Xcode scheme's local sandbox still works.

Signing is already set to `Automatic`, so your own Apple Developer Team is picked up from Xcode — no change needed in the project file.

## Architecture

```
PhotoClean/
├─ App/                  @main + root routing
├─ Core/                 PhotoLibraryService, TrashStore, UndoStack, Models, FormatHelper
├─ Features/
│  ├─ Home/              Swipe view + view model + peek strip + card + video player
│  ├─ Trash/             Batch delete grid + commit flow
│  ├─ Onboarding/        3-page welcome + permission request
│  └─ Settings/          Stats + about + GitHub link
├─ UI/                   Haptics, LiquidGlass (iOS 26 modifier)
├─ Resources/            Localizable.xcstrings (en + zh-Hant)
└─ Assets.xcassets/      AppIcon + AccentColor
```

## Design notes

| Decision | Why |
|---|---|
| Batch delete, not per-swipe | iOS requires a system confirmation dialog for every `PHAssetChangeRequest.deleteAssets`. Per-swipe would interrupt the flow. One batch = one dialog. |
| No custom asset index | `PHAsset.fetchAssets(withLocalIdentifiers:)` gives us O(1) lookups via Photos' native index. Saves ~5 MB for a 50k-photo library. |
| `PHPhotoLibraryChangeObserver` | Library updates are pushed by iOS, so scene-phase transitions don't force a refetch. |
| Thumbnail LRU cap 50 | Matches peek-strip working set. Predictable memory footprint. |
| Overlay layout for top/bottom bars | Liquid Glass refracts visible content. Bars float above the photo so glass looks alive. |

## Star History

<a href="https://www.star-history.com/#Kazzx9921/PhotoClean&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
 </picture>
</a>

## License

[PolyForm Noncommercial 1.0.0](LICENSE) — free to clone, modify, and run on your own device. Not for resale or commercial redistribution (including app stores).

For commercial licensing, contact <geekaz.net@gmail.com>.

## Credits

- Apple SwiftUI, Photos, AVKit, PhotosUI
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
