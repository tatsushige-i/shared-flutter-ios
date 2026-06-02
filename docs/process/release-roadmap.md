# Release Roadmap

新規 Flutter(iOS) アプリを App Store リリースまで導くための **Milestone / Issue の正本**。
`release-roadmap-scaffold` skill がこのファイルを読み、対象 repo に 3 Milestone と各 Issue を
冪等に一括起票する。

> **このファイルが正本**。Milestone や定型 Issue を増減・改訂したいときは本ファイルを編集する
> （skill 側は編集しない）。
>
> **アプリ固有値**: Issue 本文中の `{{app_name}}` / `{{bundle_id}}` 等のプレースホルダは、
> skill が各アプリの `.claude/flutter-ios-profile.md` の値に置換して起票する。
>
> **ラベル**: 各 Issue の type ラベル（`chore` / `feature` / `enhancement` / `documentation` /
> `bug`）と priority ラベル（`priority: high|medium|low`）は、対象 repo に存在している前提。
> 無ければ shared-claude-code の `config-github-sync` で整備してから scaffold する。
>
> **スコープ**: ここに含めるのは新規アプリで共通して必要な定型作業のみ。アプリ固有の MVP 機能
> Issue や QA バグは各アプリで別途起票する。

各 Issue 本文は以下の共通フォーマットで生成する（`documentation` / `chore` は Implementation
Approach を省く）。

