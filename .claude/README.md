# Claude Code Harness v2

An owned harness that fully replaced the ECC bundle on 2026-06-12.
Design goals: **(1) minimize always-resident tokens (rate-limit pressure),
(2) deterministic quality assurance so lower-tier models (Opus/Sonnet) deliver
Fable-tier results, (3) solid context management and feedback loops.**

Language policy: instruction files that Claude reads (CLAUDE.md, skills, agents,
rules, hook-injected messages) are written in **English** to avoid translation
drift. Japanese appears only as (a) trigger keywords that match the user's
Japanese prompts, (b) deliverable labels such as 検証済み/推定, and (c) verbatim
quotes of the user's own standards. Responses to the user are Japanese
(`"language": "japanese"` in settings.json).

## Repository layout & installation

This directory is versioned inside the `dotfiles` repo. `~/.claude` is NOT a
git repo — it holds runtime state (history, projects/, plugins/, session data)
that must never be committed. Run `~/dotfiles/install.sh` to symlink every
top-level entry here into `~/.claude` (idempotent: re-points stale links,
backs up real files as `*.bak.<timestamp>`). Re-run after pulling when new
top-level entries appear. `settings.local.json` stays machine-local.

Note: hook commands in settings.json reference `$HOME/dotfiles/.claude/hooks/`
directly, so hooks work even before the `hooks` symlink exists.

## 3-layer architecture

| Layer | Role | Implementation |
|---|---|---|
| L1 always-on core | Routing decisions only (when to plan / delegate / evaluate / hand off) | `CLAUDE.md` (~80 lines) |
| L2 on-demand knowledge | Domain patterns; only frontmatter is resident, bodies load when invoked | `skills/` (19) |
| L3 deterministic enforcement | Quality gates independent of model tier | `hooks/` (7) + `agents/` evaluators (7) + codex second opinion |

Design principle: **compliance with prose rules scales with model capability,
but hooks fire 100% of the time.** Put quality assurance in L3 wherever
possible; L1 carries routing judgment only.

## hooks/ — deterministic gates

| Hook | Event | Behavior |
|---|---|---|
| `prompt-router.sh` | UserPromptSubmit | Injects a one-line skill-routing reminder on JA/EN keyword match (model-independent skill discovery) |
| `pre-config-guard.sh` | PreToolUse (Edit/Write) | **Blocks** weakening lint/type configs — including the create-a-looser-new-config loophole |
| `post-edit-accumulate.sh` | PostToolUse (Edit/Write) | Records edited files into session scratch |
| `post-bash-track.sh` | PostToolUse (Bash) | Records executed commands (test-run detection) |
| `stop-verify.sh` | Stop | Formats + `tsc --noEmit` on edited files; **blocks the response on type errors** and bounces them back. Missing tsc surfaces once instead of passing silently. Test reminder (1 file for auth/payment paths, 3 otherwise). pnpm/yarn/bun runner detection with monorepo lockfile walk-up |
| `session-start.sh` | SessionStart | Injects `tasks/handoff.md` only (≤7 days old, ≤2KB cap); prunes stale scratch dirs |
| `pre-compact-save.sh` | PreCompact | Saves git status + edited-file list into handoff.md |

**Kill switches:**
- `HARNESS_HOOKS=off` — disables every hook instantly (emergency)
- `HARNESS_STOP_GATE=off|block|strict` — Stop gate only (default block; strict also requires tests)
- Regression tests: `bash hooks/run-tests.sh` (14 cases)

**No-false-block design:** every hook exits 0 on internal error; the Stop gate
checks `stop_hook_active` and uses a clear-on-read accumulator (at most one
block per edit batch).

## agents/ — independent evaluators (GAN pattern)

code-reviewer / security-reviewer / react-reviewer / design-reviewer /
research-reviewer / build-error-resolver / e2e-runner. All pinned to
`model: sonnet` (evaluation burns the cheaper rate window; independence — not
model tier — is what makes the loop work). Evaluators receive **only the
changed-file list and requirements**, never the generator's self-assessment.
Any CRITICAL/HIGH finding ⇒ verdict FAIL; "acceptable overall" rationalization
is forbidden. design-reviewer FAILs generic-AI-template UI on primary surfaces;
research-reviewer refutes unsourced numbers (two FAILs ⇒ stop and surface to
the user).

## Provenance

- Vendored from ECC plugin `2.0.0-rc.1` (cache:
  `~/.claude/plugins/cache/ecc/ecc/2.0.0-rc.1/`), heavily trimmed and
  restructured; each vendored file carries a `Vendored from ECC 2.0.0-rc.1`
  comment.
- The ECC plugin is disabled (`"ecc@ecc": false` in settings.json). Reason: the
  ~249-skill always-on listing tax only disappears when the plugin is off.
- Dropped ECC machinery: observation hooks (continuous-learning / governance /
  metrics / cost-tracker), memory MCP (native memory dir), sequential-thinking
  MCP (extended thinking), github MCP (`gh` CLI), exa MCP (WebSearch).
- MCP servers: user-scoped playwright + context7 only (migrated from the old
  `/Users/tomokis` project-local registration), plus the figma and codex plugins.
- `~/.agents/skills/` was renamed to `~/.agents/skills.disabled/`
  (delete after a safe week).

## Measurements (record via /context)

| Metric | v1 (ECC full) | v2 | Notes |
|---|---|---|---|
| Always-on prose (CLAUDE.md + rules) | ~21.5KB | ~5KB | CLAUDE.md ~80 lines + 2 path-scoped rules |
| Skill list entries | 249 (ECC) + ~25 (~/.agents) | 19 | descriptions compressed to one sentence |
| Hooks | 28 (node bootstrap ~1.5KB/firing) | 7 (bash+jq) | observation hooks removed |
| MCP servers | 6 (ECC) + 2 duplicates | 2 + figma/codex plugins | |
| /context at session start | ___ tokens | ___ tokens | record in a fresh session |

## Default model policy

- Default: `claude-opus-4-8` (effort xhigh). Switch to Fable via `/model` only
  for long autonomous runs or ambiguous-spec interpretation.
- The harness closes failures caused by skipped verification, instruction
  drift, and context decay. Absolute capability gaps remain — that is what the
  Fable escape hatch is for.

## Self-evaluation scores (2026-06-12)

Independent evaluator agents (no self-assessment passed in, rationalization
forbidden), iterated until >90 in all domains:
software development **91** / UX-UI design **93** / business development **93**.
Remaining backlog: deterministic gates for non-TS languages, pixel-level visual
verification, Figma round-trip as an enforced (not advisory) gate, and a live
Opus field trial.

## Improvement loop (harness assumption auditing)

Every rule and hook encodes an assumption about what a model cannot do
reliably on its own; assumptions decay as models improve.

- When adopting a new model: re-question whether each constraint is still
  load-bearing. A guardrail that fires needlessly should be reported and
  removed, not worked around.
- After any user correction: `/learn` (→ MEMORY.md or skills/learned/).
- Quarterly: token audit via `/context`, prune skills/learned/.
- Prefer deleting constraints the model now handles natively over adding
  scaffolding.
