---
name: release-notes-generate
description: 直前のリリースタグから対象タグまでのマージ済み PR を分類し、日本語のリリースノート草案を生成してユーザー承認後に GitHub Release を作成する。
argument-hint: "[<tag>]  (例: v1.0.1+1。省略時は最新タグ)"
---

# リリースノート生成スキル

更新リリースの GitHub Release ノートを、手作業のフォーマット再構築なしで再現する。
直前のリリースタグ → 対象タグの**マージ済み PR / コミット**を抽出し、変更種別ごとに
分類して**日本語のリリースノート草案**を生成、ユーザー承認後に `gh release create`
で公開する。

> アプリ固有値（App Store app id `{{asc_app_id}}` / GitHub `{{repo}}`）は各アプリの
> `.claude/flutter-ios-profile.md` を参照する。本スキルはそれらを直接埋め込まない。

タグの採番（`vX.Y.Z+N`、`+N` は build 番号）は
[`release-ios-build`](../release-ios-build/SKILL.md) で行う前提。本スキルは**タグ push 済み**の
状態から GitHub Release を作るところを担う。

## Steps

### Step 1: 対象タグと直前リリースタグの確定

1. 引数があればそれを**対象タグ**とする。無ければ `git tag --sort=-v:refname | head` で最新の
   `vX.Y.Z+N` 形式タグを対象タグの候補として提示し、確認する（推測で進めない）。
2. 対象タグの**直前のリリースタグ**を決める。`git tag --sort=-v:refname` の並びで対象タグの
   1 つ前を採用する。判断が曖昧な場合（build 番号違いの複数タグ等）はユーザーに確認する。
3. 対象タグに対応する GitHub Release が**既に存在しないか** `gh release view "<tag>"` で確認する。
   既存ならば上書き作成せず、編集（`gh release edit`）するかをユーザーに確認する。

### Step 2: 変更の抽出

1. `git log --merges <prev>..<target> --oneline` でマージ済み PR を一覧化する。
2. 各マージコミットから PR 番号（`Merge pull request #NNN`）と、squash merge の場合は
   タイトル末尾の `(#NNN)` を拾う。PR タイトル / 関連コミットの先頭行を変更内容として使う。
3. 必要に応じて `gh pr view <NNN> --json title,labels` でタイトル・ラベルを補う。

### Step 3: 分類

conventional commit prefix と PR タイトル・ラベルから、以下に振り分ける。
該当が無いセクションは省略する。

| セクション             | 対象 |
| ---------------------- | ---- |
| 🎉 新機能              | `feat` / `feature` ラベル |
| 🐛 修正                | `fix` / `bug` ラベル |
| ✨ 改善                | `enhance` / `enhancement` ラベル |
| 🧹 メンテナンス        | `chore`（ユーザーに影響するもの。スクショ差し替え等） |
| 📚 ドキュメント（内部）| `docs` / ドキュメントのみの変更 |

- **ユーザー向け変更を上に**、内部・ドキュメントを下にまとめる。
- 各行は「日本語の簡潔な説明 (#PR番号)」形式。

### Step 4: リリースノート草案の生成（日本語）

v1.0.0 系リリースノートのフォーマットを踏襲する。テンプレート:

```markdown
## {{app_name}} <version> — <一行サマリ>

<1〜2 文の概要。前リリースからの位置づけ>

### 📱 App Store
<前回リリースノートの App Store URL を踏襲。無ければ https://apps.apple.com/us/app/<slug>/id{{asc_app_id}} を組み立て、slug をユーザーに確認>

### 🐛 修正
- ... (#NNN)

### ✨ 改善
- ... (#NNN)

### 🧹 メンテナンス
- ... (#NNN)

### 📚 ドキュメント（内部）
- ... (#NNN)

**Full Changelog**: https://github.com/{{repo}}/compare/<prev>...<target>
```

- `<version>` はタグから build 番号（`+N`）を除いた SemVer（例: `v1.0.1+1` → `v1.0.1`）を表示に使う。
- タイトルの一行サマリは、その版の主たるユーザー向け変更を端的に表す。

### Step 5: 提示と承認

- 生成した草案を**全文ユーザーに提示**し、公開可否・文面・セクション粒度を確認する。
- GitHub Release の作成は**外部公開**にあたるため、ユーザーの明示承認を得るまで作成しない。

### Step 6: GitHub Release 作成

承認後、草案を一時ファイルに書き出して作成する（タグ実在を検証）:

```bash
gh release create "<target-tag>" \
  --title "<title>" \
  --notes-file <tmpfile> \
  --verify-tag
```

- `--verify-tag` でタグが存在しない場合は作成を中止する（誤タグ防止）。
- 作成後、公開された Release の URL をユーザーに提示する。

## Notes

- 本スキルはタグ・ビルド・審査提出は扱わない。それらは [`release-ios-build`](../release-ios-build/SKILL.md)
  および各アプリの `docs/process/release-guide.md` を正本とする。
- App Store 掲載文言（最新情報・概要・プロモーション）のドラフトは扱わない。それは
  [`release-ios-build`](../release-ios-build/SKILL.md) の掲載文言ステップが担う（変更集合の分類は
  本スキルの Step 2-3 を共有・相互参照する）。
- リリースノートは日本語で書く（Issue/PR と同様、プロジェクトのドキュメント言語規約に従う）。
