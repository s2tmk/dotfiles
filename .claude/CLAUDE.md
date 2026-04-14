## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Workflow Orchestration

### Plan First

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Break subtasks small enough to complete in under 50% context

### Subagent Strategy

- Use subagents liberally to keep main context window clean
- One task per subagent for focused execution
- Use the **Command -> Agent -> Skill** pattern for orchestration:
  - Command = entry point (slash command)
  - Agent = autonomous executor with preloaded skills
  - Skill = reusable knowledge/instructions
- Subagents **cannot** invoke other subagents via bash. Use the Agent tool:
  ```
  Agent(subagent_type="agent-name", description="...", prompt="...")
  ```

### Self-Improvement Loop

- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Review lessons at session start for relevant project

### Verification Before Done

- Never mark a task complete without proving it works
- Ask yourself: "Would a staff engineer approve this?"

### Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Go fix failing CI tests without being told how

## Context Management

- Keep CLAUDE.md under 200 lines per file for reliable adherence
- Perform manual `/compact` at ~50% context usage
- Avoid the last 20% of context window for large-scale refactoring
- Use `/doctor` for diagnostics when something feels wrong

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Track Progress**: Mark items complete as you go
3. **Capture Lessons**: Update `tasks/lessons.md` after corrections
