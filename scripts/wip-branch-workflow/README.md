# WIP Branch Workflow

A startup script that ensures Claude always works on a work-in-progress branch, protecting your main branch from messy intermediate commits.

## The Pattern

1. Claude works on `claude-wip-$USER` branch
2. Makes frequent checkpoint commits (messy, numerous)
3. When work is complete, squash-merge to main (clean, single commit)
4. Reset wip branch to main, continue

## What the Script Does

On session start:

| Current State | Action |
|---------------|--------|
| On `main`, clean | Pull latest, switch to `claude-wip-$USER` |
| On `main`, dirty | Move changes to `claude-wip-$USER` (no pull) |
| On other branch | Do nothing |

## Installation

### 1. Copy the script

```bash
mkdir -p .claude/scripts
cp startup.sh .claude/scripts/
chmod +x .claude/scripts/startup.sh
```

### 2. Add to CLAUDE.md

```markdown
## Startup Checklist

Run at session start:
\`\`\`bash
./.claude/scripts/startup.sh
\`\`\`
```

Or use a SessionStart hook in settings.json:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/scripts/startup.sh"
          }
        ]
      }
    ]
  }
}
```

## Companion: Squash Merge

To complete the workflow, create a `/squash-merge` command that:
1. Squash-merges wip branch to main
2. Resets wip branch to main
3. Pushes main

This gives you clean, reviewable commits on main while allowing messy work-in-progress commits.

## Customization

Edit the script to change:
- Branch naming (`claude-wip-$USER` → your pattern)
- Pull behavior (always pull, never pull, etc.)
- Additional setup steps
