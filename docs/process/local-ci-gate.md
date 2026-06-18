# ローカル CI ゲート（make ci + pre-push フック）

## 目的

GitHub Actions 無料枠の消費を抑えるため、push 前にローカルで CI 相当のチェックを実行する。
`make ci` は CI の `test.yml` と同等のステップを再現する。

## 前提

- [fvm](https://fvm.app/) がインストール済みであること

## セットアップ

### 新規アプリ（bootstrap.sh 実行後）

`bootstrap.sh` 実行時に `templates/Makefile` がアプリルートにコピーされる。
既に他のターゲットを持つ `Makefile` が存在する場合は自動コピーされないため、
「既存 Makefile への追記」セクションを参照すること。

### 既存アプリ（bootstrap 実行済み）

1. `/config-flutter-ios-sync` を実行してこのドキュメントの symlink を取得する
2. shared-flutter-ios の `templates/Makefile` の内容を自アプリの `Makefile` に追記する（後述）

## make ci の実行

```sh
make ci
```

実行される処理:

| ステップ | コマンド | 目的 |
|---|---|---|
| フォーマットチェック | `fvm dart format --output=none --set-exit-if-changed .` | 未フォーマットのファイルがあれば失敗 |
| 静的解析 | `fvm flutter analyze` | 警告・エラーがあれば失敗 |
| テスト | `fvm flutter test` | テストが失敗すれば失敗 |
| コード生成 | `fvm dart run build_runner build` | 生成ファイルを最新化 |
| codegen 鮮度確認 | `git diff --exit-code` | 生成ファイルが未コミットなら失敗 |

## pre-push フックの導入（任意）

push 時に自動的に `make ci` を実行するフックをインストールする。

```sh
make pre-push-setup
```

`.git/hooks/pre-push` が作成され、以降の `git push` で `make ci` が自動実行される。
CI チェックに失敗すると push がブロックされる。

フックを無効化したい場合は以下のいずれかを実行する:

```sh
# 一時的にスキップ（1 回限り）
git push --no-verify

# 恒久的に削除
rm .git/hooks/pre-push
```

## 既存 Makefile への追記

アプリに既に `Makefile` がある場合、以下のターゲットを追記する。

```makefile
.PHONY: ci pre-push-setup

ci:
	fvm dart format --output=none --set-exit-if-changed .
	fvm flutter analyze
	fvm flutter test
	fvm dart run build_runner build
	git diff --exit-code

pre-push-setup:
	@printf '#!/bin/sh\nmake ci\n' > .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push
	@echo "pre-push hook installed: .git/hooks/pre-push"
```

> **注意**: Makefile のインデントはタブ文字を使用すること。スペースでは make が失敗する。
