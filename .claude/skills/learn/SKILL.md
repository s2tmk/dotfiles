---
name: learn
description: Distill a correction or hard-won insight from the current session into a one-line prevention rule, saved to the project MEMORY.md or promoted to skills/learned/ when it applies across projects. Invoke after a user correction, a repeated mistake, or when the user says /learn.
---

# Learn — persist feedback as prevention rules

Convert a correction or discovery from this session into a rule that prevents recurrence.

## Procedure

1. **State what happened in one sentence**: the user's correction, a wrong assumption, a
   repeated mistake. Write what to change next time — not the story.
2. **Decide where it belongs**:
   - Project-specific (terminology, design decisions, data sources, review procedures)
     → append one line to the project's `MEMORY.md`, matching its existing format
   - Bizdev/research lessons (wrong source selection, unlabeled estimates, recommendations
     without evidence) → under `## Research Lessons` in the project `MEMORY.md`
     (market facts are project-specific)
   - Cross-project reusable patterns (tool pitfalls, workflow improvements)
     → create `~/.claude/skills/learned/<kebab-name>/SKILL.md`
3. **Write it as a rule**: "When X, always Y" / "Never Z — do W instead".
   Add a one-phrase reason in parentheses unless it is obvious.
4. **Check for duplicates**: if MEMORY.md / learned/ already covers the same point,
   strengthen or correct the existing entry instead of adding a new one. Delete rules
   that turned out to be wrong.

## learned/ skill format

```markdown
---
name: <kebab-case-name>
description: <one sentence with concrete trigger words that make clear when this fires>
---

# <Title>

**Rule**: <one-line rule>
**Why**: <one-line reason>
**Example**: <minimal example of the situation it applies to>
```

## Quality bar

- Save only what changes future behavior. No impressions, narratives, or obvious generalities.
- One rule per file. Split it when it grows.
- A learned skill unused for 3 months is a deletion candidate — review it and remove it.
