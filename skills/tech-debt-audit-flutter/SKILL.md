---
name: tech-debt-audit-flutter
description: Flutter / Dart プロジェクトの技術的負債を19カテゴリ並列調査し、優先度付きレポートを生成する
---

# Flutter 技術的負債監査スキル

Flutter / Dart プロジェクトの技術的負債を監査する。共通の `rules/tech-debt-checklist.md`
（`.claude/rules/shared/tech-debt-checklist.md` として symlink 配布）の各カテゴリを Flutter /
Dart 文脈で調査する手順に加え、Flutter / Dart 固有のチェック（Widget 肥大化・状態管理の
一貫性・生成コードの鮮度など）を、カテゴリごとに `tech-debt-auditor` subagent を1件ずつ並列
起動して調査する。ファイルパス・行番号・改善提案付きの優先度別レポートを出力する。

## Steps

### Step 1: プロジェクト検出

1. リポジトリルートに `pubspec.yaml` があり、`flutter:` ブロックまたは `dependencies:` 配下に
   `flutter` SDK 制約があることを確認して Flutter / Dart プロジェクトであることを検証する
   - `pubspec.yaml` が存在しない → 「エラー: Dart プロジェクトが見つかりません
     （pubspec.yaml がありません）。」と表示して終了
   - `pubspec.yaml` はあるが `flutter` 依存がない → 「警告: 純粋な Dart パッケージのようです。
     Flutter 固有チェック（Widget / 状態管理 / ナビゲーション）はスキップします。」と表示して
     続行
2. アプリケーションのエントリポイント `lib/main.dart` の有無を確認する（アプリケーション
   プロジェクトの場合。`main.dart` を持たないライブラリパッケージも監査対象として有効）
3. 以降のコマンドで参照する Flutter CLI プレフィックスを判定する:
   - `.fvmrc` または `.fvm/` が存在する → `fvm flutter ...` / `fvm dart ...`
   - それ以外 → `flutter ...` / `dart ...`
4. プロジェクト構造を把握するため以下を走査する:
   - `lib/` 直下のトップレベルディレクトリ一覧（例: `app/`, `core/`, `features/`）
   - 各 feature ディレクトリがクリーンアーキテクチャ層構成（`presentation/` /
     `application/` / `domain/` / `data/`）を採用しているか、別構成かを確認
   - `test/`, `integration_test/`, `analysis_options.yaml`, `.github/workflows/` の有無と形状
   - 走査対象の `.dart` ソースファイル数（`node_modules` 相当なし。ビルド出力・生成物
     `*.g.dart` / `*.freezed.dart` を除く）をカウントする — Step 3 レポートの
     `Files scanned` になる。subagent はプロジェクト全体を見渡せないため、この集計は
     main thread がここで一度だけ行う
5. 上記から簡潔な**プロジェクト構造サマリー**を作成する（Step 2 の全 subagent に
   プロジェクトコンテキストとして渡す）。数行程度に収める:

   ```text
   Project: <pubspec.yaml の name>（Flutter / Dart）
   Layout: lib/ 配下のトップレベルディレクトリ（app/, core/, features/ など）
   Feature 層構成: presentation/application/domain/data の有無（feature ごと）
   Flutter CLI prefix: fvm flutter | flutter
   Files scanned: <.dart ソースファイル数>
   ```

### Step 2: 並列カテゴリ調査

`rules/tech-debt-checklist.md` の共通12カテゴリ（Flutter / Dart 文脈で調査）と、Flutter /
Dart 固有7カテゴリの、計19カテゴリを `tech-debt-auditor` subagent で並列調査する。各カテゴリは
独立しているため、全 subagent をまとめて起動する。

#### 共通カテゴリ

##### Code Duplication

- 画面間で繰り返される Widget ツリーパターン（類似の `Scaffold` + `AppBar` + `ListView`
  骨格、繰り返される `Padding` / `Container` ネストなど）を検索する
- feature 間で重複するデータ取得処理・Repository 実装がないか確認する
- `lib/core/` と `features/*/` にまたがる重複ユーティリティ関数を探す
- 共有 value object が不足していることを示唆する、重複した `freezed` モデルフィールドを
  フラグする

##### Architecture & Layering

- feature-first / クリーンアーキテクチャ層構成を採用している場合、レイヤ境界違反を確認する:
  - `presentation/` が `data/` を直接 import している（`application/` 経由であるべき）
  - `domain/` が Flutter / Riverpod / Drift 等フレームワークを import している
  - `application/` が `presentation/` の Widget を import している
- feature 間の直接 import（`features/foo/` が `features/bar/` を import）を探す —
  共有すべきコードは `core/` に置くべき
- 循環 import チェーンを検出する（疑わしい箇所の手動 grep、または設定済みなら
  `dart run import_sorter` / `dart run dependency_validator`）
