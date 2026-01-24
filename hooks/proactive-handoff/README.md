# Proactive Handoff

Automatically track session state for continuity across Claude Code sessions. When a session ends unexpectedly (context limit, interruption), the next session sees what was happening and what to do next.

## What It Does

- **Tracks modified files** — Auto-captured when you Edit/Write files
- **Tracks next steps** — What to do if interrupted (manually updated)
- **Integrates with TodoWrite** — Persistent tasks via .claude/tasks.md + TodoWrite UI
- **Preserves state through compaction** — PreCompact hook saves backup AND re-injects state into compaction summary
- **Loads previous state on start** — SessionStart hook displays previous session's state

## Files

| File | Purpose |
|------|---------|
| `proactive-handoff.sh` | Main script with all commands |
| `post-edit-hook.sh` | Extracts file path from hook JSON input |
| `session-start.sh` | SessionStart hook to load previous state |
| `settings-snippet.json` | Complete hook configuration for settings.json |
| `tasks-template.md` | Template for TodoWrite-integrated task tracking |
| `DESIGN.md` | Detailed design documentation |
| `TODOWRITE-INTEGRATION.md` | TodoWrite + tasks.md integration guide |

## Installation

### 1. Copy scripts to your project

```bash
# From within your project directory
mkdir -p .claude/hooks
cp proactive-handoff.sh .claude/hooks/
cp post-edit-hook.sh .claude/hooks/
cp session-start.sh .claude/hooks/
chmod +x .claude/hooks/proactive-handoff.sh
chmod +x .claude/hooks/post-edit-hook.sh
chmod +x .claude/hooks/session-start.sh
```

### 2. Configure hooks in settings.json

The `settings-snippet.json` file contains all three required hooks (SessionStart, PostToolUse, PreCompact).

**Option A: If you already have a settings.json**

Merge the contents of `settings-snippet.json` into your `.claude/settings.json` (or `.claude-shared/settings.json`).

**Option B: If you don't have a settings.json yet**

```bash
# Create .claude directory if it doesn't exist
mkdir -p .claude

# Copy the complete settings snippet
cp settings-snippet.json .claude/settings.json
```

**Option C: If you have existing hooks**

Add the three hook configurations from `settings-snippet.json` to your existing hooks:
- `SessionStart` - Loads previous session state (calls `session-start.sh`)
- `PostToolUse` - Tracks file modifications (calls `post-edit-hook.sh`)
- `PreCompact` - Saves state backup (calls `proactive-handoff.sh save`)

### 3. (Optional) Add persistent context files

The PreCompact hook automatically re-injects these files during compaction (if they exist):
- `.claude/context.md` - Strategic checkpoints (what was accomplished, key decisions)
- `.claude/tasks.md` - Backlog of things to do
- `.claude/claude.md` - General project context

These files are NOT managed by proactive-handoff - you maintain them manually.

Example `.claude/context.md`:
```markdown
# Context

## Latest Checkpoint
- Completed user authentication system
- Decision: Using JWT tokens for sessions

## Architecture
- Frontend: React + TypeScript
- Backend: Python FastAPI
- Database: PostgreSQL
```

Example `.claude/tasks.md`:
```markdown
# Tasks

## Todo
- [ ] Add password reset flow
- [ ] Implement rate limiting
- [ ] Write API documentation

## Done
- [x] User registration
- [x] Login/logout
```

### 4. Add to .gitignore

```bash
# Add these lines to your .gitignore (transient session files)
echo ".claude/session-state.md" >> .gitignore
echo ".claude/session-state.md.bak" >> .gitignore
echo ".claude/session-history.log" >> .gitignore

# Optional: Ignore context files if you want them project-specific (not shared)
# Note: You might want to CHECK IN context.md and tasks.md to share with team
echo ".claude/context.md" >> .gitignore    # Optional
echo ".claude/tasks.md" >> .gitignore      # Optional
echo ".claude/claude.md" >> .gitignore     # Optional
```

## Usage

### Automatic Tracking

Once installed, the hook automatically tracks:
- **File modifications** when you use Edit, Write, or NotebookEdit tools
- **State backups** before context compaction
- **Session start/end** timestamps

### Manual Commands

