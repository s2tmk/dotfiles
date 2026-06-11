# Claude Code Harness v2

2026-06-12 に ECC フルバンドル構成から全面移行した自前ハーネス。
設計目標: **(1) 常駐トークンの最小化（レート制限対策） (2) 下位モデル（Opus/Sonnet）でも
Fable 級の成果を出す決定論的品質保証 (3) コンテキスト管理・フィードバックループの整備。**

## 3層アーキテクチャ

| 層 | 内容 | 実体 |
|---|---|---|
| L1 常駐コア | ルーティング判断のみ（いつ計画/委任/評価/handoff するか） | `CLAUDE.md`（約55行） |
| L2 オンデマンド知識 | ドメイン別パターン。frontmatter のみ常駐、本文は呼ばれた時だけロード | `skills/` 18個 |
| L3 決定論的強制 | モデル能力に依存しない品質ゲート | `hooks/` 6本 + `agents/` 評価者5体 + codex 第二意見 |

設計原則: **散文ルールの遵守率はモデル能力に比例するが、フックは100%発火する。**
品質保証はできる限り L3（フック・独立評価）に置き、L1 には「ルーティング判断」だけを残す。

## hooks/ — 決定論的ゲート

| フック | イベント | 動作 |
|---|---|---|
| `pre-config-guard.sh` | PreToolUse (Edit/Write) | lint/型設定の弱体化を **ブロック**（新規作成は許可） |
| `post-edit-accumulate.sh` | PostToolUse (Edit/Write) | 編集ファイルを session tmp に記録 |
| `post-bash-track.sh` | PostToolUse (Bash) | 実行コマンド記録（テスト実行検知用） |
| `stop-verify.sh` | Stop | 編集ファイルを format + `tsc --noEmit`。型エラーで **応答終了をブロック**し差し戻し。テスト未実行は警告 |
| `session-start.sh` | SessionStart | `tasks/handoff.md`（7日以内・上限2KB）だけを注入 |
| `pre-compact-save.sh` | PreCompact | git status + 編集ファイル一覧を handoff.md に退避 |

**キルスイッチ:**
- `HARNESS_HOOKS=off` — 全フック即時無効（緊急用）
- `HARNESS_STOP_GATE=off|block|strict` — Stop ゲートのみ制御（既定 block、strict はテスト必須）
- 回帰テスト: `bash hooks/run-tests.sh`（10ケース）

**誤爆防止設計:** 全フックは内部エラー時 exit 0 / Stop ゲートは `stop_hook_active` チェック +
accumulator の clear-on-read（同一編集バッチにつきブロック最大1回）。

## agents/ — 独立評価者（GANパターン）

code-reviewer / security-reviewer / react-reviewer / build-error-resolver / e2e-runner。
全て `model: sonnet` 固定（レート制限の安い枠で評価を回す。独立性こそが価値でありモデル階級ではない）。
評価者には**変更ファイル一覧と要件のみ**を渡す。生成者の自己評価を渡さない。
CRITICAL/HIGH 1件でも verdict FAIL、「全体としては許容」という合理化は禁止。

## 出典と経緯

- ベンダリング元: ECC plugin `2.0.0-rc.1`（cache: `~/.claude/plugins/cache/ecc/ecc/2.0.0-rc.1/`）。
  各ファイルに `Vendored from ECC 2.0.0-rc.1` コメントあり。大幅に刈り込み・再構成済み。
- ECC プラグインは `settings.json` で無効化（`"ecc@ecc": false`）。理由: 249スキル一覧
  （説明文付き）が毎セッション注入される常駐税はプラグイン無効化でしか消えないため。
- 廃止した ECC 機構: 観測系フック（continuous-learning/governance/metrics/cost-tracker）、
  memory MCP（ネイティブ memory ディレクトリで代替）、sequential-thinking MCP（extended thinking で代替）、
  github MCP（`gh` CLI で代替）、exa MCP（WebSearch で代替）。
- MCP は user スコープの playwright + context7 のみ（旧 `/Users/tomokis` プロジェクト限定登録は移行済み）。
- `~/.agents/skills/` は `~/.agents/skills.disabled/` にリネーム（1週間問題なければ削除可）。

## 計測（/context で記録すること）

| 指標 | v1 (ECC full) | v2 | 備考 |
|---|---|---|---|
| 常駐散文 (CLAUDE.md+rules) | 約21.5KB | 約4KB | CLAUDE.md 55行 + paths限定rules 2本 |
| スキル一覧エントリ | 249 (ECC) + 約25 (~/.agents) | 18 | 説明文も1文に圧縮 |
| フック | 28本 (node bootstrap 約1.5KB/発火) | 6本 (bash+jq) | 観測系全廃 |
| MCPサーバー | 6 (ECC) + 重複2 | 2 + figma/codex plugin | |
| /context 実測 (起動時) | ___ tokens | ___ tokens | 新セッションで記録 |

## 既定モデル運用

- 既定: `claude-opus-4-8`（effort xhigh）。難タスク（長時間自律・曖昧仕様の解釈）のみ `/model` で Fable 指名。
- ハーネスで埋まるのは「検証忘れ・指示逸脱・コンテキスト劣化」起因の失敗。モデルの絶対能力差は残る。

## 改善ループ（Harness Assumption Auditing）

このハーネスの全ルール・フックは「モデルが単体では確実にできないこと」の仮説をエンコードしている。
仮説はモデルの進化で陳腐化する。

- 新モデル導入時: 各制約がまだ有効か問い直す。不要に発火するガードレールは回避せず報告・削除する
- ユーザー修正を受けたら `/learn`（→ MEMORY.md or skills/learned/）
- 四半期ごと: `/context` でトークン監査、learned/ スキルの棚卸し
- 制約を増やすより、モデルが自力でできるようになった制約を削る方を優先する
