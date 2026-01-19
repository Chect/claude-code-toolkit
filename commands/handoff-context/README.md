# Handoff Context Command

A slash command that creates a context summary file for session continuity.

## What It Does

When you run `/handoff-context`, Claude creates/updates `.claude/context.md` with:

1. **Immediate issues** - Blockers or things needing attention
2. **Work in progress** - Current state of ongoing work
3. **Exact workflow commands** - Commands needed to continue (build, test, deploy)
4. **Completed this session** - Summary of changes made
5. **Pending items** - What still needs to be done
6. **Recommendations** - Suggested next steps

## Why Use This

- **Session continuity**: Context is preserved across `/clear` or new sessions
- **Onboarding**: New sessions start with full context
- **Documentation**: Creates a running log of session work

## Installation

```bash
cp handoff-context.md ~/.claude/commands/
# or for project-specific:
cp handoff-context.md .claude/commands/
```

## Usage

```
/handoff-context
```

Run this before `/clear` or ending a session.

## Companion: Startup Script

For full continuity, add this to your CLAUDE.md or startup hook:

```markdown
## Startup Checklist
1. Check for `.claude/context.md` - if exists, read and summarize
2. Continue from where last session left off
```
