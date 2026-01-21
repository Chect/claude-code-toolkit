# Proactive Handoff

Automatically track session state for continuity across Claude Code sessions. When a session ends unexpectedly (context limit, interruption), the next session sees what was happening and what to do next.

## What It Does

- **Tracks modified files** — Auto-captured when you Edit/Write files
- **Tracks next steps** — What to do if interrupted (manually updated)
- **Saves state before compaction** — PreCompact hook backs up state
- **Loads previous state on start** — SessionStart hook displays previous session's state

## Files

| File | Purpose |
|------|---------|
| `proactive-handoff.sh` | Main script with all commands |
| `post-edit-hook.sh` | Extracts file path from hook JSON input |
| `settings-snippet.json` | Hook configuration to add to your settings.json |
| `DESIGN.md` | Detailed design documentation |

## Installation

### 1. Copy scripts to your project

```bash
# From within your project directory
mkdir -p .claude/hooks
cp proactive-handoff.sh .claude/hooks/
cp post-edit-hook.sh .claude/hooks/
chmod +x .claude/hooks/proactive-handoff.sh
chmod +x .claude/hooks/post-edit-hook.sh
```

### 2. Add hooks to settings.json

**Option A: If you already have a settings.json**

Merge the contents of `settings-snippet.json` into your `.claude/settings.json` (or `.claude-shared/settings.json`).

**Option B: If you don't have a settings.json yet**

```bash
# Create .claude directory if it doesn't exist
mkdir -p .claude

# Copy the settings snippet
cp settings-snippet.json .claude/settings.json
```

### 3. Configure SessionStart hook

You need a SessionStart hook to load previous state. Choose one of these options:

**Option A: Create a standalone SessionStart script**

```bash
# Create the script
cat > .claude/hooks/session-start.sh << 'EOF'
#!/bin/bash
# SessionStart hook - loads previous session state

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
EOF

# Make it executable
chmod +x .claude/hooks/session-start.sh
```

Then add to `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$(git rev-parse --show-toplevel)\" && .claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

**Option B: Add to existing SessionStart hook**

If you already have a SessionStart hook, add this code to it:

```bash
# Load previous session state if exists, or initialize new one
if [ -f ".claude/session-state.md" ]; then
    echo "=== Session State (previous session) ==="
    cat ".claude/session-state.md"
    echo ""
    # Initialize fresh state for new session
    .claude/hooks/proactive-handoff.sh init 2>/dev/null || true
elif [ -f ".claude/hooks/proactive-handoff.sh" ]; then
    .claude/hooks/proactive-handoff.sh init 2>/dev/null || true
fi
```

### 4. Add to .gitignore

```bash
# Add these lines to your .gitignore
echo ".claude/session-state.md" >> .gitignore
echo ".claude/session-state.md.bak" >> .gitignore
echo ".claude/session-history.log" >> .gitignore
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

## See Also

- `DESIGN.md` - Detailed design documentation and rationale
- Claude Code hooks documentation
- Git hooks for integration options
