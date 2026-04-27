# SwiftEdit

SwiftUIで実装したmacOS向けのシンプルなテキストエディタです。  
プレーンテキストファイルの作成・編集・保存に対応したドキュメントベースアプリです。

## 動作環境

| 項目 | バージョン |
|------|-----------|
| macOS | 14.0 (Sonoma) 以降 |
| Xcode | 15.0 以降 |
| Swift | 5.0 以降 |

---

## ビルド方法

### 方法 1: スクリプトでビルド（推奨）

```bash
# Debugビルド（デフォルト）
./build.sh

# Releaseビルド
./build.sh Release

# クリーンしてからビルド
CLEAN=1 ./build.sh
```

ビルド成功後、アプリは `build/Debug/SwiftEdit.app`（または `build/Release/SwiftEdit.app`）に出力されます。

### 方法 2: Xcodeでビルド

1. `SwiftEdit.xcodeproj` をXcodeで開く
2. メニューから **Product → Build**（または `⌘B`）を実行

---

## 起動方法

### スクリプトでビルドした場合

```bash
# Debugビルドを起動
open build/Debug/SwiftEdit.app

# Releaseビルドを起動
open build/Release/SwiftEdit.app
```

### Xcodeから起動

メニューから **Product → Run**（または `⌘R`）を実行します。

---

## 使い方

- **新規ファイル作成**: メニューから **File → New**（`⌘N`）
- **ファイルを開く**: メニューから **File → Open**（`⌘O`）、またはテキストファイルをアプリアイコンにドロップ
- **保存**: **File → Save**（`⌘S`）
- 対応フォーマット: プレーンテキスト（`.txt` など）

---

## プロジェクト構成

```
SwiftEdit/
├── SwiftEdit/
│   ├── SwiftEditApp.swift       # アプリエントリポイント
│   ├── ContentView.swift        # エディタUI
│   ├── SwiftEditDocument.swift  # ドキュメントモデル
│   ├── Assets.xcassets/         # アセット
│   ├── Info.plist
│   └── SwiftEdit.entitlements
├── SwiftEdit.xcodeproj/
├── build.sh                     # ビルドスクリプト
└── README.md
```