```bash
# Initialize fresh session state (usually automatic via SessionStart hook)
.claude/hooks/proactive-handoff.sh init

# Track a file modification (usually automatic via PostToolUse hook)
.claude/hooks/proactive-handoff.sh file "/path/to/file.c"

# Add next step (call manually when you know what's next)
.claude/hooks/proactive-handoff.sh next "Implement the foo function"

# Add multiple next steps
.claude/hooks/proactive-handoff.sh next "Run tests"
.claude/hooks/proactive-handoff.sh next "Update documentation"

# Clear next steps (call when task complete)
.claude/hooks/proactive-handoff.sh clear-next

# Save state (usually automatic via PreCompact hook)
.claude/hooks/proactive-handoff.sh save

# Cleanup old entries (removes completed agents, keeps last N files)
.claude/hooks/proactive-handoff.sh cleanup 20

# Track background agent (manual - no auto-hook yet)
.claude/hooks/proactive-handoff.sh agent-start "task-id-123" "research"
# ... agent completes ...
.claude/hooks/proactive-handoff.sh agent-stop "task-id-123"
```

### Typical Workflow

```bash
# Session starts → Previous state loads automatically
# Work on files → Modifications tracked automatically

# Manually add next steps as you plan
.claude/hooks/proactive-handoff.sh next "Implement validation logic"
.claude/hooks/proactive-handoff.sh next "Add unit tests"

# Session interrupted? Next session loads:
# - What files were modified
# - What the next steps were
# - Any running background agents

# Task complete? Clear next steps
.claude/hooks/proactive-handoff.sh clear-next
```

## Session State Format

The script creates `.claude/session-state.md`:

```markdown
# Session State

Auto-updated during session. Read at session start for continuity.

## Active Work

### Current Focus
- None

### Modified Files
- `/path/to/file1.c` (2026-01-18 19:45:00)
- `/path/to/file2.h` (2026-01-18 19:50:00)

### Running Agents
<!-- Background agents still executing -->

### Next Steps
- Implement the validation logic
- Run tests
- Update documentation

## Session Info

- **Started:** 2026-01-18 19:30:00
- **Last Updated:** 2026-01-18 19:55:00

## Notes

<!-- Manual notes can be added here -->
```

## TodoWrite Integration

Claude Code's built-in TodoWrite tool creates task checklists in the UI, but **todos don't persist across sessions**. This system integrates TodoWrite with persistent task storage:

### Quick Start

```bash
# Create tasks file
cp .claude/hooks/proactive-handoff/tasks-template.md .claude/tasks.md

# Edit tasks
cat > .claude/tasks.md << 'EOF'
# Tasks

## Active Tasks
- [ ] Implement user authentication
- [ ] Add input validation
- [ ] Write tests

## Completed
- [x] Set up database
EOF
```

### How It Works

1. **SessionStart** - Loads `.claude/tasks.md` and instructs Claude to create TodoWrite todos
2. **During work** - Claude uses TodoWrite for visual progress tracking
3. **Completing tasks** - Claude updates `.claude/tasks.md` as tasks finish
4. **PreCompact** - Re-injects tasks.md and reminds Claude to save current state

**Result**: TodoWrite UI during session + persistent tasks.md across sessions

See [TODOWRITE-INTEGRATION.md](TODOWRITE-INTEGRATION.md) for complete guide.

## How State Survives Compaction

**Critical behavior**: SessionStart hooks do NOT run after autocompact - they only run when starting a brand new session. This means any state loaded at session start would be lost when context gets compacted.

**Solution**: The PreCompact hook does TWO things:
1. Saves backup to `.claude/session-state.md.bak`
2. **Outputs all context files** - These get injected into the compaction summary, preserving state throughout the session:
   - `session-state.md` (always) - Auto-tracked file modifications and next steps
   - `context.md` (if exists) - Strategic checkpoints and decisions
   - `tasks.md` (if exists) - TodoWrite-integrated task tracking
   - `claude.md` (if exists) - General project context

Without the PreCompact re-injection, Claude would "forget" all these files after compaction.

## Design Philosophy

**Tasks should fit in one context window.** This system helps with unexpected interruptions, not with multi-session work. If a task needs multiple sessions, break it down into smaller tasks.

The "Next Steps" feature is the most important — it answers "where was I?" instantly after an interruption.

## Limitations

