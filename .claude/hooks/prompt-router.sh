#!/bin/bash
# UserPromptSubmit: deterministic domain-routing backstop.
# Injects a one-line skill-routing reminder when the prompt matches domain
# keywords (JA/EN) — fires regardless of model tier. Silent when no match.
# NOTE: regex keywords stay bilingual (they match user prompts, which are
# usually Japanese); the injected reminders are English (instructions Claude
# reads must be English to avoid translation drift).
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
prompt=$(hook_field '.prompt')
[ -n "$prompt" ] || exit 0

emit=""
add() { emit="${emit}${1}
"; }

if printf '%s' "$prompt" | grep -qiE '新機能|要件定義|仕様|プロダクト設計|new feature|spec|requirements'; then
  add "Routing: run requirements-design to confirm latent requirements before implementing."
fi
if printf '%s' "$prompt" | grep -qiE 'UI|画面|デザイン|ダッシュボード|ランディング|(^|[^a-zA-Z])LP([^a-zA-Z]|$)|ワイヤーフレーム|design|screen|dashboard|landing'; then
  add "Routing: ux-ui-design (standards) + frontend-design (build). After building, run design-reviewer for independent evaluation (FAIL = do not ship)."
fi
if printf '%s' "$prompt" | grep -qiE '市場調査|競合|市場規模|デューデリ|market (research|sizing|entry)|competitive|due diligence|TAM'; then
  add "Routing: market-research (delegate execution to deep-research; verify with research-reviewer before delivery)."
fi
if printf '%s' "$prompt" | grep -qiE '事業計画|事業戦略|ビジネスモデル|市場参入|GTM|business plan|go-to-market|business model'; then
  add "Routing: bizdev-strategy (requires market-research evidence — run it first if missing)."
fi
if printf '%s' "$prompt" | grep -qiE 'ピッチ|投資家|資金調達|財務モデル|pitch deck|investor|fundrais'; then
  add "Routing: investor-materials (numbers must trace to market-research; verify with research-reviewer)."
fi
if printf '%s' "$prompt" | grep -qiE 'インフラ|AWS|GCP|Cloudflare|Terraform|VPC|IAM|serverless|deploy.*infra'; then
  add "Routing: cloud-infra skill (IaC, least-privilege, DR, cost guardrails)."
fi

[ -n "$emit" ] && printf '%s' "$emit" | head -3
exit 0
