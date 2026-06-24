# アプリのローカライズ宣言（日本語対応）

Flutter/iOS アプリが日本語対応であることを**アプリバイナリで宣言**し、App Store 製品ページの
「言語」が日本語表示になるようにするための背景と適用手順をまとめる。新規アプリのリリース定型
（`docs/process/release-roadmap.md` の Milestone 2「日本語ローカライズの宣言・適用」）から参照する。

> **アプリ固有値**: `{{app_name}}` 等のプレースホルダは、各アプリの
> `.claude/flutter-ios-profile.md` の値に読み替える。

## 背景：App Store の「言語」表示の仕組み

App Store 製品ページの「言語 (Languages)」フィールドは、**ストアのメタデータ言語ではなく
アプリバイナリが宣言する対応言語**に由来する。具体的には次の 3 つが参照される。

| 宣言箇所               | ファイル                                  | 役割                                       |
| ---------------------- | ----------------------------------------- | ------------------------------------------ |
| `CFBundleLocalizations`| `ios/Runner/Info.plist`                   | バンドルが対応するローカライズの一覧        |
| `knownRegions`         | `ios/Runner.xcodeproj/project.pbxproj`    | Xcode プロジェクトが認識するリージョン      |
| `developmentRegion`    | `ios/Runner.xcodeproj/project.pbxproj`    | 既定の開発リージョン                        |

これらに `ja` が宣言されていないと、メタデータを日本語で入力していても製品ページの「言語」は
**「English」と表示される**。日本語対応アプリであることを正しく見せるため、新規アプリでは
リリース前にこの宣言を必ず行う。

> 実例: bulklog で「言語: English」表示が発生し、対応 PR で本手順と同等の宣言を追加して解消した。

## 適用手順

### 1. Flutter 側：`flutter_localizations` 導入と `Locale('ja')` 固定

1. `pubspec.yaml` の `dependencies` に SDK の `flutter_localizations` を追加する。

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_localizations:
       sdk: flutter
   ```

2. ルートの `MaterialApp`（`lib/app/app.dart`）に `localizationsDelegates` /
   `supportedLocales` を設定し、`locale` を `Locale('ja')` に固定する。

   ```dart
   MaterialApp.router(
     localizationsDelegates: GlobalMaterialLocalizations.delegates,
     supportedLocales: const [Locale('ja')],
     locale: const Locale('ja'),
     // ...
   );
   ```

   - `GlobalMaterialLocalizations.delegates` は `package:flutter_localizations/flutter_localizations.dart`
     から import する。
   - 多言語化を行わず日本語固定でよい場合も、`supportedLocales` に `ja` を含めることで
     Material コンポーネントの日本語表示が有効になる。

### 2. iOS バイナリ宣言：`Info.plist` / `project.pbxproj`

1. `ios/Runner/Info.plist` に `CFBundleLocalizations` を追加し、`ja` を宣言する。

   ```xml
   <key>CFBundleLocalizations</key>
   <array>
     <string>ja</string>
   </array>
   ```

2. `ios/Runner.xcodeproj/project.pbxproj` の `knownRegions` に `ja` が含まれていることを確認する
   （無ければ追加）。

   ```text
   knownRegions = (
     en,
     Base,
     ja,
   );
   ```

3. 同ファイルの `developmentRegion` を意図どおりに設定する。日本語を主とするアプリでは
   `developmentRegion = ja;` とする運用が分かりやすい（既定の `en` のままでも `CFBundleLocalizations`
   に `ja` があれば「言語」には日本語が出るが、開発リージョンを実態に合わせる）。

> `project.pbxproj` は Xcode GUI 経由でも編集できる（Project > Info > Localizations に Japanese を
> 追加）。バージョン値（`MARKETING_VERSION` 等）は GUI から触らない点は `versioning.md` のとおり。

### 3. 確認

1. `fvm flutter build ios` でビルドし、ビルド成果物に宣言が反映されていることを確認する。
2. ASC へアップロード後、App Store 製品ページ（または ASC のビルド情報）で「言語」が
   **日本語**と表示されることを確認する。

## 関連ドキュメント

- `docs/process/versioning.md` — 同じく `Info.plist` / `project.pbxproj` を扱う。バージョン値は
  GUI から手編集しない方針もこちらに記載。
- `docs/process/release-roadmap.md` — 本手順を参照する定型 Issue「日本語ローカライズの宣言・適用」
  （Milestone 2）の正本。
