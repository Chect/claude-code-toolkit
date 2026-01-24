# Native Task Tracking with Claude Code

Guide to using Claude Code's built-in task tracking system that persists across sessions.

## Overview

Claude Code has native task tracking that:
- ✅ **Persists across sessions** - Tasks survive when you close and restart Claude
- ✅ **Survives compaction** - Tasks remain after context window compression
- ✅ **Native UI** - Visual task list in terminal (toggle with Ctrl+T)
- ✅ **Automatically managed** - Claude creates and updates tasks as you work
- ✅ **No manual files** - Stored in `~/.claude/tasks/`, not in your project

## Quick Setup

### Global Tasks (Shared Across All Projects)

```bash
# Add to ~/.zshrc or ~/.bashrc
export CLAUDE_CODE_TASK_LIST_ID=default
```

This uses a single task list across all your projects.

### Project-Specific Tasks (Recommended)

```bash
# Add to ~/.zshrc or ~/.bashrc
export CLAUDE_CODE_TASK_LIST_ID=$(basename "$PWD")
```

This creates separate task lists for each project based on directory name.

### Per-Session Manual Setup

```bash
# Start Claude with specific task list
CLAUDE_CODE_TASK_LIST_ID=my-project claude

# Or use current directory name
CLAUDE_CODE_TASK_LIST_ID=$(basename "$PWD") claude
```

## How It Works

### Automatic Task Creation

Claude automatically creates tasks when working on multi-step work:

```
> Implement user authentication with email validation and password hashing

Claude creates tasks:
1. ❌ Set up authentication database schema
2. ❌ Implement email validation
3. ❌ Add password hashing with bcrypt
4. ❌ Create login endpoint
5. ❌ Add authentication middleware
```

### Task States

- ❌ **Pending** - Not started yet
- 🔧 **In Progress** - Currently working on
- ✅ **Completed** - Finished

### Visual UI

Press `Ctrl+T` to toggle the task list view in your terminal. Shows:
- Up to 10 tasks at a time
- Current task being worked on
- Overall progress

## Commands

### View Tasks

```bash
# In Claude Code
/todos                    # List current tasks
Ctrl+T                    # Toggle task list view
> show me all tasks      # Ask Claude directly
```

### Manage Tasks

```bash
> clear all tasks        # Remove all tasks
> mark task 3 complete   # Manually mark complete
> add task: write tests  # Add a new task
```

## Persistence

### Across Sessions

Tasks stored in `~/.claude/tasks/<TASK_LIST_ID>/`:

```bash
# Tasks persist here
~/.claude/tasks/default/tasks.json
~/.claude/tasks/my-project/tasks.json
```

Starting Claude with the same `CLAUDE_CODE_TASK_LIST_ID` loads previous tasks.

### Through Compaction

Tasks automatically persist through context compaction - no manual re-injection needed.

### Across Machines

To share tasks across machines, sync `~/.claude/tasks/`:

```bash
# Option 1: Symlink to Dropbox/iCloud
ln -s ~/Dropbox/claude-tasks ~/.claude/tasks

# Option 2: Git repository
cd ~/.claude/tasks
git init
git remote add origin <your-repo>
```

## Best Practices

### 1. Use Project-Specific Task Lists

```bash
# Different projects = different tasks
CLAUDE_CODE_TASK_LIST_ID=$(basename "$PWD")
```

**Benefits:**
- Tasks don't mix between projects
- Easier to context-switch
- Cleaner task lists

### 2. Clear Completed Tasks Regularly

```bash
> clear all completed tasks
```

Keeps the task list focused on active work.

### 3. Let Claude Manage Tasks

Don't manually create tasks unless needed - Claude does this automatically when:
- Working on multi-step features
- Complex refactoring
- Multiple file changes
- Sequential operations

### 4. Use /todos to Check Status

```bash
# Quick status check
/todos

# Detailed view
> show me all tasks with their status
```

## Integration with Proactive-Handoff

