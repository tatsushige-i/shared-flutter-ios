---
name: release-docs-sync
description: 指定 milestone の Closed Issue / マージ済み PR を変更集合として、消費アプリの docs/spec とテスト仕様書を as-built に最新化し、design→spec→archive のライフサイクル反映までを定型化する。
argument-hint: "<milestone>  (例: 'Release 1.1' / v1.1.0)"
---

# リリースドキュメント同期スキル

リリースごとに必ず発生する**現行仕様書（`docs/spec/`）とテスト仕様書（`docs/process/` の
`*test-spec*`）の as-built 最新化**を、再現性のある手順としてオペレーション化する。
指定 milestone の **Closed Issue / マージ済み PR** を変更集合として、ドリフトを検出し、
ユーザー承認のうえで docs を更新、`design→spec→archive` のライフサイクル反映までを行う。

> `docs/` の構成・役割・ライフサイクル（`design→spec→archive`）の**正本は
> [`documentation.md`](../../rules/flutter-ios/documentation.md)**（`rules/flutter-ios/documentation.md`）。
> 本スキルはそれを参照し、構成ルールを二重管理しない。

> アプリ固有値（GitHub `{{repo}}`）は各アプリの `.claude/flutter-ios-profile.md` を参照する。
> 本スキルはそれを直接埋め込まない。

本スキルは**ビルド / タグ / 審査提出 / リリースノート生成は扱わない**。それらは
[`release-ios-build`](../release-ios-build/SKILL.md) /
[`release-notes-generate`](../release-notes-generate/SKILL.md) を正本とする。
本スキルは「リリースに伴う docs の最新化」のみを担う。

## Steps

### Step 1: スコープ確定（milestone）

1. 引数として対象 milestone を受け取る（例: `'Release 1.1'` / `v1.1.0`）。
2. 引数が無い場合は推測せず、`gh api repos/{{repo}}/milestones --jq '.[].title'` で候補を提示し、
   どの milestone を対象にするかをユーザーに確認する。
3. 対象 milestone の**変更集合**を抽出する:
   - Closed Issue: `gh issue list --milestone "<milestone>" --state closed --json number,title,labels`
   - 関連するマージ済み PR: 各 Issue にひも付く PR、または
     `gh pr list --search "milestone:\"<milestone>\"" --state merged --json number,title,labels`
4. 変更集合（Issue / PR の番号・タイトル・ラベル）を一覧化してユーザーに提示する。
   - 変更集合が空（該当 Issue/PR 無し）の場合は、その旨を伝えて停止する（更新対象が無い）。

### Step 2: docs 棚卸し

[`documentation.md`](../../rules/flutter-ios/documentation.md) の構成・役割を正本に、
現状の docs を一覧化する:

- `docs/spec/` 配下の現行仕様書
- `docs/process/` のテスト仕様書（`*test-spec*` 等、名称はアプリの慣例に従う）
- `docs/design/` の対象機能の設計案（`design→spec` 反映待ちの候補）

該当ディレクトリが存在しない場合は、その旨を記録し（無いものは無いと扱い）、後続ステップで
新規作成の要否をユーザーに確認する。

### Step 3: ドリフト検出

変更集合（実装された機能 / UX 変更）と現行 docs を突き合わせ、以下を分類して列挙する:

| 区分 | 内容 |
| ---- | ---- |
| 更新が必要な spec | 実装が変わったのに `docs/spec/` が追従していない箇所 |
| 更新が必要なテスト仕様 | 機能変更に対しテスト観点・期待値の更新が必要な箇所 |
| `design→spec` 反映待ち | 実装完了済みなのに `docs/design/` に残っている設計案 |
| `spec→archive` 退役候補 | 現行仕様でなくなった `docs/spec/` 文書 |

各項目に対応する変更集合（Issue/PR 番号）を併記し、トレーサビリティを確保する。

### Step 4: 承認ゲート

- ドリフト検出結果と**更新方針**（どのファイルを・どう直すか／どれを archive へ移すか）を
  **全文ユーザーに提示**する。
- ユーザーの明示承認を得るまで、docs ファイルは一切書き換えない。
- 方針に過不足があれば指摘を反映し、再提示する。

### Step 5: spec / テスト仕様の as-built 更新

承認後、変更集合の実装内容に合わせて docs を更新する:

- `docs/spec/` … 実装の現状（as-built）を正として恒久メンテ対象として更新する。
- テスト仕様書（`docs/process/` の `*test-spec*`）… 機能変更に対応するテスト観点・
  期待値・手順を更新する。
- 新規仕様が必要な場合は [`documentation.md`](../../rules/flutter-ios/documentation.md) の
  Placement Rules に従って配置する（階層を深くしすぎない。参照アセットは同階層の `assets/`）。

### Step 6: ライフサイクル反映（design→spec→archive）

[`documentation.md`](../../rules/flutter-ios/documentation.md) の Lifecycle / archive 構造に従う:

- 実装完了済みの `docs/design/` 設計案は、内容を `docs/spec/` へ反映後、
  `docs/archive/design/` へ**移動のみ**（内容は凍結・更新しない）。
- 現行仕様でなくなった `docs/spec/` 文書は `docs/archive/spec/` へ移動する。
- `docs/archive/` 直下に直接置かず、`archive/spec/` / `archive/design/` 等の
  カテゴリ別サブディレクトリに置く。空のカテゴリディレクトリは作らない。

### Step 7: `/git-pr-create` へ委譲

- 更新が一通り完了したら `git diff --stat` と主要な差分をユーザーに提示する。
- 本スキルでは **commit / push / PR 作成を行わない**。問題が無ければ `/git-pr-create`
  フローで PR を作成するよう案内する（コミットは `/git-pr-create` のフローに委ねる）。

## Notes

- 本スキルはビルド / タグ / 審査提出 / リリースノート生成を扱わない。それぞれ
  [`release-ios-build`](../release-ios-build/SKILL.md) /
  [`release-notes-generate`](../release-notes-generate/SKILL.md) を正本とする。
- ドキュメントは日本語で書く（Issue/PR と同様、プロジェクトのドキュメント言語規約に従う）。
- docs の構成・配置・ライフサイクルは
  [`documentation.md`](../../rules/flutter-ios/documentation.md) を常に正本とし、本スキルへ
  ルールを写し取らない。
