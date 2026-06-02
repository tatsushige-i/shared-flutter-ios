# App Store Review Guidelines 照合記録

App Store 提出前に [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
と対象アプリの現行実装を照合し、審査リジェクト懸念を事前に洗い出すための記録テンプレート。
申請（初回・再申請）ごとに `/review-appstore-guidelines` スキルで再実施し、本ファイルを更新する。

> **アプリ固有値**: `{{privacy_policy_url}}` / `{{support_url}}` 等のプレースホルダは、各アプリの
> `.claude/flutter-ios-profile.md` の値に読み替える。
>
> 本ファイルは雛形。`照合メタ` / `結論` / `照合結果` の各表は **各アプリの照合実施結果で記入する**。
> 以下に示す行はローカル完結アプリの記入例であり、実装に応じて差し替える。

## 照合メタ（記入例）

| 項目         | 値                                                                 |
| ------------ | ------------------------------------------------------------------ |
| 実施日       | YYYY-MM-DD                                                         |
| 手段         | `/review-appstore-guidelines`（公式ガイドラインを実行時取得して照合） |
| 対象実装     | `ios/Runner/Info.plist` / `pubspec.yaml` / `lib/` / `web/`         |
| 対象セクション | 1.1 / 1.2 / 1.4 / 1.5 / 2.1 / 2.3 / 3.1.1 / 3.1.2 / 3.1.3 / 4.0 / 4.2 / 5.1.1 / 5.1.2 / 5.1.5 |

## 結論（記入例）

照合の総括をここに書く。例: 「新規の要対応（コード／plist 改修）はゼロ。完全ローカル動作で
ネットワーク送信・外部サービス連携・アカウント機能・センシティブ権限要求・課金・ユーザー生成
コンテンツ・データの端末外流出経路を一切持たないため、ガイドライン上の懸念はすべて『非該当』
または『既存の closed Issue で対応済み』。」

## 照合結果（記入例）

凡例: 🔴 高 / 🟡 中 / 🟢 低（現状リスクなし。将来機能追加時に注意）

| セクション | 該当箇所 | 評価 | リスク | 状態 |
| --- | --- | --- | --- | --- |
| 5.1.1(i) Privacy Policy | Privacy Policy URL `{{privacy_policy_url}}` ／ `web/privacy-policy/index.html` | ポリシー本文・URL ともに整備済み | 🟢 | ✅ |
| 1.5 Developer Information | Support URL `{{support_url}}` ／ `web/support/index.html` | サポートページ配信済み | 🟢 | ✅ |
| App Privacy（栄養ラベル） | `pubspec.yaml` / `lib/` 全体 | 通信・解析・トラッキング依存の有無を確認し申告と整合 | 🟢 | [`app-privacy.md`](./app-privacy.md) 参照 |
| 2.3 Accurate Metadata | `Info.plist`（`CFBundleDisplayName`） | 名称 30 文字以内・カテゴリ・年齢・配信地域を台帳化済み。隠し機能なし | 🟢 | ✅ |
| 2.1 App Completeness | `pubspec.yaml`（`version:`） | プレースホルダなし。実機最終確認で担保 | 🟢 | 実機確認で運用 |
| 5.1.1(ii) Permission 文字列 | `ios/Runner/Info.plist`（`NS*UsageDescription`） | 権限要求があれば具体的な usage description を記述 | 🟢 | — |
| 5.1.1(v) Account Deletion | `lib/` | アカウント／サインイン機能があればアプリ内削除導線が必須 | 🟢 | — |
| 5.1.2 Data Use and Sharing | `lib/` 全体 | 第三者共有・ATT 対象トラッキング・データ外部送信経路の有無 | 🟢 | — |
| 5.1.5 Location Services | `lib/` | 位置情報利用の有無 | 🟢 | — |
| 3.1.1 / 3.1.2 / 3.1.3 In-App Purchase | `pubspec.yaml` | デジタル課金があれば Apple IAP API 必須・外部決済リンク禁止 | 🟢 | — |
| 4.2 Minimum Functionality | `lib/features/` | Web ラッパーでないネイティブな実用性 | 🟢 | — |
| 輸出コンプライアンス | `Info.plist`（`ITSAppUsesNonExemptEncryption`） | 非対象暗号化なしを宣言済みか確認 | 🟢 | — |

## 将来機能追加時に再照合が必要なトリガ

以下のいずれかを実装する場合は、申請前に本照合を再実施し懸念を再評価すること。

- 権限を要する機能（カメラ・写真・位置情報・通知・ヘルスケア等）の追加 → `NS*UsageDescription` の追記が必要（5.1.1(ii) / 5.1.5）
- ネットワーク通信・解析・広告・クラッシュレポート SDK の導入 → App Privacy 申告の見直しが必要（5.1.1 / 5.1.2）
- 課金（IAP・サブスク）の導入 → Apple IAP API 必須・外部決済リンク禁止（3.1.1 / 3.1.2）
- アカウント／サインイン機能の追加 → アプリ内アカウント削除導線が必須（5.1.1(v)）
- データの端末外送信・共有・公開機能の追加 → プライバシーポリシー本文と App Privacy 申告の更新が必要

## Related Docs

- [`app-privacy.md`](./app-privacy.md) — App Privacy（収集データ申告）台帳
- [`release-workflow.md`](./release-workflow.md) — Build & Archive 配信手順

---

> 本記録は App Store Review Guidelines 本文に基づく解釈的レビューであり、最終的な審査結果を保証するものではない。
> 大幅なガイドライン改訂や新機能追加の際は `/review-appstore-guidelines` を再実行して更新すること。
