---
name: bizdev-strategy
description: Elevate a vague business idea to a structured strategy with falsifiable hypotheses, evidence-backed market sizing, GTM options, and a phased roadmap — with explicit handoffs to investor-materials and requirements-design. Load when the user needs a business plan, business model design, GTM strategy, market entry analysis, or strategic roadmap. Keywords: 事業計画, ビジネスモデル, GTM, 市場参入, 事業戦略, ロードマップ, business plan, business model, go-to-market, market entry, strategic roadmap.
origin: local
---

# Bizdev Strategy

Turn a vague business idea into a structured, evidence-grounded strategy with clear decisions and downstream handoffs.

## Stance

Decisions with reasoning — not summaries. Every number is labeled **検証済み** (verified against a cited source) or **推定** (estimated, with method stated). No number is left unlabeled.

---

## Section 1 — Problem Framing & Hypotheses

Restate the business idea as three falsifiable hypotheses before doing anything else:

1. **Customer hypothesis** — Who specifically has this problem? (segment, geography, company size, role)
2. **Problem hypothesis** — What job are they failing to get done, and what do they currently use instead?
3. **Willingness-to-pay hypothesis** — What would they pay, and what is the reference price in their current solution?

Each hypothesis must be falsifiable: state what evidence would prove it wrong. Do not proceed to Section 2 until these are written.

---

## Section 2 — Evidence

**Never invent numbers in this section.** All market sizing and competitive facts come from the **market-research** skill. If that output does not exist, invoke market-research first and return here once it does.

Structure the evidence as:

- **Market size**: TAM / SAM / SOM with labels (検証済み / 推定) and method per number, sourced from market-research output
- **Competitive landscape**: named competitors, their positioning, pricing signals, and distribution channels — attributed to sources with dates
- **Customer signals**: interviews, surveys, behavioral data, or analogous markets — each with sample size and date
- **Regulatory / structural constraints**: any non-negotiable external factors that shape the strategy

---

## Section 3 — Strategic Options

Present 2–3 distinct GTM or business-model options. For each option:

| Dimension | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| Business model | | | |
| Primary channel | | | |
| Target segment (year 1) | | | |
| Revenue mechanism | | | |
| Key assumption to validate | | | |
| Upside if assumption holds | | | |
| Downside if assumption fails | | | |

Do not recommend yet — that comes in Section 5. The goal here is to make the trade-offs explicit and comparable.

---

## Section 4 — Risks & Kill Criteria

For each hypothesis in Section 1, state:

- **Kill criterion**: the specific evidence that would invalidate the strategy (e.g., "fewer than 3 of 10 discovery interviews cite this as a top-3 pain point")
- **Mitigation**: the cheapest experiment that would surface this evidence before committing resources
- **Timeline**: when the kill criterion must be tested (before which phase)

Also flag macro risks (regulatory change, technology shift, competitor move) with likelihood and impact ratings.

---

## Section 5 — Recommendation & Roadmap

State the recommended option from Section 3 with the rationale tied explicitly to the evidence in Section 2.

### Phased Roadmap

**Phase 0 — Validate (weeks 1–8)**
- Objective: test the kill criteria from Section 4 before committing engineering resources
- Activities: customer discovery interviews, landing page / smoke test, competitive pricing audit
- Exit criterion: [specific, measurable signal]

**Phase 1 — Build (months 2–6)**
- Objective: deliver the minimum surface area that proves the core value hypothesis
- Feature proposals: each feature tied to a specific user-need signal from Section 2
  ```
  Feature: [name]
  Evidence: [signal source, n=, date]
  Scope: [what's in / what's explicitly out]
  ```
- Open questions for engineers: unresolved technical decisions that affect build scope
- Open questions for designers: unresolved UX decisions that affect usability assumptions

**Phase 2 — Scale (months 6–18)**
- Objective: expand from early adopters to the broader SAM
- GTM motion: [channel, sales model, partnership strategy]
- Key metrics to hit before Phase 3: [specific targets, labeled 推定]

**Phase 3 — Defend (18 months+)**
- Objective: build the moat identified in Section 3
- Milestones tied to the SOM capture assumptions from Section 2

---

## Section 6 — Handoffs

After this document is complete, route downstream work as follows:

- **Fundraising docs** → **investor-materials** skill. All TAM/SAM/SOM and competitive claims in the pitch must trace to the Evidence section (Section 2) of this document. Do not re-derive numbers in the deck.
- **First build slice** → **requirements-design** skill. Use the Phase 1 feature proposals and open questions as the starting input. requirements-design will surface personas, scope boundaries, edge cases, and acceptance criteria before implementation begins.

---

## Output Checklist

Before delivering:

- [ ] Three falsifiable hypotheses written (Section 1)
- [ ] No numbers invented — all from market-research output (Section 2)
- [ ] Every number labeled 検証済み or 推定 with method
- [ ] 2–3 options compared with explicit trade-offs (Section 3)
- [ ] Kill criteria stated for each hypothesis (Section 4)
- [ ] Recommended option justified by evidence, not assertion (Section 5)
- [ ] Phased roadmap with exit criteria per phase (Section 5)
- [ ] Feature proposals each tied to a user-need signal (Section 5)
- [ ] Downstream handoffs named (Section 6)
