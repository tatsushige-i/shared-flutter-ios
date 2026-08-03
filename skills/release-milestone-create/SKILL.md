---
name: release-milestone-create
description: 対象バージョンとコア Issue 番号から、milestone の冪等作成・Issue 割当・release-recurring-issues.md の判断基準に基づく定型 Issue 提案までを一貫して行う。
argument-hint: "<version> <issue番号...>  (例: 'v1.17.0 586 93')"
---

# Release Milestone Create Skill

per-minor（`vX.Y.0`）リリースの milestone 作成〜コア Issue 割当〜定型 Issue 起票までを一貫して
行う。運用手順（作成トリガー・命名規約・cut 判断・クローズ）の正本は
[`release-milestone-workflow.md`](../../docs/process/release-milestone-workflow.md)、定型 Issue
の要否判断基準の正本は [`release-recurring-issues.md`](../../docs/process/release-recurring-issues.md)。
本スキルはどちらも編集せず、手順として実行するのみ。

本スキルは**ビルド / タグ / 審査提出 / docs 実更新 / リリースノート生成は扱わない**。それらは
[`release-ios-build`](../release-ios-build/SKILL.md) /
[`release-docs-sync`](../release-docs-sync/SKILL.md) /
[`release-notes-generate`](../release-notes-generate/SKILL.md) を正本とする。

## Steps

### Step 1: 引数パース

1. 引数として `<version>`（`vX.Y.Z` 形式）とコア Issue 番号のリストを受け取る。
2. `<version>` が無い、または `vX.Y.Z` 形式でない場合は推測せず、ユーザーに確認する。
3. Issue 番号が 1 件も無い場合も推測せず、ユーザーに確認する（候補選定自体は会話内で決定済みの
   前提とし、本スキルはそれを行わない）。

### Step 2: 対象 repo の特定

1. `.claude/flutter-ios-profile.md` を読み、`{{repo}}` トークンの実値（`<owner>/<repo>`）を取得する。
2. profile が無い、または `repo` が未入力（`<...>` のまま）の場合は
   `gh repo view --json nameWithOwner --jq .nameWithOwner` にフォールバックする。
3. どちらでも取得できない場合はエラー表示して停止する。

### Step 3: 対象 Issue のラベル確認

各 Issue について `gh issue view <番号> -R <owner>/<repo> --json number,title,state,labels` を取得する。

1. `state` が `OPEN` でない Issue はユーザーに警告し、対象から外すか続行するか確認する。
2. type ラベル（`bug` / `feature` / `enhancement` / `documentation` / `chore`）と priority ラベル
   （`priority: high|medium|low`）がそれぞれ 1 つ以上付いているか確認する。
3. 欠けているものがあれば、どのラベルを付けるかユーザーに確認し
   `gh issue edit <番号> -R <owner>/<repo> --add-label "<label>"` で補う。

### Step 4: Milestone 作成閾値チェック

[`release-milestone-workflow.md`](../../docs/process/release-milestone-workflow.md) の作成
トリガー表に基づき、対象 Issue 数を評価する。

- 3 件以上 → そのまま Step 5 へ進む。
- 1〜2 件 → 「Issue 数が少ないため Milestone を作らず直接 PR の方が適切ではないか」と警告を
  提示し、続行するか確認する。ユーザーが続行を選べば Step 5 へ進む（強制停止はしない）。

### Step 5: Milestone の冪等作成

1. 既存 Milestone を取得する（open/closed 両方）:

   ```bash
   gh api "repos/<owner>/<repo>/milestones?state=all" --jq '.[] | "\(.number)\t\(.title)"'
   ```

2. `<version>` と完全一致するタイトルが既に存在すれば、その `number` を使い**作成しない**
   （スキップ）。
3. 無ければ作成し、返ってきた `number` を控える:

   ```bash
   gh api -X POST "repos/<owner>/<repo>/milestones" -f title="<version>"
   ```

### Step 6: 対象 Issue を Milestone に割当

各コア Issue について:

```bash
gh issue edit <番号> -R <owner>/<repo> --milestone "<version>"
```

既に同じ Milestone が割り当て済みの Issue はそのままでよい（`gh issue edit` は冪等）。

### Step 7: 定型 Issue 提案

1. [`release-recurring-issues.md`](../../docs/process/release-recurring-issues.md) の判断
   テーブルを読み込む。
2. Step 6 で Milestone に割り当てた各 Issue のラベル・内容から、3 種
   （docs 最新化 / ストア説明文最新化 / スクショ撮り直し）を**独立に**判定する。
3. 判定結果を以下の形式で提示し、ユーザーの承認を得る:

   ```text
   ## 定型 Issue の提案（milestone: <version>）

   - docs 最新化: 要 / 不要（理由: ...）
   - ストア説明文最新化: 要 / 不要（理由: ...）
   - スクショ撮り直し: 要 / 不要（理由: ...）

   該当する定型 Issue は 1 本にまとめますか、個別に作成しますか？
   ```

4. すべて「不要」であれば、その旨を伝えて Step 9 へ進む（Step 8 はスキップ）。

**Wait for user approval before proceeding to Step 8.** ユーザーが判定や統合可否を変更した場合は
その指示に従う。

### Step 8: 定型 Issue の作成

承認された内容で、対象それぞれ（または統合した 1 本）を作成する:

```bash
gh issue create -R <owner>/<repo> \
  --title "<release-recurring-issues.md のタイトル雛形から生成>" \
  --body "<本文>" \
  --label "<type>" --label "<priority>" \
  --milestone "<version>"
```

- タイトル雛形・参照リンクは [`release-recurring-issues.md`](../../docs/process/release-recurring-issues.md)
  の判断テーブルに従う。
- 複数種を 1 本に統合する場合は、本文にどの観点（docs / ストア説明文 / スクショ）を含むかを
  明記する。

### Step 9: 結果サマリ

```text
## Milestone 作成完了（<owner>/<repo>）

- Milestone: <version>（新規作成 / 既存を使用）
- 割り当てたコア Issue: <番号一覧>
- 作成した定型 Issue: <番号・タイトル一覧 / なし>
```

## Notes

- 本スキルは GitHub への書き込み（Milestone 作成・Issue 編集・Issue 作成）を行う。Step 4（閾値）・
  Step 7〜8（定型 Issue）は必ずユーザー確認を経てから実行する。
- コア Issue の候補選定（何を次リリースに載せるか）自体は本スキルの責務ではない。会話内で
  決定済みの前提とする。
- ビルド・タグ・審査提出・docs 実更新・リリースノート生成・Milestone クローズは本スキルの
  スコープ外。それぞれ既存スキル、または
  [`release-milestone-workflow.md`](../../docs/process/release-milestone-workflow.md) の運用
  手順に従う。
