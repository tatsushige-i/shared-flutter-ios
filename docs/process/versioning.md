# バージョン番号運用

iOS アプリのバージョン情報（`CFBundleShortVersionString` / `CFBundleVersion`）の
管理方針と、`pubspec.yaml` から Info.plist への伝播経路を定義する。

## Source of Truth

**`pubspec.yaml` の `version` フィールドが単一の真実の源（SoT）**。

```yaml
version: <major>.<minor>.<patch>+<build_number>
# 例: version: 1.0.0+1
```

- `<major>.<minor>.<patch>` (build name) — App Store に表示される「バージョン」
- `<build_number>` (build number) — App Store Connect 内部で各ビルドを区別するための番号

Xcode 側（`ios/Runner.xcodeproj/project.pbxproj`）の `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` を **Xcode GUI から手動で編集しないこと**。pubspec と乖離した値が
入り込み、ビルド結果が予測不能になる。

## 伝播経路

`pubspec.yaml` から iOS バンドルへの値の流れは以下のとおり。すべて自動で行われる。

```text
pubspec.yaml: version: 1.0.0+1
        │
        │  fvm flutter pub get / fvm flutter build
        ▼
ios/Flutter/Generated.xcconfig
        FLUTTER_BUILD_NAME=1.0.0
        FLUTTER_BUILD_NUMBER=1
        │
        │  Xcode build (PBXProj が xcconfig を include)
        ▼
ios/Runner.xcodeproj/project.pbxproj
        CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)"
        │
        │  ビルド時の変数展開
        ▼
ios/Runner/Info.plist
        CFBundleShortVersionString = $(FLUTTER_BUILD_NAME)  → 1.0.0
        CFBundleVersion           = $(FLUTTER_BUILD_NUMBER) → 1
```

関連ファイル:

- `pubspec.yaml`（SoT）
- `ios/Flutter/Generated.xcconfig`（自動生成。手動編集禁止）
- `ios/Runner/Info.plist`（`CFBundleShortVersionString` / `CFBundleVersion` の定義箇所）
- `ios/Runner.xcodeproj/project.pbxproj`（`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`）

## bump 方針

### build number (`+N`) の bump

- **App Store Connect / TestFlight に新規ビルドをアップロードするたびに必ず +1 する**
  - Apple の仕様上、同じ build number のビルドは再アップロード不可
  - アップロード失敗・差し戻しで再アップロードする場合も新しい番号が必要
- 開発中の実機ビルド（`docs/process/device-install.md` の手順）では bump 不要
- リリース時の build name (`X.Y.Z`) bump と同時に `+1` にリセットしてもよい（例: `1.0.0+5` → `1.1.0+1`）

### version (`X.Y.Z`) の bump

詳細ルールは [`README.md` の「リリースタグ・バージョニング規約」](../../README.md#リリースタグバージョニング規約)
に従う。pubspec の `X.Y.Z` 部分と Git タグ `vX.Y.Z` は**常に一致させる**こと。

## リリース手順

リリースビルドを作成するときは以下の順で行う。

1. `pubspec.yaml` の `version:` を bump
   - 例: `version: 0.1.0+1` → `version: 0.2.0+1`（マイナーリリース）
   - 例: `version: 0.2.0+1` → `version: 0.2.0+2`（同 version の再ビルド）
2. 変更を commit
3. `vX.Y.Z` 形式の annotated タグを push（手順は README 参照）

   ```bash
   git tag -a v0.2.0 -m "v0.2.0"
   git push origin v0.2.0
   ```

4. `Build (iOS)` ワークフロー（`.github/workflows/build.yml`）が自動起動する

## 確認方法

pubspec の値が正しく伝播されているかは以下で確認できる。

```bash
fvm flutter pub get
grep "FLUTTER_BUILD_NAME\|FLUTTER_BUILD_NUMBER" ios/Flutter/Generated.xcconfig
```

ビルド成果物の Info.plist を直接確認する場合:

```bash
fvm flutter build ios --no-codesign
/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
    build/ios/iphoneos/Runner.app/Info.plist
/usr/libexec/PlistBuddy -c "Print CFBundleVersion" \
    build/ios/iphoneos/Runner.app/Info.plist
```
