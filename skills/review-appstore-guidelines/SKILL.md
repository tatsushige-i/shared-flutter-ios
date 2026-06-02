---
name: review-appstore-guidelines
description: Apple App Store Review Guidelines を実行時に取得し、対象アプリの実装と照合して審査懸念を表形式で抽出する
argument-hint: "[--section <番号 or 名前>] [--feature <feature 名>]"
---

# App Store Review Guidelines 準拠チェックスキル

Apple 公式の [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) を実行時に取得し、対象アプリの実装と照合して、審査リジェクトにつながりうる懸念点を表形式で出力する。

> 対象アプリの固有値（アプリ名 / Bundle ID 等）は各アプリの `.claude/flutter-ios-profile.md` を参照する。
> 照合結果を記録に残す場合は [`docs/process/app-store-guideline-review.md`](../../../docs/process/app-store-guideline-review.md) の雛形を使う。

ガイドラインはスキル本体に埋め込まず実行時取得することで、改訂への追従負担をなくし、静的解析の枠を超えた解釈的レビューを可能にする。

## Steps

### Step 1: 引数パース

実行時に渡される引数を解釈する。

- `--section <番号 or 名前>` （例: `5.1`, `Privacy`, `3.1.1`）
  - 指定されたセクションに対象を限定する。コンテキスト肥大の防止が目的。
  - 名前指定の場合は柔軟に解釈する（例: `Privacy` → `5.1` 系全体、`IAP` → `3.1.1〜3.1.6`）
- `--feature <feature 名>` （例: `workout`）
  - `lib/features/<feature>/` 配下のみをコード対象に絞る
- 引数なしの場合のデフォルト対象セクション（「審査で落ちやすい代表章」）:
  - **Safety**: 1.1, 1.2, 1.4, 1.5
  - **Performance**: 2.1（App Completeness）, 2.3（Accurate Metadata）
  - **In-App Purchase**: 3.1.1, 3.1.2, 3.1.3
  - **Design**: 4.0, 4.2（Minimum Functionality）
  - **Privacy**: 5.1.1, 5.1.2, 5.1.5（Location）

### Step 2: ガイドライン取得

`WebFetch` で公式ガイドラインを取得する。

- URL: `https://developer.apple.com/app-store/review/guidelines/`
- 取得時のプロンプトは「Step 1 で決定した対象セクションの本文と要求事項を抽出する」とする
- 取得に失敗した場合（ネットワーク不通、構造変更など）はその旨を報告して中断する

### Step 3: プロジェクト関連ファイルの収集

以下のファイル群を読み込む。

**常に対象（共通）**:

- `ios/Runner/Info.plist`
  - 各種 `NS*UsageDescription`（カメラ、写真、位置情報、トラッキング等）
  - `NSPrivacyTracking` / `NSPrivacyTrackingDomains`
  - `LSApplicationQueriesSchemes`、URL Scheme、Universal Links 関連
  - サポートする向き、機能（`UIRequiredDeviceCapabilities`）
- `pubspec.yaml`
  - 審査リスクのある依存（IAP: `in_app_purchase`、ATT: `app_tracking_transparency`、WebView: `webview_flutter`、課金、広告、アナリティクス、地図 SDK など）

**引数による対象**:

- `--feature <feature 名>` 指定時: `lib/features/<feature>/` 配下の Dart ファイル
- 引数なし時: `lib/features/**/*.dart` から審査関連キーワード（`purchase`, `webview`, `tracking`, `permission`, `camera`, `photo`, `location`, `health`, `microphone`, `notification`, `bluetooth` 等）を `grep` で検索し、ヒットしたファイルのみ読む

### Step 4: 照合と懸念抽出

取得したガイドライン本文と、収集した実装を照合する。

- 「実装に対して対応が不足している項目」を抽出
- 「現状は該当する実装がないが、追加すると審査リスクになる項目」も補足として抽出
- 該当する実装が一切ないセクションは「該当なし（現状リスクなし）」と明示

### Step 5: 表形式での出力

以下のテーブル形式で結果を出力する。

| セクション | 該当ファイル:行 | 懸念内容 | 推奨対応 |
| --- | --- | --- | --- |
| 例: 5.1.1 Data Collection and Storage | `ios/Runner/Info.plist` （該当なし） | カメラや写真ライブラリへのアクセスを将来追加する場合、`NS*UsageDescription` に具体的な利用目的を記述する必要がある | 権限利用機能の追加時に該当 usage description を追加 |
| 例: 3.1.1 In-App Purchase | `pubspec.yaml` （該当なし） | デジタルコンテンツの販売を将来導入する場合、Apple 公式の IAP API 利用が必須 | `in_app_purchase` パッケージを利用し、外部決済リンクを設置しない |

- **セクション**: ガイドラインの番号（例: `5.1.1`, `3.1.1(a)`）を明記
- **該当ファイル:行**: 具体的に指す箇所がない場合は「該当なし」と記載
- **懸念内容**: 現状の問題、または将来の潜在リスクを 1〜2 文で
- **推奨対応**: 具体的な改善アクション

### Step 6: 注意事項の明記

出力末尾に以下を必ず付記する。

```text
本スキルは App Store Review Guidelines の本文に基づく解釈的レビューを行いますが、
最終的な審査結果を保証するものではありません。重大な懸念があれば
`gh issue create` で Issue 化して追跡することを推奨します。
```

## Notes

- 本スキルは読み取り専用。`Info.plist` や `pubspec.yaml` 等の修正は提案にとどめ、ユーザー指示なく書き換えない。
- ガイドラインのページ構造が大幅に変更された場合は WebFetch の抽出プロンプトを調整すること。
- Android（Google Play）向けの同等チェックは本スキルのスコープ外。
