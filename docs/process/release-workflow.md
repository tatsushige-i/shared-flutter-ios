# Release Workflow

App Store Connect への配信に用いる Build & Archive フローを定義する。
バージョン番号の bump 規約や iOS 実機への開発用インストール手順は
[`versioning.md`](./versioning.md) / [`device-install.md`](./device-install.md) を参照。

> **アプリ固有値**: `{{team_id}}` / `{{bundle_id}}` 等のプレースホルダは、各アプリの
> `.claude/flutter-ios-profile.md` の値に読み替える。本ドキュメントには固有値を埋め込まない。

## Selected Distribution Method

本プロジェクトは **「手動 Xcode Archive + Transporter (または Xcode Organizer のアップロード)」** を採用する。

選定理由:

- 単独開発フェーズで、リリース頻度は月数回程度を想定。fastlane / CI 署名自動化は導入・保守コストが上回る。
- CI (`.github/workflows/build.yml`) での署名・アップロード自動化は、App Store Connect API Key / 署名証明書 / Provisioning Profile の鍵管理セットアップが必要で、Issue を分離して扱う。
- Xcode 純正フローは Apple の認証・トランスポート仕様変更に最も追随しやすい。

## Distribution Method Comparison

| 観点                | 手動 Xcode Archive (採用) | fastlane (gym + deliver) | CI 完全自動化           |
| ------------------- | ------------------------- | ------------------------ | ----------------------- |
| 初期セットアップ    | ほぼ不要                  | 中（Fastfile 作成）      | 大（API Key / 鍵管理）  |
| 反復作業の手間      | 中（GUI 操作）            | 小                       | 極小（タグ push のみ）  |
| Apple 仕様変更追随  | 容易                      | fastlane の更新待ち      | fastlane / Action 更新  |
| 単独開発との相性    | 高                        | 中                       | 低（オーバースペック）  |

## Prerequisites

