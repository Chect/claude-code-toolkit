# Cleanup and Pruning Strategies

Strategies for maintaining clean, relevant data in both file-based and MCP Memory storage.

## The Problem

Without cleanup:
- **Files**: session-state.md grows with hundreds of old file entries
- **Context**: Old strategic decisions become stale
- **Memory**: memory.json fills with outdated facts and relationships
- **Performance**: Slower searches, larger context windows

## Overview: Two-Layer Cleanup

```
┌─────────────────────────────────────────────────────────────┐
│                    Cleanup Strategy                          │
├──────────────────────────┬──────────────────────────────────┤
│   Files (Manual+Auto)    │  MCP Memory (Auto+Manual)        │
├──────────────────────────┼──────────────────────────────────┤
│ • Archival rotation      │ • Time-based decay               │
│ • File entry limiting    │ • Relevance pruning              │
│ • Context versioning     │ • Duplicate cleanup              │
│                          │ • Orphan removal                 │
└──────────────────────────┴──────────────────────────────────┘
```

**Note:** Tasks are managed by Claude Code's native task system (CLAUDE_CODE_TASK_LIST_ID) - no cleanup needed.

## File-Based Cleanup Strategies

### 1. Session State Cleanup (Automated)

**What:** Remove old file entries, completed agents

**When:** Manually or on PreCompact

**Already implemented:**
```bash
# Remove completed agents, keep last 20 files
.claude/hooks/proactive-handoff.sh cleanup 20

# Or less aggressive (keep 50)
.claude/hooks/proactive-handoff.sh cleanup 50
```

**Audit trail:** Removed entries logged to `.claude/session-history.log`

**Automate via PreCompact:**
```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$(git rev-parse --show-toplevel)\" && .claude/hooks/proactive-handoff.sh cleanup 30 && .claude/hooks/proactive-handoff.sh save && ..."
          }
        ]
      }
    ]
  }
}
```

### 2. Context Rotation (Strategic)

**What:** Archive old strategic decisions, keep context.md current

**When:** Monthly or when changing project phases

**Strategy A: Versioned Context**
```bash
# Before major milestone
cp .claude/context.md .claude/archives/context-$(date +%Y-%m).md

# Update context.md with new phase
# Keep only current strategic decisions
```

**Strategy B: Append-Only Context**
```markdown
# .claude/context.md

## Current Phase (2026-02)
- Focus: Production deployment
- Key decisions: Using hybrid memory approach

## Previous Phases

### 2026-01: Development
- Implemented proactive-handoff
- Added MCP servers
```

**Strategy C: Split Context**
```bash
.claude/
├── context.md              # Current (last 3 months)
├── archives/
│   ├── context-2025-Q4.md  # Quarterly archives
│   └── context-2026-Q1.md
```

### 3. File Entry Limiting (Already Implemented)

**Current behavior:**
- `session-state.md` tracks file modifications
- Cleanup keeps last N entries (default: 20)
- Older entries logged to `session-history.log`

**Tune based on session length:**
```bash
# Short sessions (< 1 hour)
.claude/hooks/proactive-handoff.sh cleanup 10

# Normal sessions (1-3 hours)
.claude/hooks/proactive-handoff.sh cleanup 20

# Long sessions (> 3 hours)
.claude/hooks/proactive-handoff.sh cleanup 50
```

## MCP Memory Cleanup Strategies

### 1. Manual Inspection and Pruning

**What:** Review and remove outdated entities/observations

**When:** Monthly or when memory.json > 100KB

**Commands:**
```bash
# In Claude Code

# 1. Inspect entire graph
> Show me the entire knowledge graph

# I use: read_graph()
# Returns all entities, relations, observations

# 2. Find stale entities
> Show me all entities of type "project"

# I use: search_nodes("type:project")

# 3. Remove outdated entity
> Delete the entity "old-project-name"

# I use: delete_entities(["old-project-name"])

# 4. Remove stale observations
> Remove the observation "Used Python 2.7" from chris

# I use:
delete_observations({
  entityName: "chris",
  observations: ["Used Python 2.7"]
})

# 5. Remove outdated relation
> Remove the relation between old-tool and current-project

# I use:
delete_relations([{
  from: "old-tool",
  to: "current-project",
  relationType: "integrates_with"
}])
```

### 2. Time-Based Decay (Manual Implementation)

**Concept:** Facts lose relevance over time

**Implementation pattern:**
```bash
# Add timestamps to observations
> Remember that I'm currently using React 18.2

# I create:
{
  "name": "chris",
  "observations": [
    "Currently using React 18.2 (as of 2026-01-23)"
  ]
}

# Later cleanup:
> Remove any observations about React versions older than 6 months

# I search and delete:
search_nodes("React")
# Review dates, delete old observations
```

**Automated decay (future feature):**
```bash
# Some MCP memory servers support automatic decay
# Memento MCP: Relations decay with configurable half-life (30 days default)
# Check if your memory server supports this
```

