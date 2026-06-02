# Architecture Rules

本プロジェクト固有のアーキテクチャ規範。`lib/` 配下のコードはすべて本ルールに従うこと。

## Directory Layout

```text
lib/
├── main.dart                 # エントリポイント。ProviderScope で App をラップ
├── app/                      # ルートウィジェット、ルーティング、テーマ
│   ├── app.dart
│   └── router.dart
├── core/                     # 複数 feature にまたがる横断的関心事
└── features/
    └── <feature>/
        ├── presentation/     # 画面・ウィジェット（ConsumerWidget）
        ├── application/      # Riverpod プロバイダー / ノーティファイア
        ├── domain/           # 不変データ型（freezed）
        └── data/             # Repository 抽象 + 具体実装
```

- 新しい機能は必ず `lib/features/<feature>/` 配下に上記 4 レイヤ構成で追加する
- レイヤ名は固定（`presentation` / `application` / `domain` / `data`）。別名は使わない

## Layer Responsibilities

| Layer          | 責務                                                                            | 主な型・依存                            |
| -------------- | ------------------------------------------------------------------------------- | --------------------------------------- |
| `presentation` | 画面・UI ウィジェット。`application` のプロバイダーを `ref.watch` して描画      | `ConsumerWidget` / `ConsumerStatefulWidget` |
| `application`  | UI 状態とユースケース。`data` の Repository を呼び出して `domain` 型を返す     | Riverpod の `@riverpod` プロバイダー    |
| `domain`       | ドメインモデル（値オブジェクト）。フレームワーク非依存                          | `freezed` クラス                         |
| `data`         | 永続化・外部 I/O。`Repository` 抽象を定義し、具体実装をぶら下げる              | `abstract class XxxRepository` + 実装   |

## Layer Dependency Rules

- 依存方向: `presentation → application → data → domain`
- `domain` は他レイヤに依存しない（純粋なデータ型のみ）
- `presentation` から `data` を直接参照しない。必ず `application` 経由
- feature 間の直接依存は禁止。共通化が必要になった場合は `core/` へ昇格させる

## Tech Stack Policy

### Riverpod (`flutter_riverpod` + `riverpod_generator`)

- プロバイダーは `@riverpod` アノテーション方式で定義する（手書きの `Provider(...)` は使わない）
- `main.dart` で `ProviderScope` を最上位に置く構成を維持する
- プロバイダーは原則 `application/` 配下に置く。`data/` の Repository をプロバイダー化する場合も `application/` で行う

### go_router

- ルート定義は `lib/app/router.dart` の `appRouter` に集約する
- 画面遷移は `context.push` / `context.go` 等の go_router API を用いる（`Navigator` を直接使わない）
- 各画面のインポートは `features/<feature>/presentation/` から行う

### freezed

- `domain/` の値オブジェクトに用いる
- 生成ファイル（`*.freezed.dart` / `*.g.dart`）はリポジトリにコミットする
- 生成は `fvm dart run build_runner build`（開発中は `watch --delete-conflicting-outputs`）で行う

## `core/` Policy

- 単一 feature でしか使わないユーティリティは `core/` に置かない。その feature 内に配置する
- 2 つ以上の feature から実際に参照されるようになった時点で `core/` へ昇格させる
- `core/` は薄く保つ。安易に "便利関数置き場" にしない