- **macOS only** — Uses `sed -i ''` syntax (Linux needs `sed -i`)
- **Agent tracking not automatic** — The agent-start/agent-stop commands work manually but aren't wired to hooks yet (Claude Code would need SubagentStart/SubagentStop hooks)
- **Manual next steps** — You need to manually call `proactive-handoff.sh next "step"` to add next steps

## Files Created

| File | Gitignore? | Purpose |
|------|------------|---------|
| `.claude/session-state.md` | Yes | Live session state |
| `.claude/session-state.md.bak` | Yes | Backup before compaction |
| `.claude/session-history.log` | Yes | Audit trail of cleanups |

## Troubleshooting

### State not loading at session start

Check that:
1. SessionStart hook is configured in settings.json
2. The hook script is executable (`chmod +x .claude/hooks/session-start.sh`)
3. You're in a git repository (script uses `git rev-parse --show-toplevel`)

### Files not being tracked

Check that:
1. PostToolUse hook is configured in settings.json
2. `post-edit-hook.sh` is executable
3. You have `jq` installed (`brew install jq` or `apt install jq`)

### "sed: command not found" or sed errors

On Linux, change `sed -i ''` to `sed -i` in both scripts:
```bash
# macOS
sed -i '' "pattern" file

# Linux
sed -i "pattern" file
```

## Advanced Usage

### Customizing Context Re-injection

The PreCompact hook automatically re-injects:
- `.claude/session-state.md` (always)
- `.claude/context.md` (if exists)
- `.claude/tasks.md` (if exists)
- `.claude/claude.md` (if exists)

To add more context files, edit the PreCompact command in your settings.json:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$(git rev-parse --show-toplevel)\" && .claude/hooks/proactive-handoff.sh save && echo '' && echo '=== Session State ===' && cat .claude/session-state.md 2>/dev/null || true && echo '' && if [ -f '.claude/claude.md' ]; then echo '=== Context ===' && cat .claude/claude.md; fi && if [ -f '.claude/tasks.md' ]; then echo '' && echo '=== Tasks ===' && cat .claude/tasks.md; fi"
          }
        ]
      }
    ]
  }
}
```

**Why this matters**: SessionStart hooks do NOT run after autocompact. Without re-injection, Claude would "forget" these files after compaction. The PreCompact output gets preserved in the compaction summary.

### Automatic cleanup on PreCompact

Add cleanup to your PreCompact hook:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$(git rev-parse --show-toplevel)\" && .claude/hooks/proactive-handoff.sh cleanup 20 && .claude/hooks/proactive-handoff.sh save"
          }
        ]
      }
    ]
  }
}
```

This will keep only the 20 most recent files and remove completed agents before each compaction.

### Integration with git commits

You could clear the "Modified Files" list after committing (since files are now in git history):

```bash
# After git commit
.claude/hooks/proactive-handoff.sh cleanup 0  # Remove all file entries
```

Or add as a post-commit git hook.

## Optional: Loading Additional Context Files

The included `session-start.sh` script loads only `session-state.md`. If you also maintain `context.md` (for strategic checkpoints) or `tasks.md` (for backlog), you can modify `session-start.sh` to load them:

```bash
#!/bin/bash
# SessionStart hook - loads previous session state
# Part of proactive-handoff system

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Load previous session state if exists, or initialize new one
if [ -f ".claude/session-state.md" ]; then
    echo "=== Session State (previous session) ==="
    cat ".claude/session-state.md"
    echo ""
    # Initialize fresh state for new session
    .claude/hooks/proactive-handoff.sh init 2>/dev/null || true
elif [ -f ".claude/hooks/proactive-handoff.sh" ]; then
    # No previous state, just initialize
    .claude/hooks/proactive-handoff.sh init 2>/dev/null || true
fi

# Optional: Load context.md (strategic checkpoint)
if [ -f ".claude/context.md" ]; then
    echo "=== Context (last checkpoint) ==="
    cat ".claude/context.md"
    echo ""
fi

# Optional: Load tasks.md (backlog)
if [ -f ".claude/tasks.md" ]; then
    echo "=== Tasks (backlog) ==="
    cat ".claude/tasks.md"
    echo ""
fi
```

**Note:** These files are not part of proactive-handoff. You manage them manually:
- `context.md` - Strategic checkpoints (what was accomplished, key decisions)
- `tasks.md` - Backlog of things to do eventually

## See Also

- `DESIGN.md` - Detailed design documentation and rationale
- Claude Code hooks documentation
- Git hooks for integration options
