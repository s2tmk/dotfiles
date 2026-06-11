#!/bin/bash
# UserPromptSubmit: deterministic domain-routing backstop.
# Injects a one-line skill-routing reminder when the prompt matches domain
# keywords (JA/EN) — fires regardless of model tier. Silent when no match.
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
prompt=$(hook_field '.prompt')
[ -n "$prompt" ] || exit 0

emit=""
add() { emit="${emit}${1}
"; }

if printf '%s' "$prompt" | grep -qiE '新機能|要件定義|仕様|プロダクト設計|new feature|spec|requirements'; then
  add "Routing: requirements-design スキルで潜在要求を確認してから実装に入る。"
fi
if printf '%s' "$prompt" | grep -qiE 'UI|画面|デザイン|ダッシュボード|ランディング|LP\b|ワイヤーフレーム|design|screen|dashboard|landing'; then
  add "Routing: ux-ui-design（設計基準）+ frontend-design（実装）。完成後は design-reviewer で独立評価（FAIL なら出荷しない）。"
fi
if printf '%s' "$prompt" | grep -qiE '市場調査|競合|市場規模|デューデリ|market (research|sizing|entry)|competitive|due diligence|TAM'; then
  add "Routing: market-research（実調査は deep-research に委譲、納品前に research-reviewer で検証）。"
fi
if printf '%s' "$prompt" | grep -qiE '事業計画|事業戦略|ビジネスモデル|市場参入|GTM|business plan|go-to-market|business model'; then
  add "Routing: bizdev-strategy（market-research の Evidence が前提 — なければ先に実行）。"
fi
if printf '%s' "$prompt" | grep -qiE 'ピッチ|投資家|資金調達|財務モデル|pitch deck|investor|fundrais'; then
  add "Routing: investor-materials（数値は market-research 由来必須、research-reviewer で検証）。"
fi
if printf '%s' "$prompt" | grep -qiE 'インフラ|AWS|GCP|Cloudflare|Terraform|VPC|IAM|serverless|deploy.*infra'; then
  add "Routing: cloud-infra スキル（IaC・最小権限・DR・コストガードレール）。"
fi

[ -n "$emit" ] && printf '%s' "$emit" | head -3
exit 0