- `application/`（Riverpod ノーティファイア）に属すべき状態ロジックが `StatefulWidget` の
  setState ブロックに漏れ出していないか確認する

##### Error Handling

- 失敗しうる `await` 呼び出し（I/O、ネットワーク、プラグイン呼び出し）が `try / catch` の
  外にないか検索する
- 空の `catch` ブロック（`catch (_) {}`）や、スタックトレースを握りつぶす過度に広い
  `catch (e)` を探す
- `Future` / `Stream` の消費側で `onError` の欠落や、失敗を無視する `unawaited()` 呼び出しを
  確認する
- UI 層で `AsyncValue` 消費側（`ref.watch(...)`）の `error` 分岐欠落（error を握りつぶす
  `when` / `whenData`）を確認する
- 型付きエラークラスであるべき `throw Exception('...')` 文字列を検索する

##### Type Safety

- `.dart` ファイル中の `dynamic` パラメータ / 戻り値型と、値の入れ物として使われる
  `Object?` を検索する
- null 安全性を回避する null-assertion 演算子（`!`）の使用をフラグする
- 実行時に失敗しうる `as` キャストを検索する
- 境界で `freezed` モデルにパースされず複数レイヤを跨いで渡される `Map<String, dynamic>`
  を探す
- 初期化式の型が自明でない `var` 宣言の型注釈欠落をフラグする

##### Dead Code

- `<flutter-prefix> analyze` を実行し `unused_element`, `unused_import`,
  `unused_local_variable`, `dead_code` 診断を収集する
- コメントアウトされたコードブロック（コードらしき3行以上の連続コメント）を検索する
- 再 import されない `export` 文を確認する
- 放棄された作業を示唆しうる、現行スプリントより古い TODO / FIXME / XXX コメントを特定する

##### Constants & Configuration

- `build()` メソッド内のマジックナンバー（テーマトークンや名前付き定数であるべき生の
  padding / radius / duration リテラル）を検索する
- ソースファイルに埋め込まれたハードコードされた URL、API ベースパス、feature-flag
  文字列を探す
- `Widget` コンストラクタで `const` にできる箇所（analyzer ルール
  `prefer_const_constructors`）を確認する
- ファイルをまたいで重複する `Duration` / `EdgeInsets` / color リテラル定義を特定する

##### Component / Module Size

- **300行**を超える `.dart` ファイル（生成物 `*.g.dart` / `*.freezed.dart` を除く）を
  特定する
- **100行**を超える `build()` メソッドをフラグする — `extract widget` リファクタの候補
- **4階層以上**ネストする Widget ツリーをフラグする
- 無関係な関心事が混在する、public メソッドが約10個を超えるクラスをフラグする

##### Dependency Management

- `pubspec.yaml` の依存関係を `lib/` の実際の import と突き合わせ、未使用パッケージを
  見つける
- `<flutter-prefix> pub outdated` を実行し、メジャーバージョンが複数世代遅れている
  パッケージをフラグする
- 重複する機能を提供するパッケージ（例: HTTP クライアント2種、日付ライブラリ2種、
  モックフレームワーク2種）を探す
- バージョン固定を回避する git-ref / path 依存（`git:` / `path:` エントリ）をフラグする
- `test/`、`build_runner` 設定、CI から実際に参照されていない `dev_dependencies` エントリを
  確認する

##### Testing

- `<flutter-prefix> test --coverage` を実行（または未実行を記録）し `coverage/lcov.info`
  の未カバレッジファイルを確認する
- `lib/features/*/` のファイル数と `test/features/*/` のファイル数を比較し、feature 単位の
  カバレッジギャップを見積もる
- テストを欠くクリティカルパス（認証、決済、永続化、同期）を特定する
- インメモリ実装ではなく Repository をモックしているテスト（結合バグを隠蔽しうる）を探す
- 実際の `DateTime.now()`、`Random()`、注入なしのファイルシステム状態に依存するテストを
  フラグする

##### Accessibility

- 非インタラクティブなコンテンツを `Semantics` ラベルなしで包む `GestureDetector` /
  `InkWell` を検索する
- `Image`、`Icon`、`CircleAvatar` の `semanticLabel` / `semanticsLabel` 欠落を確認する
- `tooltip` のない `IconButton` / `FloatingActionButton` を探す
- 色のみのシグナル（アイコンやラベルを伴わない赤 / 緑テキスト）をフラグする
- `labelText` / `hintText` セマンティクスが欠落した `TextField` を確認する

##### Performance

- `application/` でメモ化すべき、`build()` 内の高コストな計算（ソート、JSON パース、
  正規表現コンパイル）を探す
- 大きなハードコード children リストを持つ `ListView(...)`（可能なら `itemExtent` 付き
  `ListView.builder` であるべき）をフラグする
