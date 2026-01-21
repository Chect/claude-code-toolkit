# Proactive Handoff Design

## Core Principle

**Tasks should complete in a single context window.** If they don't, the task needs further breakdown—not a multi-window persistence mechanism.

This hook system helps with **unexpected interruptions** (context limit reached, session crash), not with planned multi-session work.

---

## What We Track

The `session-state.md` file maintains live operational state:

| What | How | Purpose |
|------|-----|---------|
| **Modified Files** | Automatic (PostToolUse hook) | Know what changed this session |
| **Running Agents** | Manual or hook-based | Track background work |
| **Next Steps** | Manual | Answer "where was I?" after interruption |
| **Session Timestamps** | Automatic | When session started and last updated |

---

## File Structure

```markdown
session-state.md
─────────────────
"What's happening right now"

- Modified files (auto-tracked)
- Next steps (manually added)
- Running agents (for background tasks)
- Session timestamps
```

### Update Triggers

| Section | Trigger | Mechanism |
|---------|---------|-----------|
| Modified Files | Every Edit/Write | PostToolUse hook → post-edit-hook.sh |
| Running Agents | Agent start/stop | Manual or future hook integration |
| Next Steps | Manual | `proactive-handoff.sh next "step"` |
| Timestamps | Any update | Automatic |

---

## Implementation

### Hooks Configured

1. **PostToolUse** (Edit/Write/NotebookEdit)
   - Extracts file path from tool input
   - Calls `proactive-handoff.sh file <path>`
   - Auto-tracks file modifications

2. **PreCompact** (before context window compaction)
   - Calls `proactive-handoff.sh save`
   - Backs up state to `.claude/session-state.md.bak`

3. **SessionStart** (when new session begins)
   - Displays previous session state if exists
   - Initializes fresh state file

### Files Created

| File | Gitignore? | Purpose |
|------|------------|---------|
| `.claude/session-state.md` | Yes | Live session state |
| `.claude/session-state.md.bak` | Yes | Backup before compaction |
| `.claude/session-history.log` | Yes | Audit trail of cleanups |

---

## Design Decisions

### What We Track

| Feature | Rationale |
|---------|-----------|
| **Next Steps** | Critical when interrupted; immediately answers "where was I?" |
| **File tracking** | Know what changed this session without checking git |
| **Cleanup mechanism** | Prevent state bloat over long sessions |
| **History log** | Audit trail for debugging |

### What We Don't Track

| Feature | Rationale |
|---------|-----------|
| **Decision Log** | Tasks fit in one window; decisions don't span sessions |
| **Session Goals** | Quick sessions by default; goals are implicit in the task |
| **Problems/Solutions** | Would require manual effort; defer until need is clear |

---

## Agent Tracking

The `agent-start` and `agent-stop` commands exist but aren't automatically wired up:

```bash
# Manual usage
.claude/hooks/proactive-handoff.sh agent-start "task-abc123" "background-research"
# ... agent runs ...
.claude/hooks/proactive-handoff.sh agent-stop "task-abc123"
```

**Future Integration:**
If Claude Code adds SubagentStart/SubagentStop hooks (or similar), these commands would be automatically triggered to track background agents.

**Current Status:**
Manual tracking only. The commands work but require explicit invocation.

---

## Cleanup Strategy

Over long sessions, the file list can grow large. The cleanup command manages this:

```bash
# Remove completed agents, keep last 20 file entries
.claude/hooks/proactive-handoff.sh cleanup 20
```

**What it does:**
1. Removes all completed agents (status shows "completed")
2. Keeps only the N most recent file entries
3. Logs removed entries to `session-history.log` for audit

**When to run:**
- Manually when state file gets large
- Could be added to PreCompact hook for automatic cleanup

---

## Session Workflow

### Normal Flow

```
Session Start
    ↓
Load previous state (if exists)
    ↓
Initialize fresh state
    ↓
Work happens:
    - Files edited → auto-tracked
    - Next steps added manually
    - Agents tracked (manual)
    ↓
Session ends normally
```

### Interrupted Flow

```
Session Start
    ↓
Load previous state
    ├─ See: Modified files
    ├─ See: Next steps  ← Critical for recovery
    └─ See: Running agents
    ↓
Resume work or adjust plan
```

### Context Compaction

```
Context limit approaching
    ↓
PreCompact hook triggers
    ↓
Save state to backup
    ↓
Compaction happens
    ↓
State file persists (not in conversation context)
    ↓
Continue working
```

---

## Example Session State

```markdown
# Session State

Auto-updated during session. Read at session start for continuity.

## Active Work

### Current Focus
- None

### Modified Files
- `/src/main.c` (2026-01-18 19:45:00)
- `/include/utils.h` (2026-01-18 19:50:00)

### Running Agents
- **research-abc123** (background-research) - started 2026-01-18 19:40:00

### Next Steps
- Implement the validation logic in main.c
- Run tests with `make test`
- Check for memory leaks

## Session Info

- **Started:** 2026-01-18 19:30:00
- **Last Updated:** 2026-01-18 19:55:00

## Notes

<!-- Manual notes can be added here -->
```

---

## Limitations

1. **macOS only** - Uses `sed -i ''` syntax
   - Linux needs `sed -i` (without empty string)
   - Could be made portable with conditional check

2. **Agent tracking not automatic** - Commands exist but need hook integration
   - SubagentStart/SubagentStop hooks don't exist yet in Claude Code
   - Currently manual invocation only

3. **Next steps are manual** - Claude should update these during work
   - Could prompt Claude to update next steps periodically
   - Or add as part of tool use prompts

4. **No git integration** - Files tracked independently of commits
   - Shows session edits, not what's committed
   - Could integrate with git hooks for commit awareness

---

## Future Enhancements

These are potential improvements, not current features:

1. **Automatic cleanup on PreCompact**
   - Add cleanup call to PreCompact hook
   - Prevent state bloat automatically

2. **Git awareness**
   - Clear "Modified Files" after git commit
   - They're committed, no longer "in progress"

3. **Task type detection**
   - Detect when task is growing beyond one session
   - Prompt user to break it down

4. **Agent hook integration**
   - When Claude Code adds agent lifecycle hooks
   - Automatically track agent start/stop

---

## Changelog

### 2026-01-20
- Cleaned up for public release
- Removed unimplemented feature discussions
- Focused on current implementation
- Clarified what's automatic vs. manual

### 2026-01-18
- Initial implementation
- File tracking via PostToolUse hook
- Next steps for interruption recovery
- Cleanup mechanism and history log
