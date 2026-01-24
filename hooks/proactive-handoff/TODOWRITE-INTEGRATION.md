# TodoWrite Integration

Integration between Claude Code's built-in TodoWrite tool and proactive-handoff for persistent task management.

## The Problem

Claude Code's TodoWrite tool creates task checklists in the UI, but **todos don't persist across sessions**. When a session ends or context gets compacted, the TodoWrite state is lost.

## The Solution

Use `.claude/tasks.md` as the persistent source of truth, with TodoWrite as the in-session UI:

```
Session Start
    ↓
Load tasks.md → Create TodoWrite todos
    ↓
Work (using TodoWrite for live UI)
    ↓
Update tasks.md as tasks complete
    ↓
PreCompact → Reminds to save TodoWrite state
    ↓
Compaction (tasks.md re-injected)
    ↓
Continue with TodoWrite still reflecting tasks.md
```

## Workflow

### 1. Session Start

The SessionStart hook loads `.claude/tasks.md` and instructs Claude to create TodoWrite todos:

```markdown
# Tasks

## Active Tasks
- [ ] Implement user authentication
- [ ] Add password validation
- [ ] Create login endpoint

## Completed
- [x] Set up database schema
```

Claude automatically creates TodoWrite todos from the "Active Tasks" section.

### 2. During Work

Claude uses TodoWrite to track progress in the UI:
- Visual checklist in terminal
- Real-time status updates
- Shows current task with activeForm

### 3. Completing Tasks

When tasks are completed, Claude updates `.claude/tasks.md`:

```markdown
## Active Tasks
- [ ] Add password validation
- [ ] Create login endpoint

## Completed
- [x] Set up database schema
- [x] Implement user authentication  ← Moved here
```

### 4. Before Compaction

PreCompact hook:
1. Re-injects current `tasks.md`
2. Reminds Claude to update `tasks.md` with current TodoWrite state
3. Compaction preserves the updated task list

## File Format

Use standard markdown checkbox format:

```markdown
# Tasks

## Active Tasks
<!-- Tasks Claude should create TodoWrite todos for -->
- [ ] Pending task 1
- [ ] Pending task 2

## Completed
<!-- Tasks that are done -->
- [x] Completed task 1
- [x] Completed task 2

## Notes
<!-- Context for tasks -->
- Task 1 requires API key setup
- Task 2 depends on Task 1 completing
```

## Commands

### Initialize tasks.md

```bash
cp .claude/hooks/proactive-handoff/tasks-template.md .claude/tasks.md
```

### Manual Update

Edit `.claude/tasks.md` directly:

```bash
# In Claude Code
> Edit .claude/tasks.md and move completed tasks
```

Claude will automatically update the file as tasks complete.

## Integration with session-state.md

The "Current Focus" section in `session-state.md` shows active TodoWrite tasks:

```markdown
### Current Focus
- Implement user authentication
- Add password validation
```

This is updated automatically as TodoWrite state changes.

## Benefits

1. **Visual UI** - TodoWrite provides real-time progress display
2. **Persistence** - tasks.md survives sessions and compaction
3. **Team Sharing** - tasks.md can be committed to git
4. **Automatic** - SessionStart and PreCompact handle integration
5. **Manual Control** - Edit tasks.md directly when needed

## Comparison

| Feature | tasks.md only | TodoWrite only | Integrated |
|---------|---------------|----------------|------------|
| Persists across sessions | ✅ | ❌ | ✅ |
| Visual UI in terminal | ❌ | ✅ | ✅ |
| Real-time updates | ❌ | ✅ | ✅ |
| Team shareable | ✅ | ❌ | ✅ |
| Survives compaction | ✅ | ❌ | ✅ |

## Example Session

```bash
# Session starts
=== Tasks (use TodoWrite tool to track these) ===
# Tasks
## Active Tasks
- [ ] Add user registration endpoint
- [ ] Implement email validation
- [ ] Add rate limiting

IMPORTANT: Create TodoWrite todos from the Active Tasks above.

# Claude creates TodoWrite todos automatically
# TodoWrite UI shows:
# 1. ❌ Add user registration endpoint
# 2. ❌ Implement email validation
# 3. ❌ Add rate limiting

# Work happens...
# TodoWrite UI updates:
# 1. ✅ Add user registration endpoint
# 2. 🔧 Implementing email validation
# 3. ❌ Add rate limiting

# Claude updates tasks.md as tasks complete:
## Active Tasks
- [ ] Add rate limiting

## Completed
- [x] Add user registration endpoint
- [x] Implement email validation

# Context fills up, PreCompact triggers
=== Tasks (re-injecting for compaction) ===
[tasks.md content with reminder to update]

# Compaction happens, session continues
# TodoWrite still reflects current state from tasks.md
```

## Tips

1. **Keep tasks actionable** - Clear, specific tasks work best with TodoWrite
2. **Update frequently** - Move completed tasks to "Completed" section regularly
3. **Use Notes section** - Add context that TodoWrite doesn't capture
4. **Commit tasks.md** - Share team-wide task status via git
5. **Clean up completed** - Archive old completed tasks periodically

## Troubleshooting

### TodoWrite not created at session start

**Problem**: Tasks.md loaded but TodoWrite todos not created

**Solution**: Claude needs explicit instruction. Ensure session-start.sh includes the "IMPORTANT: Create TodoWrite todos" line.

### TodoWrite state lost after compaction

**Problem**: TodoWrite todos disappear after compaction

**Solution**: Ensure tasks.md is updated before compaction and is re-injected by PreCompact hook.

### Tasks out of sync

**Problem**: TodoWrite shows different tasks than tasks.md

**Solution**: Update tasks.md to match current TodoWrite state:

```bash
# In Claude Code
> Update .claude/tasks.md to reflect current TodoWrite state
```

## See Also

- [Claude Code Todo Lists](https://platform.claude.com/docs/en/agent-sdk/todo-tracking)
- [proactive-handoff DESIGN.md](DESIGN.md)
- [TodoWrite Tool Documentation](https://claudelog.com/faqs/what-is-todo-list-in-claude-code/)
