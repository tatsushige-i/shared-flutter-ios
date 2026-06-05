---
name: release-ios-build
description: バージョンを bump して signed IPA をビルドし、ユーザーの ASC アップロード後に PR を作成する iOS リリースフロー。手順の正本は docs/process/release-workflow.md
argument-hint: "<version>  (例: 1.0.0+2)"
---

# iOS リリースビルドスキル

`pubspec.yaml` のバージョン bump → signed IPA ビルドまでを自動化し、App Store Connect への
アップロード（ユーザーが Transporter で実施）後に PR 作成まで進める。

手順の詳細・選定理由・トラブルシュートは [`docs/process/release-workflow.md`](../../../docs/process/release-workflow.md)
を正本とする。本スキルはそのうち「手動 Xcode フローを省いた最短ルート（手順 1 → 3 → 5-B → 6 → PR）」を
オペレーション化したもので、内容を二重管理しない。

> アプリ固有値（Team ID / Bundle ID 等）は各アプリの `.claude/flutter-ios-profile.md` を参照する。
> 本スキルはそれらを直接埋め込まない。

採用する最短ルート:

1. 手順 1 … バージョン bump
2. 手順 3 … `fvm flutter build ipa --release` で signed IPA 生成（`Generated.xcconfig` も再生成されるため手順 1 の注記対応は不要）
3. 掲載文言ドラフト … リリース対象の変更集合から App Store 掲載文言（最新情報・概要・プロモーション）を提案し、承認後に台帳へ同期（release-workflow.md には無いスキル独自ステップ。方針の正本は [`docs/process/app-store-metadata.md`](../../../docs/process/app-store-metadata.md)）
4. 手順 5-B … ユーザーが Transporter で IPA をアップロード（GUI 操作のため手動）
5. 手順 6 … ユーザーが ASC 側でビルドを配信に紐付け
6. PR 作成 … `git-pr-create` 相当のフローで bump コミットを PR 化
7. 手順 2（タグ）… PR マージ後に `main` 上で `vX.Y.Z+N` タグを切って push

## Steps

### Step 1: 引数バリデーション

- 引数として目標バージョンを `X.Y.Z+N` 形式（例: `1.0.0+2`）で受け取る。必須。
- 形式が不正、または引数が無い場合は現在の `pubspec.yaml` の `version:` を表示し、正しい形式での指定を促して**停止**する（推測で bump しない）。
- 現在値と目標値を比較し、`+N`（build number）が現在値以下の場合は警告する（同一 build number は ASC に拒否されるため）。

### Step 2: 前提チェックとブランチ作成

1. `git status --porcelain` で未コミット変更を確認。変更があれば内容を表示し、続行可否をユーザーに確認する。
2. `git branch --show-current` で現在ブランチを確認。
   - `main` 等のデフォルトブランチ上なら、`chore/bump-version-<version をハイフン化>`（例: `chore/bump-version-1.0.0-2`）ブランチを切る。
   - 既に作業ブランチ上ならそのまま使う。

### Step 3: バージョン bump

- `pubspec.yaml` の `version:` 行を目標バージョンに書き換える。他の行は変更しない。

### Step 4: commit

- `git add pubspec.yaml` のみをステージ（`git add -A` / `git add .` は使わない）。
- コミットメッセージ: `chore: bump version to <version>`
- Co-Authored-By trailer を付与する。

### Step 5: signed IPA ビルド

```bash
fvm flutter build ipa --release
```

- ビルド成功後、出力ログの **Version Number / Build Number** が目標値と一致することを必ず確認する。
  不一致なら原因（`Generated.xcconfig` 未更新等）を [`release-workflow.md`](../../../docs/process/release-workflow.md)
  の Troubleshooting を参照して報告し、PR には進まない。
- 成果物 `build/ios/ipa/*.ipa` のパスとサイズを表示し、`open build/ios/ipa/` で出力先を Finder で開く。

### Step 6: 掲載文言ドラフトの提案と台帳同期

ASC へ文言を入力する前（次の Step 7 の配信準備で使う）に、App Store 掲載文言のドラフトを提案する。
記載方針・文字数上限の正本は [`docs/process/app-store-metadata.md`](../../../docs/process/app-store-metadata.md)。

1. **変更集合の抽出**: 直前のリリースタグ → **現在の `HEAD`（bump コミットを含む今回リリース対象）**
   のマージ済み PR / Closed Issue を収集する。
   - この時点では今回タグが未作成のため、`release-notes-generate` のように `<prev>..<target>` では
     なく **`<直前タグ>..HEAD`** を対象にする（タグは Step 9 で切る）。直前タグは
     `git tag --sort=-v:refname | head -1` で確認し、曖昧ならユーザーに確認する。
   - PR / Issue の分類は [`release-notes-generate`](../release-notes-generate/SKILL.md) の Step 2-3 の
     ロジックを参照する（本スキルで再実装しない）。