- 大きなサブツリーを再構築するホットパス（アニメーション tick、スクロールリスナー）での
  `setState` 呼び出しを検索する
- 作成されても破棄されない `StreamSubscription`、`TextEditingController`、
  `AnimationController`、`FocusNode` を特定する
- Widget ツリーの差分検出最適化を無効化する、`const` 欠落の Widget コンストラクタを探す

##### Security

- 未検証のソースから取得する git / URL / path 依存が `pubspec.yaml` にないか確認する
- ソースに埋め込まれたシークレット、API キー、トークン（`String _apiKey = '...'`）を
  検索する
- 機微データに `flutter_secure_storage` / Keychain ではなく `SharedPreferences` を使用して
  いないかフラグする
- SQL、ファイルパス、プラットフォームチャンネルに直接渡される未検証の外部入力を探す
- ネットワーク呼び出しにハードコードされた `http://`（非 TLS）URL を確認する

#### Flutter / Dart 固有カテゴリ

##### Widget / build Method Bloat

- 100行を超える `build()` メソッドを列挙する
- 中間 `extract widget` リファクタなしに4階層以上ネストする Widget ツリーを特定する
- レイアウト・データ変換・イベントハンドリングが単一の `build()` に混在する画面をフラグする

##### State Management Consistency

- 同一プロジェクト内での状態管理手法の混在（`setState` + Riverpod + Provider + Bloc）を
  検出する
- Riverpod を採用しているプロジェクトで、`@riverpod` 生成プロバイダーであるべき手書きの
  `Provider(...)` / `StateProvider(...)` をフラグする
- Riverpod を採用しているプロジェクトで、ノーティファイアに置くべきビジネス状態を保持する
  `StatefulWidget` をフラグする
- 状態管理レイヤを迂回するグローバルなミュータブルシングルトン
  （`final foo = Foo();` のトップレベル定義）を探す

##### Async / Stream Handling

- Riverpod `AsyncValue` の方が一貫性があるプロジェクトでの `FutureBuilder` /
  `StreamBuilder` 使用を特定する
- キャンセルされない `StreamSubscription`（`initState` で作成され `dispose` で
  `cancel()` されない）をフラグする
- 破棄されない `TextEditingController` / `AnimationController` / `FocusNode` /
  `ScrollController` をフラグする
- Widget 内の `Timer` と `Future.delayed` 使用について、dispose 時のキャンセル漏れを
  確認する

##### Generated Code Freshness

- `<flutter-prefix> dart run build_runner build --delete-conflicting-outputs` を実行し
  `git status` を確認する
- `*.g.dart` または `*.freezed.dart` に変更が生じた場合 → コミット済みの生成コードが
  陳腐化しており再生成が必要
- プロジェクトの規約に従い生成ファイルがコミットされ、ignore されていないことを確認する

##### Navigation Conventions

- `go_router` を採用しているプロジェクトで、`context.push` / `context.go` /
  `context.pop` を使うべき箇所で直接 `Navigator.push` / `Navigator.pop` /
  `Navigator.of(context)` を使っていないか検索する
- ルート定義が（例: `lib/app/router.dart` に）集約され、画面に散らばっていないか確認する
- 画面内で手動パースされ、ルート宣言側に定義されていないディープリンクパラメータを
  フラグする

##### Layer Boundary Audit (project-specific)

- プロジェクトの `CLAUDE.md` または `.claude/rules/architecture.md` がレイヤ規約を
  定義している場合、各 `lib/features/<feature>/` ディレクトリが規定構成に一致するか
  検証する
- 規約がフルセットを要求する箇所でレイヤが欠落している feature（例: `presentation/`
  のみで `application/` がない）をフラグする
- `core/` が雑多な置き場になっていないか確認する — 単一 feature でのみ使われる
  ユーティリティはその feature 内に置くべき

##### Build / CI Coverage Gaps

- `.github/workflows/*.yml` を調べ、PR でどのチェックが実行されるか確認する
- 監査上重要とみなす、欠落している CI ステップをフラグする:
  - `<flutter-prefix> format --output=none --set-exit-code .`（または `dart format`）
  - カバレッジレポーター付きの `<flutter-prefix> test --coverage`
  - 非ブロッキングの advisory としての
    `<flutter-prefix> pub outdated --exit-if-no-update-needed=false`
  - 生成コード鮮度チェック（`build_runner build` + `git diff --exit-code`）
- プロジェクトに当該チェック欠落による直近の regression がない限り LOW 優先度として扱う

#### subagent の起動

19件の `Agent` 呼び出しを**1メッセージにまとめて**発行し、並列実行する
（`review-team-run` の前例に倣う）。全呼び出しで `subagent_type` に `tech-debt-auditor` を
指定する。各呼び出しのプロンプトには以下を渡す:

