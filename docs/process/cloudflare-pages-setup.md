# Cloudflare Pages 配信手順

`web/` ディレクトリの静的ファイル（プライバシーポリシー等）を Cloudflare Pages の
リポジトリ連携で配信するための、ダッシュボード側の設定手順をまとめる。リポジトリ
内にはビルド設定ファイル（`wrangler.toml` 等）を置かず、Cloudflare ダッシュボード
上で設定する方針とする。

App 関連で必要となるサポートメール（プライバシーポリシー連絡先）の Cloudflare
Email Routing 設定も、同一ダッシュボードで完結するため本ドキュメント末尾に併記する。

> **アプリ固有値**: `{{repo}}` / `{{dns_zone}}` / `{{site_domain}}` / `{{support_email}}` /
> `{{forward_email}}` / `{{dkim_selector}}` 等のプレースホルダは、各アプリの
> `.claude/flutter-ios-profile.md` の値に読み替える。本ドキュメントには固有値を埋め込まない。

## 配信対象

- リポジトリ: `{{repo}}`
- publish ディレクトリ: `web`
- production branch: `main`
- ビルドコマンド: なし（静的ファイルのみ）

## UI 注記（Workers vs Pages）

Cloudflare は 2024 年以降 Workers + Static Assets への統合を進めており、
**Workers & Pages** 画面右上の **Create application** ボタンを押下すると、
デフォルトで Workers 作成フロー（`Set up your application` / `Deploy command:
npx wrangler deploy` の画面、リポジトリに `wrangler.toml` 要件あり）に遷移する。
本手順は Pages（リポジトリ無設定方針）で構築するため、必ず以下の
Pages 専用エントリから開始する。

## 初回セットアップ手順

1. Cloudflare ダッシュボードで **Pages 作成フロー** を開く
   - URL を直接叩くのが確実: `https://dash.cloudflare.com/<account-id>/pages/new`
   - 画面タイトルが **「Get started with Pages」** であることを確認する
     （`Set up your application` と出た場合は Workers フローなので戻る）
2. **「Import an existing Git repository」→ Get started** を選択
3. GitHub アカウントを連携し `{{repo}}` リポジトリを選択
4. プロジェクト名を入力（例: アプリ名）
5. ビルド設定を以下のとおり指定する（`Deploy command` 欄は Pages フローには存在しない）
   - Framework preset: `None`
   - Build command: 空欄
   - Build output directory: `web`
   - Root directory: 空欄（リポジトリルート）
   - Production branch: `main`
6. **Save and Deploy** を押下し、初回デプロイの完了を待つ
7. デプロイ完了後、`https://<project>.pages.dev/privacy-policy/` でアクセス可能になる

## カスタムドメインの割り当て

`{{site_domain}}` を割り当てる（`{{dns_zone}}` が Cloudflare DNS 管理下である前提）。

1. Cloudflare Pages プロジェクトの **Custom domains → Set up a custom domain** を開く
2. `{{site_domain}}` を入力
3. DNS は同じ Cloudflare アカウントで管理されているため、CNAME レコードが
   自動で追加される
4. SSL 証明書（Universal SSL）も自動的に発行される
5. 反映後、`{{privacy_policy_url}}` で公開ページに到達できることを確認
6. 確定した URL を README の「ドキュメント」セクションに反映する

## デプロイの確認

- `main` への push で自動的に本番デプロイが走る
- PR ブランチには **プレビューデプロイ**（`https://<branch>.<project>.pages.dev`）が
  自動生成される。レビュー時はこの URL で表示確認できる

## URL の構造

| パス                 | 内容                   |
| -------------------- | ---------------------- |
| `/privacy-policy/`   | プライバシーポリシー   |
| `/support/`          | サポート               |

`web/` 直下にトップページ（`index.html`）を置かない場合、ルート `/` への
アクセスは 404 となる。将来必要になればトップページを追加する。

## サポートメール（Cloudflare Email Routing）

プライバシーポリシー・App Store Connect のサポート連絡先として
`{{support_email}}` を `{{forward_email}}` に転送する設定を行う。
Cloudflare Email Routing は Free プランで利用可能で、転送専用（送信不可）。

### 初回セットアップ手順

Get started ウィザードが「Custom address 作成」「DNS レコード追加」を一連の流れで案内する。

1. Cloudflare ダッシュボードで `{{dns_zone}}` zone を開き、左メニュー
   **Email → Email Routing → Get started** を押下
2. **「Create a custom address」** wizard 画面で次を入力 → **Create and continue**
   - Custom address: `{{support_email}}` のローカル部（右の `@{{dns_zone}}` は固定表示）
   - Action: `Send to an email`
   - Destination: `{{forward_email}}`（未登録なら同画面の **Add destination address**
     から新規追加。Cloudflare から確認メールが送信される）
3. **「Configure your DNS」** 画面で必要な 5 件のレコードが提示されるので、
   **「Add records and enable」** で zone DNS へ自動追加する
   - MX × 3: `route1/2/3.mx.cloudflare.net`（`{{dns_zone}}` 宛のメール受信用）
   - TXT (DKIM): `{{dkim_selector}}._domainkey.{{dns_zone}}`（転送送信時の認証）
   - TXT (SPF): `{{dns_zone}}` の `v=spf1 include:_spf.mx.cloudflare.net ~all`
     （送信元正当性宣言）
4. Destination アドレス（`{{forward_email}}`）に届く Cloudflare からの認証メールの
   リンクを踏み、**Destination addresses** タブで Verified 状態であることを確認する
   （迷惑メールフォルダに入っていることがあるので注意）
5. 任意の外部アドレスから `{{support_email}}` 宛にテスト送信し、
   `{{forward_email}}` で受信できることを確認

### 補足

- Free プランは転送のみ（`{{support_email}}` を **From** として送信する手順は別途必要）。
- 認証メールが届かない場合は Destination アドレスの迷惑メールフォルダを確認
- ルーティングルールは複数 Custom address を追加可能。将来 `support@{{dns_zone}}` 等を
  追加する際は同じ手順で増やせる
