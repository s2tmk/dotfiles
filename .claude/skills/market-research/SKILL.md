---
name: market-research
description: Market research producing evidence-grade outputs: TAM/SAM/SOM sizing triangulated against government statistics, industry reports, and academic literature; competitive analysis; investor due diligence; technology scans. Delivers decisions, not summaries. Load when the user needs market sizing, competitive intelligence, fund research, or thesis validation at academic-paper rigor. Keywords: 市場調査, 競合分析, 市場規模, TAM, デューデリジェンス, market sizing, competitive analysis, competitive intelligence, market entry, due diligence.
origin: ECC
---

<!-- Vendored from ECC 2.0.0-rc.1 skills/market-research -->

# Market Research

Produce research that supports decisions, not research theater.

## Tool Integration

For any non-trivial research question, invoke the **deep-research** harness skill for multi-source fan-out with adversarial verification — its cited output is the raw evidence layer; this skill defines the synthesis and output format on top. For targeted lookups use **WebSearch** (query execution) and **WebFetch** (primary-source retrieval). **Hard gate: never write findings without executed searches — a deliverable whose claims lack an executed deep-research/WebSearch trail fails the Verification Gate automatically.**

## When to Activate

- Researching a market, category, company, investor, or technology trend
- Building TAM/SAM/SOM estimates
- Comparing competitors or adjacent products
- Preparing investor dossiers before outreach
- Pressure-testing a thesis before building, funding, or entering a market

## Research Standards

1. Every important claim needs a source.
2. Prefer recent data and call out stale data.
3. Include contrarian evidence and downside cases.
4. Translate findings into a decision, not just a summary.
5. Separate fact, inference, and recommendation clearly.

## Research Depth Standard

The bar for this skill is **徹底した市場調査・統計資料・学術論文レベル** — academic rigor, not consulting-deck feel.

### Source Hierarchy

Prefer in this order:
1. **Primary government statistics** — census data, trade statistics, ministry/agency surveys with methodology documentation
2. **Peer-reviewed academic literature** — empirical studies with sample sizes and confidence intervals
3. **Established industry reports** — Gartner, IDC, CB Insights, sector-specific research firms (cite the specific report title, year, and page)
4. **Company filings and earnings calls** — primary source for public company data
5. **Reputable journalism** — only for recent developments not yet in structured sources; verify with a second source

Avoid: press releases, vendor-sponsored white papers, and unattributed "industry experts say" claims.

### Triangulation Requirement

Market size claims must be triangulated across at least two independent source types:

```
Example: SaaS market in Japan
- Top-down: METI digital transformation survey (2023) → enterprise software spend as % GDP
- Bottom-up: public ARR from listed SaaS companies × estimated market share
- Cross-check: IDC Japan cloud report (2023)

If the three estimates disagree by >30%, document the range and the likely reason for divergence.
```

### Citing Sources

Format: `Author/Organization (Year). "Title." URL or publication detail. [Accessed: date if web]`

When data is older than 3 years, flag it explicitly: `[Data from 2021 — verify if market has shifted]`

### TAM/SAM/SOM Clarity

Always distinguish:
- **TAM**: theoretical maximum, requires explicit assumption (e.g., "assumes all enterprises with >50 employees adopt")
- **SAM**: addressable segment given your model and geography — must have defensible filter logic
- **SOM**: realistic capture in 3-5 years — must tie to specific GTM assumptions, not a generic percentage
- **Verified vs estimated**: label each number as one or the other

```
Bad:  "TAM is $10B"
Good: "TAM (estimated): $10B based on [Source A, 2023] adjusted for [assumption X].
       SAM (estimated): $1.2B filtering to Japan SMB segment (50–500 employees, ≥¥500M revenue)
       per METI 2022 survey. SOM (forecast): ¥240M in year 3 assuming 20% market penetration
       among early-adopter segment of 600 target companies."
```

## Common Research Modes

### Investor / Fund Diligence
Collect:
- Fund size, stage, and typical check size
- Relevant portfolio companies
- Public thesis and recent activity
- Reasons the fund is or is not a fit
- Any obvious red flags or mismatches

### Competitive Analysis
Collect:
- Product reality, not marketing copy
- Funding and investor history if public
- Traction metrics if public
- Distribution and pricing clues
- Strengths, weaknesses, and positioning gaps

### Market Sizing
Use:
- Top-down estimates from reports or public datasets
- Bottom-up sanity checks from realistic customer acquisition assumptions
- Explicit assumptions for every leap in logic

### Technology / Vendor Research
Collect:
- How it works (not marketing description)
- Trade-offs and adoption signals
- Integration complexity and lock-in risk
- Security, compliance, and operational risk
- Alternative approaches and when each is better

## Outputs That Engineers and Designers Can Act On

Research only has value when the downstream team can use it. Tailor outputs:

### Roadmap with Rationale

```
Feature: Offline mode
Evidence: 67% of field-worker users (survey, n=200, Q1 2024) reported unreliable connectivity
          as top pain point. Three competitor products lack this feature (competitive analysis above).
Proposed timeline: Q3 2025 (after core sync engine lands in Q2)
Open question: which data subset is critical offline vs. full sync?
```

### Feature Proposals Tied to User Needs Evidence

Link every proposed feature to a specific user need signal: a quote, a survey data point, a behavioral metric, or an analogous pattern from a comparable market.

### Open Questions for the Team

Research should surface what it cannot answer:

```
Open questions after this research:
1. Regulatory: Will the FSA classify our token structure as a security instrument?
   (Requires legal counsel — current guidance is ambiguous post-2024 revision)
2. TAM assumption: The ¥240M SOM assumes 20% penetration of the 600-company target list.
   Is 20% realistic given 12-month avg. enterprise sales cycles? (Needs sales input)
3. Competitive moat: Competitor A has filed 3 patents in this area (USPTO, 2022-2024).
   Do these block our approach? (Needs IP counsel review)
```

## Output Format

Default structure:

1. **Executive summary** (3-5 bullets, decision-oriented)
2. **Key findings** (organized by research mode above)
3. **Market size estimates** (TAM/SAM/SOM with sources and labels)
4. **Competitive landscape**
5. **Implications** (what this means for the decision)
6. **Risks and caveats**
7. **Recommendation** (concrete: enter/exit/wait/pivot/investigate)
8. **Open questions** (what research could not resolve)
9. **Sources** (formatted citations)

## Verification Gate

Before delivery, run the **research-reviewer** agent on the draft. Pass it ONLY the draft and source list — not your reasoning. FAIL => fix and re-run. Never deliver unverified numbers. If the document fails research-reviewer twice, STOP and surface the unresolved HIGH findings to the user — do not loop silently.

## Quality Gate

Before delivering:
- All numbers are sourced or labeled as estimates
- Old data is flagged with the year
- TAM/SAM/SOM are clearly separated and labeled
- The recommendation follows from the evidence
- Risks and counterarguments are included
- Engineers and designers can derive actionable next steps
- Open questions are listed so the team knows what is unresolved
- The output makes a decision easier, not just more documented

## Delivery

If the user's Notion workspace is connected (Notion MCP), offer to publish the final deliverable as a Notion page (`notion-create-pages` for new deliverables, `notion-update-page` for revisions).