```markdown
## Overview
<1-2 文>

## Background & Motivation
<なぜ必要か>

## References
- docs/process/<doc>.md / 関連 skill

## Acceptance Criteria
- [ ] <完了条件>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Milestone 1: MVP 実装完了

> 説明: アプリとして動作する最小機能セットが揃い、実機で一通り操作できる状態を目指す。
> （アプリ固有の機能 Issue は各アプリで追加する。本 Milestone には足場のみを含める）

### Issue: プロジェクト初期セットアップ（fvm / 依存 / ディレクトリ構成）
- type: `chore`
- priority: `priority: high`
- body:
  - Overview: `{{app_name}}` の Flutter プロジェクトを初期化し、開発を始められる状態にする。
  - Background: fvm による Flutter バージョン固定、基本依存（riverpod / go_router / freezed 等）の
    導入、`lib/` のディレクトリ構成を規範に沿って用意する。
  - References: `rules/flutter-ios/architecture.md`（レイヤ構成）
  - Acceptance Criteria:
    - [ ] `fvm` で Flutter バージョンが固定されている
    - [ ] `lib/app` / `lib/core` / `lib/features` の骨格が存在する
    - [ ] `fvm flutter run` でアプリが起動する

### Issue: アーキテクチャ規範の適用（features / レイヤ構成の雛形整備）
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: `architecture.md` のレイヤ構成（presentation / application / domain / data）に沿った
    feature 雛形を整備する。
  - Background: 以降の機能追加が規範どおりに行えるよう、最初の feature をリファレンス実装にする。
  - References: `rules/flutter-ios/architecture.md`
  - Acceptance Criteria:
    - [ ] 1 つの feature が 4 レイヤ構成で実装されている
    - [ ] Riverpod プロバイダーが `application/` に集約されている
    - [ ] 依存方向（presentation → application → data → domain）が守られている

### Issue: CI 整備（lint / test / build ワークフロー）
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: push / PR で lint・test・ビルド検証が走る CI を整備する。
  - Background: 後続のリリースタグ検証ビルド（`.github/workflows/build.yml`）の土台にもなる。
  - References: `docs/process/release-workflow.md`（タグ検証ビルド）
  - Acceptance Criteria:
    - [ ] PR で `flutter analyze` / `flutter test` が実行される
    - [ ] `flutter build ios --no-codesign` の検証ビルドが通る

### Issue: docs 基盤整備（spec / process ディレクトリ）
- type: `documentation`
- priority: `priority: low`
- body:
  - Overview: `documentation.md` の規約に沿って `docs/` の構成（spec / design / process / archive）を
    用意する。
  - Background: 仕様・手順を継続的にメンテできる置き場を最初に決めておく。
  - References: `rules/flutter-ios/documentation.md`
  - Acceptance Criteria:
    - [ ] `docs/spec` / `docs/process` が存在する
    - [ ] 現行仕様の最初の 1 ページが `docs/spec` にある

---

## Milestone 2: iOS 申請準備完了

> 説明: アプリアイコン・Launch Screen・Info.plist・Bundle ID などの iOS 仕上げと、App Store 提出用
> メタデータ・プライバシー・審査準拠の準備を完了させる。

### Issue: アプリアイコン決定・差し替えツール整備
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: `{{app_name}}` のアプリアイコンを確定し、マスター 1 枚から再生成できる運用を整える。
  - Background: `flutter_launcher_icons` による再生成フローを用意し、1024×1024 / 不透明 / sRGB の
    提出要件を満たす。
  - References: `docs/process/app-icon.md`
  - Acceptance Criteria:
    - [ ] `assets/icon/app_icon.png`（1024×1024 / アルファ無し）が用意されている
    - [ ] `flutter_launcher_icons` で iOS アイコン一式が再生成できる

### Issue: Launch Screen カスタマイズ
- type: `chore`
- priority: `priority: low`
- body:
  - Overview: 既定の Flutter Launch Screen を `{{app_name}}` 用にカスタマイズする。
  - Background: 起動時の体験を整え、審査時の「未完成」印象を避ける。
  - Acceptance Criteria:
    - [ ] `ios/Runner/Base.lproj/LaunchScreen.storyboard` がアプリ用に調整されている

### Issue: Bundle ID・表示名・バージョン整備
- type: `chore`
- priority: `priority: high`
- body:
  - Overview: Bundle ID `{{bundle_id}}` / 表示名 `{{app_name}}` / バージョンを正しく設定する。
  - Background: App Store 公開後に Bundle ID は変更不可。`pubspec.yaml` を SoT としたバージョン
    伝播を確立する。
  - References: `docs/process/versioning.md`
  - Acceptance Criteria:
    - [ ] `CFBundleDisplayName` が `{{app_name}}`、Bundle ID が `{{bundle_id}}`
    - [ ] `pubspec.yaml` の version が Info.plist に正しく伝播している

### Issue: Info.plist 権限・暗号化申告の整理
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: 使用する権限の `NS*UsageDescription` と輸出コンプライアンス宣言を整理する。
  - Background: 不要な権限宣言を持たず、`ITSAppUsesNonExemptEncryption` を実装に合わせて宣言する。
  - References: `docs/process/release-workflow.md`（Export Compliance）、`review-appstore-guidelines` skill
  - Acceptance Criteria:
    - [ ] 実装で要求する権限のみに usage description が記述されている
    - [ ] `ITSAppUsesNonExemptEncryption` が実装に合った値で宣言されている

### Issue: App Privacy 申告の整理
- type: `documentation`
- priority: `priority: medium`
- body:
  - Overview: App Store Connect の App Privacy 申告内容を整理し台帳化する。
  - Background: 収集データ・トラッキングの有無を実装から確認し、申告とポリシーを整合させる。
  - References: `docs/process/app-privacy.md`
  - Acceptance Criteria:
    - [ ] App Privacy の申告結論が実装の確認に基づいて記録されている
    - [ ] ASC 側で申告が公開（Publish）されている

### Issue: プライバシーポリシー作成・公開（Support ページ含む）
- type: `feature`
- priority: `priority: medium`
- body:
  - Overview: プライバシーポリシーとサポートページを作成し `{{site_domain}}` で公開する。
  - Background: 審査要件（5.1.1 / 1.5）を満たすため、Cloudflare Pages で静的配信する。
  - References: `docs/process/cloudflare-pages-setup.md`
  - Acceptance Criteria:
    - [ ] `{{privacy_policy_url}}` でプライバシーポリシーに到達できる
    - [ ] `{{support_url}}` でサポートページに到達できる

### Issue: App Store Connect アプリレコード登録
- type: `chore`
- priority: `priority: high`
- body:
  - Overview: ASC に `{{app_name}}`（Bundle ID `{{bundle_id}}`）のアプリレコードを作成する。
  - Background: ビルドのアップロード先・メタデータ入力先となる。作成後 `asc_app_id` を profile に控える。
  - References: `docs/process/release-workflow.md`
  - Acceptance Criteria:
    - [ ] ASC に Bundle ID `{{bundle_id}}` のアプリレコードがある
    - [ ] `asc_app_id` が `.claude/flutter-ios-profile.md` に記録されている

### Issue: メタデータ確定・掲載テキスト作成
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: 名称・サブタイトル・説明文・キーワード・カテゴリ・年齢レーティング・配信地域を確定する。
  - Background: 隠し機能なし・名称 30 文字以内など 2.3 Accurate Metadata の要件を満たす。
  - Acceptance Criteria:
    - [ ] 掲載テキスト一式が用意され ASC に入力されている
    - [ ] カテゴリ・年齢・配信地域が確定している

### Issue: スクリーンショット撮影（必須サイズ）
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: 必須サイズ（iPhone 6.9″）のスクリーンショットを撮影する。
  - Background: シミュレータでステータスバーを整え、価値訴求順に複数枚用意する。
  - References: `docs/process/app-store-screenshots.md`
  - Acceptance Criteria:
    - [ ] 1320×2868 のスクショが必要枚数（3〜5 枚目安）揃っている
    - [ ] `docs/process/assets/app-store-screenshots/` に保管されている

### Issue: App Review ガイドライン準拠チェック
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: App Store Review Guidelines と現行実装を照合し、審査懸念を事前に洗い出す。
  - Background: 申請前にリジェクト要因を潰す。`review-appstore-guidelines` skill で実施し記録する。
  - References: `docs/process/app-store-guideline-review.md`、`review-appstore-guidelines` skill
  - Acceptance Criteria:
    - [ ] 主要セクションの照合結果が記録されている
    - [ ] 要対応項目が解消または Issue 化されている

### Issue: 実機動作確認チェックリスト作成・実機 UAT
- type: `documentation`
- priority: `priority: medium`
- body:
  - Overview: 申請前の実機動作確認チェックリストを作成し、開発実機で UAT を行う。
  - Background: シミュレータで見えない実機特有の挙動を確認する。
  - References: `docs/process/device-install.md`
  - Acceptance Criteria:
    - [ ] 実機確認チェックリストが用意されている
    - [ ] 開発実機で全項目を確認済み

---

## Milestone 3: App Store 申請通過

> 説明: TestFlight 配信を経て App Store 審査に提出し、承認されるまでを完了とする。

### Issue: iOS Archive 作成 → ASC アップロード
- type: `chore`
- priority: `priority: high`
- body:
  - Overview: signed IPA をビルドし ASC へアップロードする。
  - Background: `release-ios-build` skill の最短ルート、または手動 Xcode Archive で実施する。
  - References: `docs/process/release-workflow.md`、`release-ios-build` skill
  - Acceptance Criteria:
    - [ ] signed IPA がビルドできる
    - [ ] ASC のビルド一覧に処理完了状態で表示される

### Issue: TestFlight 内部テスト配信・実機確認
- type: `chore`
- priority: `priority: medium`
- body:
  - Overview: アップロードしたビルドを TestFlight 内部テスターへ配信し、実機で確認する。
  - Background: 申請前にリリース候補ビルドそのものを実機で検証する。
  - References: `docs/process/release-workflow.md`
  - Acceptance Criteria:
    - [ ] TestFlight でビルドが内部テスターに配信されている
    - [ ] 配信ビルドを実機で確認済み

### Issue: Review Notes 準備
- type: `documentation`
- priority: `priority: medium`
- body:
  - Overview: 審査担当向けの補足情報（Review Notes）を準備する。
  - Background: 権限の利用目的やデモ手順など、審査をスムーズにする情報を記載する。
  - Acceptance Criteria:
    - [ ] Review Notes の文面が用意されている

### Issue: 審査提出・リジェクト対応運用
- type: `chore`
- priority: `priority: high`
- body:
  - Overview: App Store 審査に提出し、リジェクト時の対応フローを回す。
  - Background: 指摘内容を解消して再提出する運用を確立する。
  - Acceptance Criteria:
    - [ ] 審査に提出済み
    - [ ] リジェクト時は指摘を解消し再提出している

### Issue: リリース直後の本番動作確認・リリース手順書整備
- type: `documentation`
- priority: `priority: medium`
- body:
  - Overview: 公開直後に本番（App Store 配信版）の動作を確認し、リリース手順書を整える。
  - Background: 次回以降のリリースを再現可能にする。
  - References: `docs/process/release-workflow.md`、`docs/process/versioning.md`
  - Acceptance Criteria:
    - [ ] 公開版アプリの主要導線を実機で確認済み
    - [ ] リリース手順書が最新化されている
