---
name: investor-materials
description: Create and update pitch decks, one-pagers, investor memos, accelerator applications, financial models, and use-of-funds tables — all internally consistent from a single source of truth. Load when the user needs investor-facing documents, projections, milestone plans, or fundraising materials. Keywords: ピッチデッキ, 投資家向け資料, 資金調達, 財務モデル.
origin: ECC
---

<!-- Vendored from ECC 2.0.0-rc.1 skills/investor-materials -->

# Investor Materials

Build investor-facing materials that are consistent, credible, and easy to defend.

## When to Activate

- Creating or revising a pitch deck
- Writing an investor memo or one-pager
- Building a financial model, milestone plan, or use-of-funds table
- Answering accelerator or incubator application questions
- Aligning multiple fundraising docs around one source of truth

## Golden Rule

All investor materials must agree with each other.

Create or confirm a single source of truth before writing:
- Traction metrics
- Pricing and revenue assumptions
- Raise size and instrument
- Use of funds
- Team bios and titles
- Milestones and timelines

If conflicting numbers appear, stop and resolve them before drafting.

## Market Data Prerequisite

Market size and competitive claims MUST trace back to a **market-research** output (`docs/strategy/<product>-market-research.md`) or the Evidence section of a **bizdev-strategy** document (`docs/strategy/<product>-strategy.md`). If they don't exist, run **market-research** first — never accept TAM/SAM numbers that exist only in the deck.

## Core Workflow

1. Inventory the canonical facts
2. Identify missing assumptions
3. Choose the asset type
4. Draft the asset with explicit logic
5. Cross-check every number against the source of truth

## Asset Guidance

### Pitch Deck

Recommended flow:
1. Company + wedge
2. Problem
3. Solution
4. Product / demo
5. Market
6. Business model
7. Traction
8. Team
9. Competition / differentiation
10. Ask
11. Use of funds / milestones
12. Appendix

If the user wants a web-native (HTML) deck, pair this skill with the **frontend-design** skill.

### One-Pager / Memo

- State what the company does in one clean sentence
- Show why now
- Include traction and proof points early
- Make the ask precise
- Keep claims easy to verify

### Financial Model

Include:
- **Driver tree**: revenue derived from explicit drivers (e.g., leads × conversion × ACV − churn) — never a flat growth percentage
- **Burn / runway**: monthly burn by category and runway in months, at current cash and post-raise
- **Cohort / retention logic**: projections must encode a per-cohort retention/churn assumption, not aggregate growth
- **Bear / base / bull**: each case derived only from named assumption changes (e.g., "bear: conversion 1% vs. base 2%") — never free-drawn curves
- Milestone-linked spending
- Sensitivity analysis where the decision hinges on assumptions

### Funding Instruments (JP context)

For Japan-based raises, consider alongside SAFE / priced equity:
- **J-KISS** — the standard JP convertible (post-money SAFE equivalent)
- **日本政策金融公庫 創業融資** — non-dilutive startup loans
- **補助金** — IT導入補助金, ものづくり補助金 and similar (non-dilutive; eligibility windows apply)

State the chosen instrument and the reason in the ask.

### Accelerator Applications

- Answer the exact question asked
- Prioritize traction, insight, and team advantage
- Avoid puffery
- Keep internal metrics consistent with the deck and model

## Red Flags to Avoid

- Unverifiable claims
- Fuzzy market sizing without assumptions
- Inconsistent team roles or titles
- Revenue math that does not sum cleanly
- Inflated certainty where assumptions are fragile

## Quality Gate

**MUST**: write each deliverable to `docs/strategy/<product>-investor/<doc>.md` (e.g., `.../pitch-deck.md`, `.../financial-model.md`).

Before delivering:
- Every number matches the current source of truth
- Use of funds and revenue layers sum correctly
- Assumptions are visible, not buried
- The story is clear without hype language
- The final asset is defensible in a partner meeting

## Verification

Run the **research-reviewer** agent on the completed draft. Pass it the draft and the source list from the underlying market-research output — not your reasoning. FAIL => fix and re-run. If the document fails research-reviewer twice, STOP and surface the unresolved HIGH findings to the user — do not loop silently.

## Delivery

If the user's Notion workspace is connected (Notion MCP), offer to publish the final deliverable as a Notion page (`notion-create-pages` for new documents, `notion-update-page` for revisions).