1. **カテゴリ** — 上記の `#####` 見出しと**完全一致**するカテゴリ名（例: `Code Duplication`、
   `Component / Module Size`、`Widget / build Method Bloat`）。この文字列は各 finding の
   `category` フィールドとして返され、Step 3 のサマリー表集計のキーになる —
   言い換え・省略しないこと
2. **調査手順** — 上記リストの該当カテゴリの bullet を原文のまま
3. **プロジェクトコンテキスト** — Step 1 で作成したプロジェクト構造サマリー

19件すべての応答を待ってから続行する。各 subagent の finding-block（または
`No findings.`）をカテゴリ別に収集し、Step 3 で用いる。

### Step 3: レポート生成

19件の subagent が返した finding-block を1つのレポートに集約する:

1. **完了確認**: 19件すべての subagent 呼び出しが返ったか確認する。エラー・タイムアウト・
   `No findings.` でも整形された finding-block でもない出力を返した呼び出しは
   「findings なし」として扱わず、そのカテゴリのサマリー表の行を `-`/件数ではなく
   `incomplete` とする
2. 各 subagent の finding-block をパースする。`No findings.` を返した subagent は
   何も追加しない
3. **重複排除**: 複数の subagent が同一 `file:line` かつ同一内容を報告した場合
   （カテゴリの調査手順が重なる場合に起こりうる。例: `Error Handling` と
   `Async / Stream Handling`）、1件に統合し関与カテゴリをすべて列挙する
   （例: `**[Error Handling, Async / Stream Handling]**`）
4. `priority`（HIGH/MEDIUM/LOW）でバケット分けする。各 subagent が既に割り当てた
   優先度をそのまま使用し、再判定しない
5. HIGH → MEDIUM → LOW の順で、3バケット全体を通した連番 1..N を採番する
   （カテゴリ単位の番号ではない）
6. 各 finding の `category` / `recommendation` フィールドをテンプレートの
   `**[<Category>]**` / `**Recommendation:**` にマッピングする
7. サマリー表の `**Total**` 行が N と一致するか確認する。一致しない場合は手順2〜5を
   再確認してからレポートを提示する

以下の形式で監査結果を出力する:

```text
## 技術的負債監査レポート — Flutter

Project: <pubspec.yaml の name>
Scan date: <YYYY-MM-DD>
Files scanned: <count>

### HIGH Priority (<count> items)

1. **[<Category>]** `path/to/file.dart:L<line>`
   **Finding:** <問題の内容>
   **Recommendation:** <修正方法>

### MEDIUM Priority (<count> items)
...

### LOW Priority (<count> items)
...

### Summary

| Category | HIGH | MEDIUM | LOW |
|---|---|---|---|
| Code Duplication | - | - | - |
| Architecture & Layering | - | - | - |
| Error Handling | - | - | - |
| Type Safety | - | - | - |
| Dead Code | - | - | - |
| Constants & Configuration | - | - | - |
| Component / Module Size | - | - | - |
| Dependency Management | - | - | - |
| Testing | - | - | - |
| Accessibility | - | - | - |
| Performance | - | - | - |
| Security | - | - | - |
| Widget / build Method Bloat | - | - | - |
| State Management Consistency | - | - | - |
| Async / Stream Handling | - | - | - |
| Generated Code Freshness | - | - | - |
| Navigation Conventions | - | - | - |
| Layer Boundary Audit (project-specific) | - | - | - |
| Build / CI Coverage Gaps | - | - | - |
| **Total** | **X** | **X** | **X** |
```

#### Priority Criteria

優先度は `tech-debt-auditor` subagent が調査時点で割り当てる（Step 3 では再判定しない）。
HIGH/MEDIUM/LOW の定義は subagent（`agents/shared/tech-debt-auditor.md`）の
Priority Criteria 表を参照する。

### Step 4: Issue作成

レポート提示後、どの finding を GitHub Issue 化するかユーザーに確認する:

1. 全 findings の連番リスト（Step 3 のグローバル連番）を表示し、以下を促す:

   ```text
   Issue化する項目を番号で指定してください（例: 1,3,5 / all / none）
   ```

2. ユーザーの応答に応じて:
   - **`none`**: スキルを終了
   - **`all`**: 全 findings を Issue 化
   - **番号指定**: 選択された findings のみ Issue 化
3. 選択された各 finding について `/git-issue-create` の規約で Issue を作成する:
   - **タイトル**: 日本語、finding の簡潔な説明
   - **ラベル**: `enhancement` + レポートから優先度をマッピングしたラベル
     （`HIGH` → `priority: high`、`MEDIUM` → `priority: medium`、`LOW` → `priority: low`）
   - **本文**: カテゴリ、ファイルパス、finding の詳細、改善提案を含める
4. 作成した Issue の番号と URL の一覧を表示する
