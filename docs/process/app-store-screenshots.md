# App Store Screenshots

App Store 提出用スクリーンショットの必須サイズ・撮影手順・保管場所をまとめた運用ドキュメント。
リリース／再申請のたびに本手順で撮り直す。

> 撮影対象画面・ファイル名は各アプリで定義する。以下の表は記入例。

## 必須サイズ

正本は Apple 公式の [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)。
iPhone 専用アプリの場合は iPhone 6.9″ Display のみを対象とすれば足りる。

| 対象             | 向き  | ピクセルサイズ            |
| ---------------- | ----- | ------------------------- |
| iPhone 6.9″ Display | 縦    | **1320 × 2868**（採用）   |
| 〃（許容代替）   | 縦    | 1290 × 2796 / 1260 × 2736 |

- 正本は常に上記 Apple 公式ページで最新サイズを確認する（仕様は改訂される）
- 枚数: 1〜10 枚（App Store は 3〜5 枚を推奨）
- 形式: `.png` / `.jpg`
- 6.9″ を入れておけば、Apple 側で他サイズに自動縮小される

## 撮影対象画面（記入例）

掲載順を意識し、価値訴求の強い順に並べる。

| #  | ファイル                  | 画面                         | 訴求点                       |
| -- | ------------------------- | ---------------------------- | ---------------------------- |
| 01 | `01-<screen>.png`         | アプリの全体像が伝わる画面   | アプリ全体像                 |
| 02 | `02-<screen>.png`         | 中核機能の画面               | 中核機能                     |
| 03 | `03-<screen>.png`         | 差別化機能の画面             | 差別化機能                   |
| 04 | `04-<screen>.png`         | 補助機能の画面               | 補助機能                     |

## 保管場所

- `docs/process/assets/app-store-screenshots/` 配下に上表のファイル名で置く
- 本ファイル（`process/`）が参照するアセットなので、`documentation.md` の規約どおり同階層の `assets/` 配下に配置する

> スクリーンショット画像自体は各アプリ固有の成果物。共有リポジトリ（shared-flutter-ios）には
> 含めず、各アプリの `docs/process/assets/` 配下にコミットする。

## 撮影手順

6.9″ クラスのシミュレータ（**iPhone 17 Pro Max** 等, 1320×2868）を使う。

1. **アプリ起動**

   ```sh
   fvm flutter run -d "iPhone 17 Pro Max"
   ```

2. **サンプルデータ投入**: シミュレータ上で現実的なデータを手入力し、各掲載画面が映える状態にする

3. **ステータスバーをクリーン化**（App Store 体裁。`<udid>` は対象シミュレータの UDID）

   ```sh
   xcrun simctl status_bar <udid> override \
     --time "9:41" --batteryState charged --batteryLevel 100 \
     --cellularBars 4 --wifiBars 3
   ```

4. **各画面を撮影**

   ```sh
   xcrun simctl io <udid> screenshot docs/process/assets/app-store-screenshots/01-<screen>.png
   # 02〜 も同様に画面遷移しながら撮影
   ```

5. **サイズ検証**（必ず 1320×2868 であることを確認）

   ```sh
   sips -g pixelWidth -g pixelHeight docs/process/assets/app-store-screenshots/*.png
   ```

6. **後片付け**（任意）

   ```sh
   xcrun simctl status_bar <udid> clear
   ```

## 既知の落とし穴

- **`flutter run` が iOS シミュレータを destination 解決できないことがある**
  - 症状: `Unable to find a destination matching the provided destination specifier`。`flutter run` 経由の xcodebuild がシミュレータを候補に出さず、実機・Mac のみになる。
  - 切り分け: `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -showdestinations` を直接叩いてシミュレータが列挙されるか確認する。
  - 背景: Flutter と Xcode の新メジャーバージョンの組み合わせで発生することがある（Flutter 側の対応待ち）。シミュレータ撮影が必要な場合は対応版へ更新する。

## Related Docs

- [`release-workflow.md`](./release-workflow.md) — Build & Archive 配信手順