- Apple Developer Program (Paid, $99/年) 加入済み
- Team ID: `{{team_id}}`（`ios/Runner.xcodeproj/project.pbxproj` の `DEVELOPMENT_TEAM`）
- Bundle ID: `{{bundle_id}}`
- App Store Connect 上のアプリレコードが作成済み（メタデータは各アプリ側で管理）
- macOS + 最新の Xcode + `fvm` 環境（プロジェクトの `README.md` のセットアップ完了済み）
- アップロード手段として下記いずれかを準備
  - Xcode Organizer（Xcode に同梱）
  - [Transporter](https://apps.apple.com/app/transporter/id1450874784)（Mac App Store から無料インストール）

## Signing 構成（証明書 / Provisioning Profile）

本プロジェクトは **Automatic Signing（Xcode の "Automatically manage signing"）** を採用する。
個別の証明書・Provisioning Profile を手作業で作成・管理する運用は行わない。

### セットアップ手順

```bash
open ios/Runner.xcworkspace
```

Xcode 上で:

1. 左ペインで **Runner** プロジェクト → TARGETS の **Runner** を選択
2. **Signing & Capabilities** タブを開く
3. **"Automatically manage signing"** にチェックを入れる
4. **Team** を Team ID `{{team_id}}` を含むチームに設定する（Prerequisites の値）

上記により Xcode が **Apple Distribution 証明書** と **App Store 用 Provisioning Profile**
を自動生成・更新する。Apple Developer Portal 上で証明書や Profile を手動作成する必要はない。
Bundle ID（`{{bundle_id}}`）に対応する App ID は Apple Developer Program 側に登録済みで
あることが前提（Prerequisites 参照）。

### 手動署名（Manual Signing）について

手動署名が必要になるのは CI 上で署名・アップロードを自動化する場合のみで、本ドキュメント時点の
手動 Xcode フローでは不要。CI 署名自動化は [`## Future Automation`](#future-automation) の
別 Issue 範囲とする。

## Release Steps

リリースビルドを作成して App Store Connect にアップロードする手順。

> **実行ブランチの前提（カット先行）**: リリースは**カット済みのブランチ上**で行う。`release/*`
> ブランチ運用を導入しているアプリは `release/*` ブランチ上で、未導入のアプリはリリース対象を統合した
> `main` 上で実行する。`develop` 等の統合ブランチ上で bump・ビルド・審査提出を行うと、リリースカットが
> 後追いになりブランチ戦略と不整合を起こすため避ける。これにより、ビルド・審査提出の対象コミットが
> 実際にリリースされる内容と一致することが保証され、タグ（手順 2）の provenance も自明になる。

### 1. バージョンを bump する

`pubspec.yaml` の `version:` を更新する（規約は [`versioning.md`](./versioning.md) 参照）。

```yaml
# 例: 1.0.0+1 → 1.0.0+2 （同 version の再アップロード）
# 例: 1.0.0+5 → 1.1.0+1 （マイナーリリース）
version: 1.0.0+2
```

> **重要（Xcode で Archive する場合）**: iOS の `Info.plist` は `$(FLUTTER_BUILD_NAME)` /
> `$(FLUTTER_BUILD_NUMBER)` を参照しており、その実値は `ios/Flutter/Generated.xcconfig` に入る。
> このファイルは `pubspec.yaml` を編集しただけでは更新されず、Flutter コマンド実行時に再生成される。
> そのため **`pubspec.yaml` を bump した後、Xcode で直接 Archive（手順 4）する前に必ず下記いずれかを
> 実行して `Generated.xcconfig` を更新する**こと。忘れると古い build number のまま Archive され、
> 同一 build number の再アップロードとして ASC に拒否される。
>
> ```bash
> fvm flutter pub get                          # 簡易
> # または確実に:
> fvm flutter build ios --config-only --release
> ```
>
> 手順 3 の `fvm flutter build ipa --release` を使う場合は、ビルド時に再生成されるため本対応は不要。

### 2. commit して `vX.Y.Z+N` タグを push する

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.0+2"
git push origin <branch>
```

タグはリリースしたコミット（PR フローではマージ後の `main`）に対して切る。タグ名は
`pubspec.yaml` の `version:` をそのまま反映した **`vX.Y.Z+N`（build number 含む）** とする。
ASC は同一 `X.Y.Z` でもアップロードごとに build number (`+N`) を上げるため、`+N` まで
含めることでビルド単位で一意に追跡できる。

```bash
# PR をマージして main を最新化したのち:
git checkout main && git pull
git tag -a v1.0.0+2 -m "v1.0.0+2"
git push origin v1.0.0+2
```

`vX.Y.Z+N` タグの push で `.github/workflows/build.yml` がトリガーされ、`flutter build ios --no-codesign` の検証ビルドが走る。CI は署名を行わないため、後続のアップロードはローカルから実施する。

### 3. ローカルで signed IPA を生成する

```bash
fvm flutter build ipa --release
```

成果物: `build/ios/ipa/*.ipa`

### 4. Xcode で Archive する（または手順 3 の IPA を流用）

`flutter build ipa` が生成した IPA をそのまま使う場合は本手順をスキップして手順 5 へ進める。Xcode 上で Archive を作りたい場合は以下:

```bash
open ios/Runner.xcworkspace
```

Xcode が開いたら:

1. ツールバーのデバイス選択で **Any iOS Device (arm64)** を選ぶ
2. メニューバー **Product > Archive** を実行
3. 完了後 **Xcode Organizer** が自動で開く

### 5. App Store Connect にアップロードする

#### 方法 A: Xcode Organizer から（手順 4 で Archive した場合）

1. Organizer で対象 Archive を選ぶ
2. 右側 **"Distribute App"** > **"App Store Connect"** > **"Upload"**
3. 署名は自動 (Automatically manage signing) でよい
4. アップロード成功後、App Store Connect の TestFlight ビルド一覧に数分〜数十分で反映される

#### 方法 B: Transporter で（手順 3 の IPA を直接アップロード）

1. Transporter アプリを起動
2. `build/ios/ipa/*.ipa` をドラッグ＆ドロップ
3. **"Deliver"** をクリック
4. アップロード成功後、App Store Connect 側に反映される

### 6. App Store Connect で配信する

- **TestFlight**: 反映されたビルドを内部テスター / 外部テスターに配布する
- **App Store**: 反映されたビルドを App 申請の対象ビルドとして紐付け、審査提出する

メタデータ（カテゴリ・年齢レーティング・サポート URL 等）は各アプリ側で管理している値を入力する。

## 初回アップロード時の確認事項

初めて App Store Connect にビルドをアップロードする際に固有の確認ポイント。2 回目以降は
基本的に再確認不要だが、ビルドが処理完了するまでの挙動は毎回同じ。

### Export Compliance（輸出コンプライアンス）

`ios/Runner/Info.plist` に `ITSAppUsesNonExemptEncryption = false` を宣言しておくと、初回
アップロードでも ASC 側の輸出コンプライアンス質問は自動回避され、追加申告は不要になる。
ただしこれは **非対象暗号化のみを使うアプリ向けの宣言**。HTTPS 標準以外の独自暗号化等を
用いる場合は宣言値・申告内容が変わるため、各アプリの実装に合わせて判断すること。
質問が表示される場合の対処は [`## Troubleshooting`](#troubleshooting) の「Export Compliance の
質問が出る」を参照。

### ビルドが ASC に反映されるまで

1. アップロード成功後、ASC の **「TestFlight」** または **「配信」→「すべてのビルド」**
   にビルドが表示される
2. 表示直後はステータスが **`処理中 (Processing)`** で、処理完了まで数分〜数十分かかる
3. 処理が完了すると、App 申請の対象ビルドとして紐付け可能になる（手順 6 へ）

### 初回特有の注意

- 処理完了後もコンプライアンス情報が未確定だと、ビルドが「コンプライアンス情報が不足して
  います」状態で止まり、申請に紐付けられないことがある。Info.plist で宣言済みでも、ASC 側の
  ビルド一覧でステータスが正常（警告アイコンなし）であることを必ず確認する
- ビルドが一覧に一向に出てこない場合は、Bundle ID とアプリレコードの不一致を疑う
  （[`## Troubleshooting`](#troubleshooting) の「`Invalid Bundle Identifier`」参照）

## Troubleshooting

### `No development team selected` / signing error

Xcode で `ios/Runner.xcworkspace` を開き、Runner target の **Signing & Capabilities** タブで Team が `{{team_id}}` を含むチームに設定されているか確認する。

### `Invalid Bundle Identifier` エラー（アップロード時）

Apple Developer Portal の App ID と App Store Connect 側のアプリレコードがどちらも Bundle ID `{{bundle_id}}` で作成済みであることを確認する。

### 同じ build number の再アップロードを拒否される

`pubspec.yaml` の `+N` を bump する（[`versioning.md`](./versioning.md) の bump 方針参照）。
Xcode で直接 Archive している場合、bump 後に `Generated.xcconfig` を再生成しないと番号が
反映されず同じ事象が再発する（手順 1 の「重要」注記参照）。

### Export Compliance の質問が出る

`ios/Runner/Info.plist` で `ITSAppUsesNonExemptEncryption = false` を宣言済みの想定なら、App Store Connect 側で追加の輸出コンプライアンス申告は不要。質問が出る場合は Info.plist の宣言が破損していないか確認する（独自暗号化を使うアプリでは宣言自体が異なる）。

## Future Automation

下記はそれぞれ別 Issue として切り出して検討する。

- **fastlane 導入**: `gym` で archive、`pilot` で TestFlight、`deliver` で App Store 提出を自動化
- **CI での署名 + アップロード自動化**: `.github/workflows/build.yml` を拡張し、App Store Connect API Key で signed build → upload まで完結

## Related Docs

- [`versioning.md`](./versioning.md) — `pubspec.yaml` のバージョン bump 規約
- [`device-install.md`](./device-install.md) — 開発者実機へのインストール手順
