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

build name (`X.Y.Z`) は [semantic versioning](https://semver.org/lang/ja/) に従って上げる。

| 区分      | 上げる条件                                       | 例                |
| --------- | ------------------------------------------------ | ----------------- |
| **MAJOR** | 後方互換を壊す大規模な変更・全面刷新             | `1.4.2` → `2.0.0` |
| **MINOR** | 後方互換のある機能追加                           | `1.4.2` → `1.5.0` |
| **PATCH** | バグ修正のみ（機能追加なし）                     | `1.4.2` → `1.4.3` |

- pubspec の `X.Y.Z` 部分と Git タグ `vX.Y.Z+N` の `X.Y.Z` 部分は**常に一致させる**こと。
- MINOR / MAJOR を上げる際は build number を `+1` にリセットしてよい（例: `1.4.2+5` → `1.5.0+1`）。

## リリース手順

リリースのブランチフロー・タグ運用の正本は
[`release-workflow.md`](./release-workflow.md)（`/release-ios-build` スキルを主経路とする）。
バージョン番号の観点での要点は以下のとおり。

1. `pubspec.yaml` の `version:` を bump
   - 例: `version: 0.1.0+1` → `version: 0.2.0+1`（マイナーリリース）
   - 例: `version: 0.2.0+1` → `version: 0.2.0+2`（同 version の再ビルド）
2. bump コミットを PR 経由でリリース対象ブランチに反映（フローは `release-workflow.md` 参照）
3. マージ後、`vX.Y.Z+N`（build number 込み）形式の annotated タグを push

   ```bash
   git tag -a v0.2.0+1 -m "v0.2.0+1"
   git push origin v0.2.0+1
   ```

   - タグ名は `pubspec.yaml` の `version:` をそのまま反映する。ASC は同一 `X.Y.Z` でも
     アップロードごとに build number (`+N`) を上げるため、`+N` まで含めてビルド単位で一意に追跡する。

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