### 3. Relevance Pruning

**What:** Remove entities/observations that are no longer relevant

**Criteria for removal:**
- Project is archived/completed
- Technology no longer used
- Relationship no longer active
- Preference has changed

**Monthly review process:**
```bash
# 1. List all projects
> Show me all entities of type "project"

# 2. Check each project
> Is AgentModel still active?
# If no: delete_entities(["AgentModel"])

# 3. Review observations
> Show observations about chris

# 4. Prune outdated
> Remove observations about technologies I no longer use
```

### 4. Duplicate Cleanup

**What:** Remove duplicate entities/observations

**When:** After bulk imports or manual errors

**Detection:**
```bash
# In Claude Code
> Check for duplicate entities in memory

# I'll search:
read_graph()
# Analyze for duplicates (same name, similar observations)

> Remove duplicate entity "claude_code_toolkit" (keep "claude-code-toolkit")

# I use:
delete_entities(["claude_code_toolkit"])
```

**Automated (if supported):**
```bash
# Some memory servers have cleanup_duplicates tool
# Check availability:
> Do you have a cleanup_duplicates tool?
```

### 5. Orphan Removal

**What:** Remove entities with no relations or observations

**When:** Monthly maintenance

**Pattern:**
```bash
> Find entities with no observations and no relations

# I'll search:
read_graph()
# Filter for entities with:
# - observations: []
# - No incoming/outgoing relations

> Delete orphaned entities

# I use:
delete_entities([list of orphans])
```

## Automated Cleanup Schedules

### Daily (Auto)
- Session state cleanup on PreCompact
- Keep last 20-30 file entries

### Weekly (Manual)
```bash
# Run on Friday
.claude/hooks/archive-tasks.sh          # Archive completed tasks
.claude/hooks/proactive-handoff.sh cleanup 20  # Clean session state
```

### Monthly (Manual)
```bash
# Review and cleanup

# 1. Files
cp .claude/context.md .claude/archives/context-$(date +%Y-%m).md
# Edit context.md to keep only current decisions

# 2. Memory
# In Claude Code:
> Review knowledge graph for outdated entities
> Remove old projects, technologies, preferences
> Check for duplicates and orphans
```

### Quarterly (Strategic)
```bash
# Archive entire quarters
mkdir -p .claude/archives/2026-Q1
mv .claude/archives/tasks-2026-*.md .claude/archives/2026-Q1/
mv .claude/archives/context-2026-0*.md .claude/archives/2026-Q1/

# Memory snapshot (optional)
cp .claude/memory.json .claude/archives/2026-Q1/memory-snapshot.json
```

## Cleanup Automation Scripts

### Auto-Archive Tasks on PreCompact

**Add to settings.json PreCompact hook:**
```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$(git rev-parse --show-toplevel)\" && if [ -f '.claude/hooks/archive-tasks.sh' ]; then .claude/hooks/archive-tasks.sh; fi && .claude/hooks/proactive-handoff.sh cleanup 30 && .claude/hooks/proactive-handoff.sh save && ..."
          }
        ]
      }
    ]
  }
}
```

### Memory Health Check Script

```bash
#!/bin/bash
# .claude/hooks/check-memory-health.sh

MEMORY_FILE=".claude/memory.json"

if [ ! -f "$MEMORY_FILE" ]; then
    echo "No memory file found"
    exit 0
fi

# Check file size
SIZE=$(stat -f%z "$MEMORY_FILE" 2>/dev/null || stat -c%s "$MEMORY_FILE" 2>/dev/null)
SIZE_KB=$((SIZE / 1024))

echo "Memory Health Check"
echo "==================="
echo "File size: ${SIZE_KB}KB"

# Warn if large
if [ "$SIZE_KB" -gt 500 ]; then
    echo "⚠️  WARNING: Memory file is large (${SIZE_KB}KB)"
    echo "   Consider cleanup:"
    echo "   - Review entities and remove old projects"
    echo "   - Prune outdated observations"
    echo "   - Remove orphaned entities"
fi

# Count entities (rough)
ENTITY_COUNT=$(grep -c '"name":' "$MEMORY_FILE" || echo "0")
echo "Entities (approx): $ENTITY_COUNT"

if [ "$ENTITY_COUNT" -gt 100 ]; then
    echo "⚠️  High entity count ($ENTITY_COUNT)"
    echo "   Review for relevance"
fi

echo ""
echo "Last modified: $(stat -f%Sm "$MEMORY_FILE" 2>/dev/null || stat -c%y "$MEMORY_FILE" 2>/dev/null)"
```

### Cron-based Cleanup

```bash
# Add to crontab (optional)

# Weekly task archival (Fridays at 5 PM)
0 17 * * 5 cd ~/projects/myproject && .claude/hooks/archive-tasks.sh

# Monthly memory health check (1st of month)
0 9 1 * * cd ~/projects/myproject && .claude/hooks/check-memory-health.sh
```