Tasks and proactive-handoff work together:

**Tasks (CLAUDE_CODE_TASK_LIST_ID):**
- Tactical breakdown of current work
- Step-by-step progress tracking
- Auto-managed by Claude

**session-state.md:**
- Strategic "next steps" if interrupted
- File modification tracking
- Manual notes about session

**Use both:**
```
Tasks:          What I'm working on now (granular)
Next steps:     What to do if session ends unexpectedly (strategic)
```

## Troubleshooting

### Tasks not persisting

**Check environment variable is set:**
```bash
echo $CLAUDE_CODE_TASK_LIST_ID
```

**If empty:**
```bash
export CLAUDE_CODE_TASK_LIST_ID=default
```

### Tasks from wrong project showing up

**Using global task list instead of project-specific:**
```bash
# Switch to project-specific
export CLAUDE_CODE_TASK_LIST_ID=$(basename "$PWD")

# Restart Claude
```

### Can't see task list

**Press Ctrl+T** to toggle task list view

**Or use commands:**
```bash
/todos
> show me all tasks
```

### Task list too cluttered

**Clear completed:**
```bash
> clear all completed tasks
```

**Clear everything:**
```bash
> clear all tasks
```

## Example Workflow

```bash
# Set up project-specific tasks
export CLAUDE_CODE_TASK_LIST_ID=claude-code-toolkit

# Start Claude
claude

# Work on feature
> Implement MCP memory integration with cleanup strategies

# Claude creates tasks automatically:
# 1. ❌ Add MCP memory to .mcp.json
# 2. ❌ Update HYBRID-MEMORY-PATTERN.md
# 3. ❌ Create cleanup-memory.sh script
# 4. ❌ Update README with memory section

# Press Ctrl+T to see task list
# Tasks auto-update as work progresses

# Close session
# Later, restart Claude (same TASK_LIST_ID)

# Tasks still there!
/todos
# 1. ✅ Add MCP memory to .mcp.json
# 2. ✅ Update HYBRID-MEMORY-PATTERN.md
# 3. 🔧 Create cleanup-memory.sh script  ← Continues here
# 4. ❌ Update README with memory section
```

## vs. Manual Task Files

| Feature | Native Tasks | tasks.md File |
|---------|--------------|---------------|
| Persistence | ✅ Automatic | ❌ Manual |
| Session survival | ✅ Yes | ❌ No |
| Compaction survival | ✅ Yes | 🟡 Re-injection needed |
| Team sharing | ❌ No (personal) | ✅ Via git |
| UI integration | ✅ Native UI | ❌ Manual |
| Auto-managed | ✅ Yes | ❌ Manual |

**When to use each:**
- **Native tasks**: Personal task breakdown (recommended)
- **Manual files**: Team-shared strategic plans (rare)

## Advanced Configuration

### Multiple Task Lists

```bash
# Work projects
CLAUDE_CODE_TASK_LIST_ID=work-project-1 claude

# Personal projects
CLAUDE_CODE_TASK_LIST_ID=personal-blog claude

# Experiments
CLAUDE_CODE_TASK_LIST_ID=experiments claude
```

### Task List Per Git Branch

```bash
# Auto task list based on branch
export CLAUDE_CODE_TASK_LIST_ID="$(basename "$PWD")-$(git branch --show-current 2>/dev/null || echo 'main')"
```

**Benefits:**
- Different tasks per feature branch
- Clean separation
- Auto-switches with branch

### Disable Task List (Not Recommended)

If you don't want automatic tasks:

```bash
# Don't set CLAUDE_CODE_TASK_LIST_ID
# Tasks won't persist across sessions
```

## See Also

- [Official Claude Code Interactive Mode Docs](https://code.claude.com/docs/en/interactive-mode#task-list)
- [Proactive Handoff README](README.md) - File-based state tracking
- [HYBRID-MEMORY-PATTERN.md](HYBRID-MEMORY-PATTERN.md) - Memory vs files strategy
