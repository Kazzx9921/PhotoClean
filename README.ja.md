<p align="center">
  <img src="Logo.png" width="128" height="128" alt="PhotoClean Icon">
</p>

<h1 align="center">PhotoClean</h1>

<p align="center">
  スワイプ操作で iPhone のカメラロールを整理する iOS アプリ。Tinder 風 UI で素早く写真を振り分けられます。
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

## 特徴

- **スワイプ操作** — 左にスワイプで削除、右で保持。写真も動画も対応。
- **プレビュー帯** — 画面下部に次の 6 枚を表示。タップでジャンプ、長押しでプレビュー。
- **二段階削除** — まずアプリ内のゴミ箱に入れ、後でまとめて iOS の「最近削除した項目」へ。システムのダイアログは一度だけ。
- **Undo** — 直前のスワイプは常に取り消し可能。
- **アプリ内で動画再生** — 動画カードの再生ボタンをタップして全画面 AVKit プレーヤーへ。
- **Liquid Glass** — iOS 26 のネイティブガラス効果、iOS 17〜25 では `.ultraThinMaterial` にフォールバック。
- **ダークモード専用設計** — 黒のレターボックスとミニマル UI、写真閲覧に最適化。
- **多言語対応** — 英語、繁体中国語、簡体中国語、日本語、スペイン語をデバイスの言語に応じて自動切替。
- **完全オフライン** — サーバー無し、アカウント無し、テレメトリ無し。データはすべてデバイス内に留まります。

## 必要環境

- iOS 17.0 以上(Liquid Glass の完全な効果は iOS 26+)
- Xcode 16 以上(推奨は Xcode 26+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## ビルド

```bash
git clone https://github.com/Kazzx9921/PhotoClean.git
cd PhotoClean
xcodegen generate
open PhotoClean.xcodeproj
```

Xcode で:
1. `PhotoClean` ターゲットを選択 → **Signing & Capabilities**
2. *Automatically manage signing* を有効にして Team を選択
3. iPhone を接続し、実行先として選択
4. ⌘R を押す

無料の Apple ID(Personal Team)を使う場合、アプリは 7 日で失効し、同時にサイドロードできるのは 3 本までです。Apple Developer 有料会員($99/年)では制限が解除されます。

## Fork して自分で公開する場合

自分のビルドを App Store に公開する場合([ライセンス](#ライセンス)に従ってください)、オリジナルと衝突しないよう以下の 3 箇所を変更してください:

1. **Bundle identifier** — `project.yml` の `PRODUCT_BUNDLE_IDENTIFIER: com.geekaz.PhotoClean` を自分のリバース DNS ID に変更し、`xcodegen generate` を実行します。
2. **アプリ内課金 Product ID** — `PhotoClean/Features/Paywall/PaywallStore.swift` の `productID` 定数を変更し、App Store Connect で対応する Non-Consumable の IAP を登録します。
3. **ローカル StoreKit テスト設定** — `PhotoClean.storekit` 内の `productID` も同じく変更し、Xcode スキームのローカルサンドボックスで引き続きテストできるようにします。

署名は既に `Automatic` に設定されているので、Apple Developer Team は Xcode が自動で読み込みます。プロジェクトファイルの変更は不要です。

## プロジェクト構成

```
PhotoClean/
├─ App/                  @main とルートルーティング
├─ Core/                 PhotoLibraryService、TrashStore、UndoStack、Models、FormatHelper
├─ Features/
│  ├─ Home/              スワイプ画面 + view model + プレビュー帯 + カード + 動画プレーヤー
│  ├─ Trash/             一括削除グリッド + コミットフロー
│  ├─ Onboarding/        3 ページのウェルカム + 権限リクエスト
│  └─ Settings/          統計 + アプリ情報 + GitHub リンク
├─ UI/                   Haptics、LiquidGlass(iOS 26 modifier)
├─ Resources/            Localizable.xcstrings(5 言語)
└─ Assets.xcassets/      AppIcon + AccentColor
```

## 設計上の選択

| 決定 | 理由 |
|---|---|
| スワイプごとでなくバッチ削除 | iOS は `PHAssetChangeRequest.deleteAssets` を呼ぶたびに確認ダイアログを要求します。1 枚ずつダイアログが出るとリズムが崩れるため、まとめて 1 回に。 |
| 独自インデックスを作らない | `PHAsset.fetchAssets(withLocalIdentifiers:)` が Photos ネイティブのインデックスで O(1) ルックアップを提供。5 万枚ライブラリで約 5 MB のメモリ節約。 |
| `PHPhotoLibraryChangeObserver` | iOS からのプッシュ通知でライブラリ変更を受信。シーンフェーズ復帰時に再フェッチ不要。 |
| サムネイル LRU 上限 50 | プレビュー帯のワーキングセットと一致し、メモリ使用量が予測可能。 |
| トップ/ボトムバーをオーバーレイ | Liquid Glass は下に可視コンテンツがあると屈折効果が働くため、バーを写真の上に浮かせています。 |

## Star History

<a href="https://www.star-history.com/#Kazzx9921/PhotoClean&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
 </picture>
</a>

## ライセンス

[PolyForm Noncommercial 1.0.0](LICENSE) — クローン、改変、自分のデバイスへのインストールは自由。再販や App Store 等への再掲載は**不可**。

商用ライセンスについては <geekaz.net@gmail.com> までご連絡ください。

## クレジット

- Apple SwiftUI、Photos、AVKit、PhotosUI
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
