---
name: release-roadmap-scaffold
description: docs/process/release-roadmap.md を正本に、対象 repo へリリース用の 3 Milestone と汎用 Issue 骨格を冪等に一括起票する。Issue 本文の固有値は flutter-ios-profile.md から差し込む
---

# Release Roadmap Scaffold Skill

新規 Flutter(iOS) アプリの repo に、App Store リリースまでの **3 Milestone と汎用 Issue 骨格** を
一括起票する。定義の正本は [`docs/process/release-roadmap.md`](../../../docs/process/release-roadmap.md)。
Issue 本文中の `{{token}}` は各アプリの `.claude/flutter-ios-profile.md` の値へ置換する。

`bootstrap.sh` で開発アセットを配線した後に本スキルを実行すると、リリースまでに必要な定型作業が
まとめて起票される。**再実行しても重複起票しない**（既存タイトルと照合してスキップ）。

## Steps

### Step 1: 対象 repo の特定

1. `gh repo view --json nameWithOwner --jq .nameWithOwner` で対象 repo（`<owner>/<repo>`）を取得する。
2. 取得できない（gh 未認証 / repo 外）場合はエラー表示して停止する。
3. 取得した `<owner>/<repo>` をユーザーに提示し、「この repo に起票してよいか」を確認する。

### Step 2: 正本（roadmap）の読み込み

1. `docs/process/release-roadmap.md` を読む。
   - 存在しない場合 → bootstrap.sh / `config-flutter-ios-sync` での配線を案内して停止する。
2. 3 つの Milestone（title / 説明）と、各 Milestone 配下の Issue（title / type ラベル /
   priority ラベル / body）を抽出する。

### Step 3: プロファイルの読み込みと固有値解決

1. `.claude/flutter-ios-profile.md` を読み、`{{token}}` → 実値のマップを作る
   （`app_name` / `bundle_id` / `site_domain` / `privacy_policy_url` / `support_url` /
   `asc_app_id` 等）。
2. プロファイルが無い、または値が未入力（`<...>` のまま）のトークンがある場合:
   - 未解決トークンの一覧を提示し、profile を埋めるよう促す。
   - ユーザーが「未入力のまま進める」と明示した場合のみ、該当トークンは `{{token}}` 文字列を
     残したまま起票する（後で手で埋められるように）。それ以外は停止する。

### Step 4: 必要ラベルの存在確認

1. `gh label list -R <owner>/<repo> --json name --jq '.[].name'` で既存ラベルを取得する。
2. roadmap で使う type ラベル（`chore` / `feature` / `enhancement` / `documentation` / `bug` の
   うち実際に使うもの）と priority ラベル（`priority: high|medium|low`）が揃っているか確認する。
3. 不足ラベルがある場合 → **本スキルではラベルを作らない**。不足分を提示し、shared-claude-code の
   `config-github-sync`（ラベルの正本）で整備してから再実行するよう案内して停止する。

### Step 5: 起票プレビューと確認

実際に作成する前に、以下を一覧で提示してユーザーの承認を得る（GitHub への書き込みを伴うため）。

```text
## 起票プレビュー（対象: <owner>/<repo>）

### 新規作成する Milestone
- M1: MVP 実装完了
- M2: iOS 申請準備完了
- M3: App Store 申請通過
（既存は「既存のためスキップ」と表示）

### 新規作成する Issue（Milestone ごと）
- [M2] アプリアイコン決定・差し替えツール整備  (chore / priority: medium)
- ...
（既存タイトルは「既存のためスキップ」と表示）

未解決トークン: なし / <一覧>

この内容で起票しますか？ 除外したい項目があれば指定してください。
```

- ユーザーが除外を指定したら、その項目を作成対象から外す。

### Step 6: Milestone の冪等起票

1. 既存 Milestone を取得する（open/closed 両方）:

   ```bash
   gh api "repos/<owner>/<repo>/milestones?state=all" --jq '.[] | "\(.number)\t\(.title)"'
   ```

2. roadmap の 3 Milestone それぞれについて:
   - 同名タイトルが既存にあれば、その `number` を使い **作成しない**（スキップ）。
   - 無ければ作成し、返ってきた `number` を控える:

     ```bash
     gh api -X POST "repos/<owner>/<repo>/milestones" \
       -f title="<title>" -f description="<説明>"
     ```

### Step 7: Issue の冪等起票

1. 既存 Issue タイトルを取得する（open/closed 両方、十分な件数）:

   ```bash
   gh issue list -R <owner>/<repo> --state all --limit 300 --json number,title --jq '.[] | "\(.number)\t\(.title)"'
   ```

2. roadmap の各 Issue について:
   - **タイトル一致**（完全一致）の既存 Issue があればスキップする。
   - 無ければ body の `{{token}}` を Step 3 のマップで置換し、所属 Milestone・type/priority ラベルを
     付けて作成する:

     ```bash
     gh issue create -R <owner>/<repo> \
       --title "<title>" \
       --body "<置換済み body>" \
       --label "<type>" --label "<priority>" \
       --milestone "<milestone title>"
     ```

   - body は `docs/process/release-roadmap.md` の共通フォーマット（Overview / Background /
     References / Acceptance Criteria ＋ Generated trailer）で生成する。
3. タイトル比較は前後空白を無視した完全一致で行う（部分一致で誤スキップしない）。

### Step 8: 結果サマリ

```text
## Roadmap Scaffold 完了（<owner>/<repo>）

### Milestones
- 作成: <数>（<title 一覧>）
- スキップ（既存）: <数>

### Issues
- 作成: <数>
- スキップ（既存）: <数>

未解決トークンを残したまま起票した Issue: <数 / なし>
```

- 未解決トークンを残して起票した場合は、該当 Issue 番号と埋めるべきトークンを併記する。

## Notes

- 本スキルは GitHub への書き込み（Milestone / Issue 作成）を行う。必ず Step 5 のプレビューで承認を得てから実行する。
- ラベルの作成・色管理は本スキルの責務ではない（shared-claude-code の `config-github-sync` が正本）。
- アプリ固有の MVP 機能 Issue や QA バグはスコープ外。各アプリで別途起票する。
- Milestone / Issue の定義を変えたいときは正本 `docs/process/release-roadmap.md` を編集する。
