# per-minor リリースの定型 Issue

per-minor（MINOR bump、`vX.Y.0` 形式の機能追加リリース）の継続リリースで、milestone に載せる
Issue が固まった後に「定型 Issue（docs 最新化 / ストア説明文最新化 / ストアスクショ撮り直し）を
追加で作るべきか」を判断するための正本。PATCH/hotfix リリース（`vX.Y.Z`→`vX.Y.Z+1` 等、機能追加を
伴わないバグ修正のみのリリース）は対象外（`versioning.md` の MINOR/PATCH 定義を参照）。

> **位置づけ**: [`release-roadmap.md`](./release-roadmap.md) は初回ローンチ用の
> **3 Milestone を一度きりで scaffold する**ための正本（`release-roadmap-scaffold` skill が使用）。
> 本ドキュメントは初回ローンチ後の**継続リリースで毎回判断が発生する定型 Issue** の正本であり、
> 対象が異なる。
>
> milestone 作成自体のトリガー（何件でMilestoneを作るか）・命名規約・運用手順は本ドキュメントの
> スコープ外。それらは別ドキュメントで正本化する（未着手）。本ドキュメントは「milestone に載せる
> Issue が決まった後、どの定型 Issue を追加するか」の判断基準のみを扱う。

## 定型 Issue 判断テーブル

milestone に割り当てた Issue のラベル・内容から、以下の基準で必要なものだけを作成する。3種は
**独立に判断する**（該当するものだけ作ればよく、複数該当する場合はまとめて1 Issue にしてもよい）。

| 定型 Issue | 作成する条件 | 作成不要なケース | タイトル雛形 | 参照 |
| --- | --- | --- | --- | --- |
| docs 最新化 | `feature` / `enhancement` を含み、仕様書・テスト仕様に影響する変更がある | `chore` / `documentation` と軽微な `bug` のみ | `docs: vX.Y.Z の機能追加・UX 変更を仕様書／テスト仕様書に反映する` | [`release-docs-sync`](../../.claude/skills/release-docs-sync/SKILL.md) |
| ストア説明文最新化（What's New / Description） | ユーザーに見える機能追加・変更があり、ASC 掲載コピー（最新情報・概要）への反映が必要 | 内部リファクタ・ロジックのみ、または軽微な文言修正のみ | `docs: vX.Y.Z のストア説明文（最新情報・Description）を最新化する` | [`app-store-metadata.md`](./app-store-metadata.md) |
| ストアスクショ撮り直し | 掲載対象画面の UI 変更（新規追加・レイアウト変更等）を含む | 内部リファクタ・ロジックのみで UI 不変、または掲載対象外画面のみの変更 | `docs: vX.Y.Z リリース用に App Store スクリーンショットを最新画面で撮影し直す` | [`app-store-screenshots.md`](./app-store-screenshots.md) |

実例（consuming app 側の Issue）:

- docs 最新化: bulklog #502 / #565
- ストア説明文最新化: bulklog #480
- ストアスクショ撮り直し: bulklog #511

## ストア説明文最新化と GitHub Release ノートは別物

[`app-store-metadata.md`](./app-store-metadata.md) が扱う「What's New / Description」は
**App Store Connect の掲載コピー**（ユーザーがストアで読む訴求文）であり、正本は ASC 本体、
本ファイルはそのスナップショット台帳。

一方 `release-notes-generate` skill が生成する **GitHub Release ノート**は、マージ済み PR を
分類した**開発者向けの変更履歴**であり、掲載コピーとは目的・読み手・文体が異なる。片方を更新
しても他方は自動的には揃わないため、両方に反映が必要な変更では両方の定型 Issue（または対応作業）
を個別に判断すること。

## 判断者・タイミング

- milestone に対象 Issue を割り当てた後（milestone 運用手順の一部として）、各 Issue のラベル・
  本文から上記3種を判断する。
- hook では「milestone を切る」イベントも条件判断も扱えないため、milestone 設定の会話の中で
  自発的に判断・提案する運用とする。