## Memory Cleanup Example Session

```bash
=== Monthly Memory Cleanup ===

# 1. Health check
> Show me the entire knowledge graph

# Review output...

# 2. Remove old project
> The "legacy-app" project is archived, remove it from memory

# I use:
delete_entities(["legacy-app"])
# Also removes all relations to/from legacy-app

# 3. Update preferences
> I no longer use PostgreSQL, remove that observation

# I use:
delete_observations({
  entityName: "chris",
  observations: ["Uses PostgreSQL databases"]
})

# 4. Remove orphans
> Find entities with no relations

# I search and clean:
read_graph()
→ Found: "temp-experiment" (no relations)

> Delete temp-experiment

delete_entities(["temp-experiment"])

# 5. Consolidate duplicates
> I see "claude-code-toolkit" and "claude_code_toolkit", merge them

# I:
# - Copy observations from claude_code_toolkit to claude-code-toolkit
# - Update relations to use claude-code-toolkit
# - Delete claude_code_toolkit

# Done!
```

## File Cleanup Example

```bash
=== Weekly File Cleanup ===

# 1. Archive completed tasks
./claude/hooks/archive-tasks.sh
→ Archived 12 completed tasks to archives/tasks-2026-W04.md

# 2. Clean session state
.claude/hooks/proactive-handoff.sh cleanup 20
→ Removed 45 old file entries, kept 20

# 3. Review context.md
cat .claude/context.md
# Decide if anything should be archived

# If yes:
cp .claude/context.md .claude/archives/context-2026-01.md
# Edit context.md to keep only current decisions

# Done!
```

## Monitoring File Growth

```bash
#!/bin/bash
# .claude/hooks/file-size-check.sh

echo "File Size Report"
echo "================"

for file in session-state.md tasks.md context.md memory.json; do
    if [ -f ".claude/$file" ]; then
        SIZE=$(stat -f%z ".claude/$file" 2>/dev/null || stat -c%s ".claude/$file" 2>/dev/null)
        SIZE_KB=$((SIZE / 1024))
        LINES=$(wc -l < ".claude/$file")
        echo "$file: ${SIZE_KB}KB, ${LINES} lines"
    fi
done

echo ""
echo "Archives:"
du -sh .claude/archives 2>/dev/null || echo "No archives"
```

## Best Practices

### Files
1. **Archive, don't delete** - Old context has historical value
2. **Weekly task cleanup** - Keep tasks.md manageable
3. **Version context.md** - Before major milestones
4. **Audit trail** - session-history.log tracks what was removed
5. **Automate via hooks** - PreCompact is ideal for cleanup

### Memory
1. **Monthly review** - Check memory.json size and relevance
2. **Prune outdated facts** - Technology changes, remove old observations
3. **Remove completed projects** - Archive projects no longer active
4. **Consolidate duplicates** - Keep naming consistent
5. **Remove orphans** - Entities with no relations/observations

### Both
1. **Regular schedule** - Weekly files, monthly memory
2. **Size monitoring** - Watch for bloat (>500KB is large)
3. **Relevance over history** - Recent is usually more relevant
4. **Balance** - Don't over-prune, keep strategic history
5. **Test restores** - Ensure archives are usable

## Cleanup Checklist

### Weekly
- [ ] Run archive-tasks.sh (if >20 completed tasks)
- [ ] Check session-state.md size (cleanup if >100 lines)
- [ ] Review recent session-history.log entries

### Monthly
- [ ] Archive context.md if major milestone
- [ ] Review memory.json (check size, prune if needed)
- [ ] Remove outdated projects from memory
- [ ] Update preferences in memory (if changed)
- [ ] Check for duplicate entities
- [ ] Remove orphaned entities

### Quarterly
- [ ] Archive weekly task archives into quarterly folder
- [ ] Snapshot memory.json to archives
- [ ] Review and consolidate context archives
- [ ] Clean up session-history.log (keep last 3 months)

## Tools Summary

| Tool | Purpose | Frequency |
|------|---------|-----------|
| `proactive-handoff.sh cleanup N` | Clean session state | Daily/PreCompact |
| `archive-tasks.sh` | Archive completed tasks | Weekly |
| Context rotation | Version strategic decisions | Monthly |
| Memory review in Claude | Prune entities/observations | Monthly |
| `check-memory-health.sh` | Size/entity count check | Monthly |
| `file-size-check.sh` | Monitor all file sizes | Weekly |
| Quarterly archival | Consolidate archives | Quarterly |

## See Also

- [DESIGN.md](DESIGN.md) - Proactive handoff design philosophy
- [HYBRID-MEMORY-PATTERN.md](HYBRID-MEMORY-PATTERN.md) - Files vs Memory usage
- [MCP Memory Service](https://github.com/doobidoo/mcp-memory-service) - Advanced memory cleanup
- [Memento MCP](https://github.com/gannonh/memento-mcp) - Time-based decay features
