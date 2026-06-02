# shared-flutter-ios

Flutter(iOS) アプリ開発のための共有アセット（アーキテクチャ規範 / iOS リリースフロー /
App Store 審査チェック / docs/process 定型手順）の集約リポジトリ。複数の新規アプリで流用できる
よう、rules / skills / docs を **symlink** で各アプリへ配布する。

汎用 Claude Code 環境アセットの [`shared-claude-code`](https://github.com/tatsushige-i/shared-claude-code) と同じ
symlink/sync 配布モデルを踏襲し、その上に **Flutter/iOS 特化レイヤを積層** する。

## 配布モデル

- **積層**: `shared-claude-code`（汎用）の上に `shared-flutter-ios`（Flutter/iOS 特化）を重ねる。
  両者は独立しており、それぞれが自分の sync skill を所有する
  （汎用は `config-claude-sync`、Flutter/iOS は本リポの `config-flutter-ios-sync`）。
- **per-app プロファイル方式**: アプリ固有値（app_name / bundle_id / team_id / domain /
  support_email 等）は各アプリの `.claude/flutter-ios-profile.md` に集約する。共有 docs / skills は
  固有値を埋め込まず `{{token}}` プレースホルダで参照し、読み手（人間 / Claude）が実行時に
  プロファイルの値へ読み替える。これにより共有ファイルを **pristine（無改変）** に保ち、
  再 sync 時の衝突を避ける。

## 配置前提

`shared-claude-code` / `shared-flutter-ios` / 各アプリ が **ローカル同一階層（同じ親ディレクトリ）**
に clone されていること。symlink の相対パスはこの兄弟配置を前提とする。

```text
~/projects/
├── shared-claude-code/     # 汎用レイヤ
├── shared-flutter-ios/     # 本リポ（Flutter/iOS レイヤ）
├── myapp/                  # 各アプリ
└── otherapp/
```

## Structure

```text
rules/flutter-ios/          # Flutter/iOS 固有の rule（symlink 配布）
├── architecture.md         # アーキテクチャ規範（feature / レイヤ構成）
└── documentation.md        # docs/ ディレクトリ構成規範
skills/                     # skill 定義（symlink 配布）
├── README.md               # skills 索引
├── config-flutter-ios-sync/ # Flutter/iOS rules・skills・docs の差分同期
├── release-roadmap-scaffold/ # 正本 roadmap から 3 Milestone + Issue を一括起票
├── release-ios-build/      # バージョン bump → signed IPA → リリース PR
└── review-appstore-guidelines/ # App Store Review Guidelines 照合
docs/process/               # 開発・運用手順（symlink 配布）
├── release-roadmap.md      # リリース・ロードマップ（Milestone/Issue の正本）
├── release-workflow.md     # Build & Archive 配信フロー（正本）
├── versioning.md           # バージョン番号運用
├── device-install.md       # 開発実機インストール
├── app-icon.md             # アプリアイコン再生成
├── app-privacy.md          # App Privacy 申告（テンプレ）
├── app-store-screenshots.md # スクリーンショット撮影手順
├── app-store-guideline-review.md # 審査ガイドライン照合記録（テンプレ）
└── cloudflare-pages-setup.md # Cloudflare Pages / Email Routing 設定
bootstrap.sh                # 対象アプリへ一括配線する単一エントリポイント
flutter-ios-profile.md.template # 各アプリが埋める固有値テンプレート
.claude/
├── rules/flutter-ios/      # rules/ への symlink（本リポ自身の参照用）
└── skills/                 # skills/ への symlink（本リポ自身の参照用）
```

## Getting Started

### 1. 3 リポを同一階層に clone する

```bash
cd ~/projects
git clone git@github.com:tatsushige-i/shared-claude-code.git   # 汎用レイヤ（未取得なら）
git clone git@github.com:tatsushige-i/shared-flutter-ios.git   # 本リポ
# 対象アプリも同じ ~/projects 配下にあること
```

### 2. 対象アプリへ bootstrap で配線する

対象アプリのルートで bootstrap.sh を実行する（カレントディレクトリ = 対象アプリ）。

```bash
cd ~/projects/myapp
bash ../shared-flutter-ios/bootstrap.sh
```

bootstrap.sh が以下を一括で行う（冪等。既存の symlink / ファイルは上書きしない）。

- `rules/flutter-ios/*.md` → `.claude/rules/flutter-ios/<name>.md`（symlink）
- `skills/<name>` → `.claude/skills/<name>`（symlink）
- `docs/process/*.md` → `docs/process/<name>.md`（symlink）
- `flutter-ios-profile.md.template` → `.claude/flutter-ios-profile.md`（テンプレからコピー）

> 汎用レイヤ（`shared-claude-code`）の配線は別途 `shared-claude-code` 側の手順
> （`/config-claude-sync` 等）で行う。本リポの bootstrap は Flutter/iOS レイヤのみを扱う。

### 3. プロファイルを埋める

`.claude/flutter-ios-profile.md` を開き、`<...>` をアプリの実値（app_name / bundle_id /
team_id / domain 等）に置き換える。共有 docs / skills 内の `{{token}}` はこの値に読み替えられる。

### 4. リリース作業一式を起票する（任意）

対象アプリで `/release-roadmap-scaffold` を実行すると、`docs/process/release-roadmap.md` を正本に
**3 Milestone（MVP 実装完了 / iOS 申請準備完了 / App Store 申請通過）と各 Milestone 配下の汎用
Issue 骨格**が対象 repo に一括起票される。Issue 本文のアプリ固有値は profile から差し込まれ、
再実行しても重複起票されない（冪等）。

> 前提: 対象 repo に type / priority ラベルが存在すること。無ければ shared-claude-code の
> `/config-github-sync` で整備してから実行する。

### 5. 以後の差分同期

shared-flutter-ios 側に rule / skill / doc が追加されたら、対象アプリで
`/config-flutter-ios-sync` を実行して不足分の symlink を補完同期する。

## skill ↔ docs の相対リンクについて

`release-ios-build` 等の skill は `docs/process/...` を `../../../docs/process/...` の相対パスで
参照する。これは **アプリの配置レイアウト**（`.claude/skills/<name>/` と `docs/process/` が
同じアプリツリーに symlink される）でのみ解決する。bootstrap.sh が docs/process も配布するため、
skill 内のリンクは無改変のまま成立する。

> 注意: この相対リンクは **shared-flutter-ios 自身のツリー内では解決しない**
> （本リポでは `.claude/skills/<name>/` の 3 つ上に `docs/process/` が無いため）。
> リンクの動作確認は配線済みのアプリ側で行う。

## 各アプリへ追加で必要な周辺ファイル

docs/process の手順が前提とする以下は各アプリ側に用意する（共有しない、アプリ固有の成果物）。

- `.github/workflows/build.yml`（`vX.Y.Z+N` タグ / push で起動する検証ビルド）
- `Makefile` / `.env.local.sample`（`device-install.md` の `make install-*` 用、必要な場合）
- `web/`（プライバシーポリシー・サポートページ。Cloudflare Pages 配信を行う場合）
- `docs/process/assets/`（スクリーンショット等のアプリ固有アセット）
