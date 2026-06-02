# アプリアイコン運用

iOS アプリアイコン (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`) は
`flutter_launcher_icons` で 1 枚のマスター画像から再生成する。直接 PNG を編集しない。

## Source of Truth

- `assets/icon/app_icon.svg` — 編集可能なベクタソース (任意・推奨)
- `assets/icon/app_icon.png` — `flutter_launcher_icons` の入力 (1024×1024 / 不透明 / sRGB)

`pubspec.yaml` の `flutter_launcher_icons:` セクションが `image_path` を指している。

```yaml
flutter_launcher_icons:
  ios: true
  android: false
  image_path: "assets/icon/app_icon.png"
  remove_alpha_ios: true
```

## 再生成手順

### 1. マスター画像を更新する

SVG ソースを編集した場合は PNG にラスタライズする。

```sh
brew install librsvg   # 未インストールなら一度だけ
rsvg-convert --width 1024 --height 1024 \
  --background-color "#0F2A44" \
  assets/icon/app_icon.svg \
  -o assets/icon/app_icon.png
```

- `--background-color` は SVG の `<rect>` 背景と揃える（上記 `#0F2A44` は一例。アプリのブランド
  カラーに置き換える）。App Store 提出向けの 1024×1024 は
  アルファチャネルを含めてはいけないため、必ず不透明な背景色を指定すること。
- 既存の PNG を別ツール (Figma 等) でエクスポートする場合も、1024×1024 / 不透明 / sRGB を満たすこと。

### 2. iOS アイコンを再生成する

```sh
fvm flutter pub get
fvm dart run flutter_launcher_icons
```

`ios/Runner/Assets.xcassets/AppIcon.appiconset/` 配下の PNG と `Contents.json` がすべて
新しいアイコンで上書きされる。

### 3. 検証

```sh
# 1024 マスターがアルファ無しか確認
magick identify ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
# → "8-bit sRGB" (4 番目の項に "RGBA" が含まれないこと)

# ビルド破綻が無いか
fvm flutter build ios --no-codesign

# 実機/シミュレータで表示確認
fvm flutter run
```

ホーム画面で旧アイコンがキャッシュされている場合はアプリを一度削除して再インストールする。

## コミット対象

- `assets/icon/app_icon.svg` (使用していれば)
- `assets/icon/app_icon.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` の差分すべて
- 必要に応じて `pubspec.yaml` / `pubspec.lock`

`assets/icon/proposals/` はデザイン検討時のローカル作業用ディレクトリで `.gitignore` 対象。
コミット不要。

## 注意

- 仮アイコン（テキストワードマーク等）で開発を進める場合は、確定デザインが決まり次第
  本手順で再生成して差し替える。
- `flutter_launcher_icons` を実行すると `ios/Runner.xcodeproj/project.pbxproj` の
  `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` が `AppIcon` に変更される。
  これはツールの仕様で、戻す必要はない。
