# Real Device Installation

iOS シミュレータでは検証できない実機特有の挙動（ジェスチャー、パフォーマンス、ストレージ、バックグラウンド挙動など）を確認するため、開発者の手元の iPhone へアプリをインストールする手順を定義する。

> **アプリ固有値**: `{{app_name}}` / `{{bundle_id}}` 等のプレースホルダは、各アプリの
> `.claude/flutter-ios-profile.md` の値に読み替える。

## Selected Distribution Method

本プロジェクトは **「開発用署名で直接インストール（Apple Developer Program Paid 加入）」** を採用する。

選定理由:

- MVP リリース（App Store 申請）には Apple Developer Program Paid 加入がどのみち必須。
- Paid 加入であれば実機にインストールしたアプリが 1 年間有効（Free Apple ID は 7 日で失効）。
- 将来 TestFlight に移行する際、本構成の証明書環境をそのまま流用できる。
- 現時点では開発者 1 人での実機検証が目的のため、Ad Hoc / TestFlight はオーバースペック。

## Distribution Method Comparison

| 観点                    | 開発用署名 (Paid) | Ad Hoc                  | TestFlight                |
| ----------------------- | ----------------- | ----------------------- | ------------------------- |
| Apple Developer Program | 必須              | 必須                    | 必須                      |
| 配布範囲                | 自分の端末        | UDID 登録端末（最大100） | 内部100名 / 外部10,000名 |
| アプリ有効期限          | 1 年              | 1 年                    | 90 日（ビルド毎）         |
| Apple 審査              | 不要              | 不要                    | 必要（外部配布時）        |
| 主な用途                | 開発者自身の検証  | クローズドテスト        | β 公開                    |

## Prerequisites

- Apple Developer Program (Paid, $99/年) に加入済みであること。
- 本リポジトリの現在値:
  - Team ID: Xcode の Signing & Capabilities タブで `{{app_name}} (Personal Team / 加入チーム名)` として選択されているもの。`ios/Runner.xcodeproj/project.pbxproj` の `DEVELOPMENT_TEAM`（= `{{team_id}}`）と一致する。
  - Bundle ID: `{{bundle_id}}`（変更不要。App Store 公開後の変更不可のため固定）。
- macOS + 最新の Xcode + `fvm` 環境（プロジェクトの `README.md` のセットアップ完了済み）。
- USB ケーブルで Mac に接続できる iPhone（iOS 16 以降を推奨）。

## Installation Steps

iPhone を Mac に USB 接続する。初回接続時は iPhone 側で「このコンピュータを信頼しますか？」のダイアログが出るので「信頼」を選ぶ。

iPhone 側で Developer Mode を有効化する（iOS 16 以降は必須）。

```text
iPhone Settings > Privacy & Security > Developer Mode > ON
（端末が再起動される）
```

Mac 側で device id を確認する。

```bash
fvm flutter devices
```

出力例:

```text
iPhone 17 Pro (mobile) • <device-id> • ios • iOS 26.5
```

device id を `.env.local` に記録する（`.env.local.sample` をコピーして作成）。

```bash
cp .env.local.sample .env.local
# .env.local を編集して DEVICE_17PRO / DEVICE_SE3 等を設定する
```

以後は `make` コマンドでインストールできる（詳細は後述）。

初回起動時、iPhone 側で「信頼されていない開発元」エラーが出てアプリが起動しない場合は、開発元の証明書を手動で信頼する。

```text
iPhone Settings > General > VPN & Device Management
> Developer App セクションの自分の Apple ID を選択
> 「Apple Development: <自分のメール>」を信頼
```

信頼後、ホーム画面のアプリアイコンを再度タップすると起動する。

## Installation via Make（ワイヤレス対応機）

`.env.local` に device id を設定しておくと、毎回 UDID を調べずに `make` コマンド1つで配信できる。ワイヤレス接続に対応した機種は USB 不要。

```bash
# .env.local.sample をコピーして device id を記入する（初回のみ）
cp .env.local.sample .env.local
```

`.env.local` の記入例:

```text
DEVICE_17PRO=<iPhone 17 Pro の device id>
DEVICE_SE3=<iPhone SE3 の device id>
```

```bash
make install-17pro
```

> 上記の `DEVICE_*` 名や `make install-*` ターゲットは一例。実際のターゲット端末に合わせて
> 各アプリの `Makefile` / `.env.local.sample` で定義する。

## Installation via Xcode（xcodebuild 非対応機）

一部の機種は `xcodebuild` コマンドでのインストールに対応していないため、Xcode GUI を使う。USB 接続必須。

```bash
open ios/Runner.xcworkspace
```

Xcode が開いたら:

1. ツールバーのデバイス選択で対象 iPhone を選ぶ
2. **▶ Run** を押す（Build Configuration は Release に設定済み）
3. インストール完了後 ■ で停止する

## Troubleshooting

**`No development team selected` / signing error**

`ios/Runner.xcodeproj/project.pbxproj` の `DEVELOPMENT_TEAM` が正しく設定されているか確認する。

```bash
grep DEVELOPMENT_TEAM ios/Runner.xcodeproj/project.pbxproj
```

未設定であれば、Xcode で `ios/Runner.xcworkspace` を開き、Runner target の Signing & Capabilities タブで Team を選択する。

**`Untrusted Developer` でアプリが起動できない**

Installation Steps の証明書信頼手順を再実行する。Apple Developer Program の年次更新が切れていると証明書も失効するので、その場合は更新後に再ビルドする。

**`Could not launch <app>` / アプリインストールはされるが起動しない**

Developer Mode が無効になっている可能性がある（iOS アップデート後などに自動で無効化されることがある）。iPhone 側で再度有効化する。

**`fvm flutter devices` に iPhone が出てこない**

- USB ケーブルがデータ通信対応か確認する（充電専用ケーブルでは認識されない）。
- iPhone 側の「このコンピュータを信頼」ダイアログを取りこぼしていないか確認する。
- Xcode を一度起動して `Window > Devices and Simulators` で iPhone が見えるか確認する（Xcode 側でデバイスペアリングが完了していないと flutter からも見えない）。

## Future TestFlight Migration

以下の状況になったら TestFlight への移行を検討する。

- 開発者以外のテスターに配布したくなった（家族・友人による β テスト等）。
- App Store 申請前のリリース候補ビルドを継続的に配布したい。

移行時の追加作業の概要:

- App Store Connect でアプリを新規登録する（Bundle ID `{{bundle_id}}` を流用）。
- `fvm flutter build ipa --release` でアーカイブを生成し、Transporter または Xcode から App Store Connect へアップロードする。詳細手順は [`release-workflow.md`](./release-workflow.md) を参照。
- TestFlight 上で内部テスター / 外部テスターを登録する。外部テスター配布は Apple の審査を経由する。

本構成の開発用署名 / Bundle ID / Team ID はそのまま TestFlight ビルドに流用できる。CI/CD（`.github/workflows/build.yml`）での署名自動化は別 Issue で扱う。
