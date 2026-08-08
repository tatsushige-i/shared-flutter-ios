# per-minor リリースの milestone 運用

per-minor（MINOR bump、`vX.Y.0` 形式の機能追加リリース）の継続リリースで、次リリースに載せる
Issue が固まってから公開後の Milestone クローズまでの**運用手順**を正本化する。「milestone に
載せる Issue が決まった後、どの定型 Issue（docs 最新化 / ストア説明文最新化 / スクショ撮り直し）
を追加するか」の判断基準は本ドキュメントのスコープ外（[`release-recurring-issues.md`](./release-recurring-issues.md)
が正本）。

> **位置づけ**: [`release-roadmap.md`](./release-roadmap.md) は初回ローンチ用の
> **3 Milestone を一度きりで scaffold する**ための正本（`release-roadmap-scaffold` skill が使用）。
> [`release-recurring-issues.md`](./release-recurring-issues.md) は継続リリースで毎回判断する
> **定型 Issue の要否判断基準**の正本。本ドキュメントはそのどちらでもなく、継続リリースにおける
> **milestone 作成トリガー・命名規約・Issue 割当・cut 判断・クローズまでの運用手順**の正本であり、
> `release-milestone-create` skill が使用する。

## Milestone 作成トリガー

次リリースに載せるバージョンを決めたら、載せる Issue 数によらず常に `vX.Y.0` の Milestone を
作成する。

## Milestone とラベルの役割

- **Milestone あり** = その version にスケジュール済み
- **Milestone なし** = 未スケジュール（やる予定だが version 未定）
- **`backlog` ラベル** = 明確に先送り（someday / 当面着手しない）

## 命名規約

- Milestone 名はリリース version に対応させる（例: `v1.1.0`）。
- SemVer の採番基準（MAJOR / MINOR / PATCH の判定表）は [`versioning.md`](./versioning.md) を正とする。

## 運用手順

1. 次リリースに載せるバージョンが決まったら `vX.Y.0` Milestone を作成する。
2. 対象 Issue を Milestone に割り当てる。
3. **リリース定型 Issue の要否を判断して起票する。** 割り当てた Issue のラベル・内容から
   何を作成すべきかは [`release-recurring-issues.md`](./release-recurring-issues.md) の判断
   テーブルに従う（該当するものだけを作成する）。
4. 進捗（open/closed）を見て**リリースをスケジュールできる**と判断したら、release ブランチを
   切る。ブランチの切り出し元・命名・タイミングは対象アプリのブランチ戦略ドキュメントに従う
   （shared 側にブランチ戦略の正本は無いため、対象アプリ側のドキュメントを参照すること）。
5. リリース公開後、該当 Milestone を close する。

実例（consuming app 側の Milestone）: bulklog #22 (v1.17.0)

## 判断者・タイミング

- 次リリース候補の Issue が固まった時点（milestone 作成の直前・直後）で、対象 Issue のラベル・
  内容から上記手順を実行する。
- hook では「milestone を切る」イベントを扱えないため、milestone 設定の会話の中で自発的に
  判断・提案する運用とする（`release-milestone-create` skill が本手順に沿って対話的に実行する）。
