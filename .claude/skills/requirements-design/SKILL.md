---
name: requirements-design
description: Requirements discovery and feature design for new products and features — elicits latent requirements before implementation, using a structured question checklist (persona, problem, scope, non-functional needs, edge cases, success metrics) and produces a short confirmed brief. Load for 要件定義, 新機能, 仕様策定, プロダクト設計, feature requests, new products, specifications, and any design task before implementation starts.
origin: Local
---

# Requirements Design

Never implement from a restated request. Elicit latent requirements first.

## When to Activate

- User requests a new feature, product, or screen
- A request is phrased as a solution ("add a button that does X") rather than a problem
- Requirements feel ambiguous, underspecified, or technically premature
- A 要件定義 step is needed before architecture or code

---

## The Core Rule

A request like "add CSV export" is a proposed solution, not a requirement. The real requirement is "users need to get their data out of the system in a format their tools can consume." Those are different — the right solution might be CSV, or API, or a Slack notification, depending on who the user is and what tool they use.

**Always surface the actual problem before picking a solution.**

---

## Intake from bizdev-strategy

If this skill is triggered from a bizdev-strategy handoff, load that document (`docs/strategy/<product>-strategy.md`) — Section 5 feature proposals and Section 2 evidence — first; every feature in the Requirements Brief must cite its evidence source from that document. If a bizdev-strategy document exists for this product, do not accept undocumented feature requests.

## Discovery Question Checklist

Work through these before writing a line of design or code. Not every question applies to every request — use judgment, but default to asking rather than assuming.

### 1. Users and Personas
- Who are the specific users of this feature? (role, technical level, frequency of use)
- Are there multiple user types with different needs?
- What does success look like from their perspective?
- **Primary job-to-be-done**: What are they hiring this product to do that they cannot do conveniently today? State it as a job, not a feature.
- **Latent needs probe**: Is there an unarticulated need the user would recognize as true once named? Propose 1-2 candidates and confirm with the user before proceeding.

### 2. The Problem Being Solved
- What is the user trying to accomplish? (goal, not solution)
- What are they doing today instead? (workaround, manual process, competitor)
- How painful is the current situation? (critical blocker vs. minor inconvenience)
- Is this a latent need (user hasn't articulated it yet) or an explicit request?

### 3. Scope Boundaries and Explicit Non-Goals
- What is definitely in scope?
- What is explicitly NOT in scope for this iteration?
- What related problems are we intentionally deferring?

### 4. Non-Functional Requirements
- Performance: response time targets, throughput, concurrent users
- Security and authorization: who can see/do what?
- Scale: how large is the data set, how many users, how often?
- Internationalization (i18n): multi-language, timezone, number format?
- Accessibility (a11y): WCAG level required?
- Browser/device support: mobile-first, specific OS/browser?

### 5. Edge Cases and Failure Modes
- What happens when the input is empty, null, or malformed?
- What is the behavior when a dependency (API, DB) is unavailable?
- What are the concurrency implications (two users editing simultaneously)?
- What happens if the user navigates away mid-flow?

### 6. Success Criteria and Metrics
- How will we know this feature worked? (specific, measurable)
- What are the acceptance criteria for "done"?
- Which metrics will we track post-launch?

### 7. Business Context

These questions are mandatory for any new product or major feature — skip only for pure internal tooling where monetization is clearly N/A.

- **Monetization model**: How does this product make money? (subscription, usage-based, one-time, freemium, B2B seat license, marketplace take rate, other)
- **Paying customer vs. end user**: Are the people who pay and the people who use the same? If not, who is each, and whose needs take priority in a conflict?
- **Competitive alternative**: What does the user do today instead? Include "do nothing" as an explicit option — why would they switch?
- **Regulatory / compliance constraints** (JP defaults): 個人情報保護法 (APPI) for personal data; 特定商取引法 for e-commerce disclosures; 資金決済法 for payments/points/prepaid value; 電気通信事業法 外部送信規律 for cookie/analytics consent; インボイス制度 for invoicing. Add GDPR/CCPA/SOC 2 when targeting overseas customers.
- **Time-to-market pressure**: Is there a deadline, launch window, or competitive event that forces scope reduction? What is the minimum viable scope for that date?

### 8. Integration Constraints
- What existing systems, APIs, or data sources does this touch?
- What contracts (API shape, DB schema, event format) must remain stable?
- Are there external dependencies (third-party services, webhooks) that affect timing?

---

## Design Guidance

Once requirements are confirmed, apply these principles before producing an architecture or implementation plan:

### Clean Architecture Boundaries
Separate concerns at natural seams:
- UI / presentation: how it looks and is interacted with
- Application: orchestration of use cases
- Domain: business rules and entities
- Infrastructure: database, external APIs, file system

Avoid mixing these layers. A UI component should not contain SQL; a repository should not contain business logic.

### YAGNI & DRY
Apply CLAUDE.md Core Principles: build only what confirmed requirements demand; extract duplication only once it is real, not speculative.

### Document Decisions + Alternatives Briefly
For each non-trivial design decision, record:
- What was chosen
- What was considered and rejected
- Why (constraint, tradeoff, or evidence)

This goes in a DECISIONS.md or inline in the requirements brief, not just in Slack.

---

## Output: Requirements Brief

After discovery, produce a short brief the user confirms **before implementation starts**.

**MUST**: write the brief to `docs/requirements/<feature>-brief.md` — downstream gates look for it at this path.

```markdown
## Requirements Brief: <Feature Name>

**Problem**: [1-2 sentences describing the real user problem]

**Users**: [Persona(s), role, frequency of use]

**In Scope**:
- [Concrete deliverable 1] — Evidence: [source document + section, e.g. "market-research §3, n=200 survey"]
- [Concrete deliverable 2] — Evidence: [...]

**Explicitly Out of Scope**:
- [What we are not doing and why]

**Non-Functional**:
- Performance: [specific target]
- Auth: [who can access]
- Scale: [data size, concurrency]
- i18n/a11y: [requirements or N/A]

**Edge Cases**:
- [Edge case 1 → expected behavior]
- [Edge case 2 → expected behavior]

**Success Criteria**:
- [Measurable criterion 1]
- [Measurable criterion 2]

**Integration Points**:
- [System/API, contract constraint]

**Open Questions**:
- [Unresolved item requiring decision before implementation]

**Design Decisions**:
- [Decision made, alternatives considered, rationale]

Confirmed by user: [write only after explicit user confirmation — then: yes (<date>)]
```

Get explicit confirmation on this brief before architecture, code, or detailed design. A "yes this looks right" from the user is the gate. Only after that confirmation, write the final line `Confirmed by user: yes (<date>)` — never pre-fill it. Downstream gates check for the exact key `Confirmed by user:`.

### Delivery

If the user's Notion workspace is connected (Notion MCP), offer to publish the confirmed Requirements Brief as a Notion page before implementation begins — it becomes the single source of truth that engineering and design work traces back to.

---

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| Implementing from a solution-phrased request | Misses the actual need; builds the wrong thing | Reframe as a problem, ask "why?" |
| Assuming non-functional requirements | Performance, auth, and scale assumptions are often wrong | Ask explicitly |
| Skipping edge cases | Edge cases become bugs or security issues in production | Enumerate at least 3 failure modes |
| "We'll figure out scope later" | Scope creep, rework, misaligned expectations | Define scope and non-goals before the first line of code |
| Treating the brief as bureaucracy | Skipping the brief for "small" features is where requirements rot starts | Brief can be short, but it must exist |
