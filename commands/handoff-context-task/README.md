# Handoff Context Task Command

A slash command that creates a detailed task progress report for multi-session work.

## What It Does

When you run `/handoff-context-task`, Claude creates/updates `.claude/current-task.md` with a comprehensive task report including:

1. **Task title and goal** - End result and acceptance criteria
2. **Overall progress** - High-level status and phases remaining
3. **Architecture/design decisions** - Decisions made and WHY (prevents re-litigating)
4. **What's been completed** - Done items with file:line references
5. **What's in progress** - Current work item and immediate next step
6. **What's remaining** - Ordered list of remaining work
7. **Key code locations** - Map of relevant files and line numbers
8. **Reference materials** - Docs, specs, datasheets
9. **Known issues and constraints** - Problems and limitations discovered
10. **Test procedure** - How to verify completed work
11. **Session log** - Running log of what each session accomplished

## Why a Separate File?

Long-running tasks are stored in `.claude/current-task.md`, separate from:
- `.claude/context.md` — general session context (short-term)
- `.claude/current-bug.md` — bug investigations (medium-term)

This means:
- **Persists across many sessions**: Designed for tasks spanning dozens of context windows
- **Clear when done**: Delete or archive `current-task.md` when the task is complete
- **No pollution**: General context and bug tracking stay clean
- **Parallel tracking**: All three context files can coexist

## Installation

```bash
cp handoff-context-task.md ~/.claude/commands/
# or for project-specific:
cp handoff-context-task.md .claude/commands/
```

## Usage

```
/handoff-context-task
```

Run this before `/clear` or ending a session when working on a multi-session task.

To clear a completed task:
```bash
rm .claude/current-task.md
```

## Companion: Startup Hook

To auto-load the task context at session start, add this to your startup hook (e.g., `session-start-hook.sh`):

```bash
# Output current-task.md if exists (long-running task context)
if [ -f ".claude/current-task.md" ]; then
    echo "" | tee /dev/tty
    echo "--- current-task.md ---" | tee /dev/tty
    cat ".claude/current-task.md" | tee /dev/tty
fi
```

And add this to your CLAUDE.md startup checklist:

```markdown
1. **Check for context files:** Read `.claude/context.md`, `.claude/current-bug.md`, and `.claude/current-task.md`
   - `context.md` = general session context
   - `current-bug.md` = active bug investigation
   - `current-task.md` = long-running multi-session task
```

## Companions

- [handoff-context](../handoff-context/) — general session context
- [handoff-context-bug](../handoff-context-bug/) — bug investigation context
