# Handoff Context Bug Command

A slash command that creates a detailed bug investigation report for session continuity.

## What It Does

When you run `/handoff-context-bug`, Claude creates/updates `.claude/current-bug.md` with a comprehensive bug report including:

1. **Bug title and symptoms** - Exact reproduction steps
2. **Root cause analysis** - Code paths, function chains with file:line references
3. **State machine context** - States, transitions, flag values
4. **Changes made** - Every file:line changed, old vs new code, and WHY
5. **Test results** - What worked and what didn't
6. **Debug traces** - Debug output added and what to look for
7. **Open questions** - What's still unknown
8. **Key code locations** - Every file:line referenced
9. **Reference implementation** - Original behavior analysis
10. **Test procedure** - Step-by-step to reproduce and verify

## Why a Separate File?

Bug investigations are stored in `.claude/current-bug.md`, separate from `.claude/context.md` (general session context). This means:

- **Clear when done**: Delete `current-bug.md` when the bug is resolved — no surgery on context.md
- **No pollution**: General context stays clean and focused
- **Parallel tracking**: You can have both active session context and a bug investigation

## Installation

```bash
cp handoff-context-bug.md ~/.claude/commands/
# or for project-specific:
cp handoff-context-bug.md .claude/commands/
```

## Usage

```
/handoff-context-bug
```

Run this before `/clear` or ending a session when actively debugging a bug.

To clear a resolved bug:
```bash
rm .claude/current-bug.md
```

## Companion: Startup Hook

To auto-load the bug context at session start, add this to your startup hook (e.g., `session-start-hook.sh`):

```bash
# Output current-bug.md if exists (separate from general context)
if [ -f ".claude/current-bug.md" ]; then
    echo "" | tee /dev/tty
    echo "--- current-bug.md ---" | tee /dev/tty
    cat ".claude/current-bug.md" | tee /dev/tty
fi
```

And add this to your CLAUDE.md startup checklist:

```markdown
1. **Check for context files:** Read `.claude/context.md` and `.claude/current-bug.md`
   - `context.md` = general session context
   - `current-bug.md` = active bug investigation
```

## Companion: handoff-context

Use alongside [handoff-context](../handoff-context/) for general session context. The two commands write to different files and don't interfere with each other.
