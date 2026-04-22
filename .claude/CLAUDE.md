## Workflow Orchestration

### 1. Plan Node Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity
- On Opus 4.6+: plan scope and intent, NOT granular sprint-level decomposition — the model can sustain coherent execution for 2+ hours without step-by-step scaffolding

### 2. Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Generator-Evaluator Separation (GAN Pattern)

Self-evaluation is unreliable — agents identify problems then rationalize them as non-critical. Separate generation from evaluation:

- **Generator**: The main agent (or subagent) doing the work
- **Evaluator**: An independent subagent that judges the output without seeing the generation process
- Use code-reviewer / security-reviewer / typescript-reviewer as evaluators — they must NOT receive the generator's self-assessment
- Evaluator must have hard thresholds: any criterion below threshold = fail + detailed feedback
- Anti-pattern to watch for: evaluator identifies real issues then says "overall this is acceptable" — configure evaluator prompts to forbid rationalization

When to use full GAN pattern (cost-justified):
- Tasks exceeding the model's reliable baseline (multi-file features, architecture changes)
- Security-sensitive code (auth, payments, user data)
- UI/UX work requiring subjective quality judgment

When single-pass self-check is sufficient:
- Simple bug fixes with binary pass/fail verification (tests pass or don't)
- Single-file edits with clear correctness criteria
- Documentation updates

### 4. Self-Improvement Loop

- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 5. Verification Before Done

- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- For non-trivial work: spawn an independent evaluator subagent instead of self-assessing
- Run tests, check logs, demonstrate correctness
- Evaluator must test deeply — click through nested features, not just golden path

### 6. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 7. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

### 8. Context Window Management

Context degradation is the #1 failure mode in long-running sessions:

- **Monitor context usage**: When approaching ~70% of context, proactively decide: compact or reset
- **Prefer context reset over compaction** for multi-file features: write structured handoff artifacts (what's done, what's next, key decisions, file paths) then start fresh
- **Use compaction** for single-concern sessions where earlier context is summarizable without loss
- **Handoff artifacts live in files**, not conversation: one agent writes, the next reads — this maintains faithfulness to specifications
- **Never push through context anxiety**: If you feel pressure to wrap up prematurely, that's the signal to reset context, not to rush

### 9. Harness Assumption Auditing

Every rule, hook, and workflow in this configuration encodes an assumption about what the model can't do reliably on its own. These assumptions decay as models improve.

- When a new model is in use: question whether each constraint is still load-bearing
- If a guardrail fires but feels unnecessary, flag it — don't just work around it
- Prefer removing constraints that the model handles natively over adding more scaffolding
- The design space moves, not shrinks: freed capacity should enable more ambitious work, not just less overhead

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` — scope and intent over granular checkboxes
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections
7. **Long runs (30min+)**: Skip per-step tracking; do a single-pass evaluation at the end

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
