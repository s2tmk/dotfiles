# dotfiles

Configuration for the development environment, currently centered on the
Claude Code harness (`.claude/`).

## Setup

```bash
# 1. Clone
git clone git@github.com:s2tmk/dotfiles.git ~/dotfiles

# 2. Create symlinks (idempotent — safe to re-run any time)
cd ~/dotfiles
./install.sh
```

`install.sh` symlinks every top-level entry of `dotfiles/.claude/` into
`~/.claude/`. Already-correct links are skipped, stale or dangling links are
re-pointed, and real files in the way are backed up as `*.bak.<timestamp>`.
Re-run it after pulling whenever new top-level files or directories were added.

## Git management policy for ~/.claude

- `~/.claude` itself is **not** a git repository. It mixes versionable config
  with runtime state (session history, project data, plugin caches,
  credentials) that must never be committed.
- Everything worth versioning lives in `dotfiles/.claude/` and is linked into
  place entry by entry. Rolling back config = `git revert` here; runtime state
  is untouched.
- `settings.local.json` and `.credentials.json` stay machine-local (gitignored).

See [.claude/README.md](.claude/README.md) for the harness architecture,
kill switches, and operating notes.