2. **ユーザー向け変更のフィルタ**: tech-debt 解消 / CI / ドキュメント / 内部リファクタ等の非ユーザー
   向け変更を除外する（`app-store-metadata.md` の「What's New 記載方針」に準拠）。
3. **文言ドラフト生成**: `app-store-metadata.md` の方針・文字数上限に従って生成する。
   - **このバージョンの最新情報（What's New）**: `■` 見出し・平易・未実装に触れないトーンで生成（必須）。
   - **概要（Description）**: 新機能が主要機能に該当する場合のみ追記差分を提案。
   - **プロモーションテキスト**: 任意で差し替え案。
   - 各フィールドが文字数上限（最新情報・概要 4,000 / プロモーション 170）を超えていないか確認し、
     超過していればその場で警告する。
4. **提示 → 承認**: 生成した全文をユーザーに提示し、承認を得るまで台帳へ書き込まない。
5. **台帳同期**: 承認後、消費アプリの `docs/process/app-store-metadata.md`（ASC スナップショット台帳）
   への追記差分を提示する。コミットはユーザー承認後（`git-pr-create` のフローに委ねるか、bump コミット
   とは分けてユーザー確認のうえ行う）。ASC web UI への入力はユーザー操作のまま（自動化しない）。

> 文言の正本は ASC。本ステップは「ドラフト提案 + 台帳同期」までを担い、ASC への入力はユーザーが行う。

### Step 7: アップロード案内（ユーザー操作）

以下を案内し、**ユーザーのアップロード完了報告を待って停止**する（GUI 操作のため自動化しない）。

1. Transporter アプリを起動（未インストールなら Mac App Store からインストール）
2. `build/ios/ipa/*.ipa` をドラッグ＆ドロップ →「Deliver」
3. ASC の「TestFlight」/「配信」→「すべてのビルド」に反映（処理中→数分〜数十分で完了）

> Export Compliance は `ios/Runner/Info.plist` で `ITSAppUsesNonExemptEncryption = false` 宣言済みのため追加申告不要。
> （暗号化を用いるアプリでは申告内容が変わる。`release-workflow.md` の Export Compliance 節を参照）

ユーザーから「通った」「アップロード成功」等の完了報告があるまで Step 8 に進まない。

### Step 8: PR 作成

ユーザーのアップロード成功報告を受けたら、`git-pr-create` スキルのフローで PR を作成する。

- バージョン bump は特定 Issue に紐付かないリリース運用作業のため、Issue 紐付けは通常なし。
- PR タイトル: `chore: バージョンを <version> に bump`
- PR 本文には bump 内容と「ASC へアップロード済み」を Summary / Test plan に含める。

### Step 9: PR マージ後にタグを切る（ユーザーのマージ報告後）

Step 8 で作成した PR が**マージされた報告をユーザーから受けてから**実行する（未マージの状態では切らない）。

1. 最新の `main` を取得する。

   ```bash
   git checkout main && git pull
   ```

2. `pubspec.yaml` の `version:` をそのまま反映した `vX.Y.Z+N`（build number 含む。例 `v1.0.0+2`）でアノテーション付きタグを切る。

   ```bash
   git tag -a v<version> -m "v<version>"
   git push origin v<version>
   ```

- タグ名は marketing version だけでなく **build number (`+N`) まで含める**。ASC は同一 `X.Y.Z` でもアップロードごとに `+N` を上げるため、ビルド単位で一意に追跡するため。
- タグ push で [`.github/workflows/build.yml`](../../../.github/workflows/build.yml)（`tags: ['v*']`）の `flutter build ios --no-codesign` 検証ビルドがトリガーされる。
- タグは ASC にアップロードしたコミットと対応させるのが目的。merge commit 運用のため bump commit は `main` に保存され、マージ後の `main` に切っても provenance は保たれる。

## 完了後

タグ push（Step 9）まで終えたら、ブランチ削除・`main` の fast-forward 等の後片付けは `git-branch-cleanup` スキルで行う。

## Related

- [`docs/process/release-workflow.md`](../../../docs/process/release-workflow.md) — 手順の正本
- [`docs/process/versioning.md`](../../../docs/process/versioning.md) — version bump 規約
- [`docs/process/app-store-metadata.md`](../../../docs/process/app-store-metadata.md) — 掲載文言の記載方針・文字数上限・台帳（Step 6 の正本）
- [`release-notes-generate`](../release-notes-generate/SKILL.md) — GitHub Release ノート生成（変更集合の分類ロジックを共有）
