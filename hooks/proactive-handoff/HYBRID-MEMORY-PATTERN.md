# Hybrid Memory Pattern

Design pattern for combining file-based persistence with MCP Memory Server knowledge graph.

## The Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Persistent Storage                        │
├──────────────────────────┬──────────────────────────────────┤
│   Files (Human-Curated)  │  MCP Memory (Claude-Optimized)   │
├──────────────────────────┼──────────────────────────────────┤
│ • Strategic decisions    │ • Learned patterns               │
│ • Current work state     │ • Semantic relationships         │
│ • Active tasks           │ • Cross-project knowledge        │
│ • Team-shared context    │ • Queryable facts                │
│                          │                                  │
│ Git-committed ✅         │ .gitignored ❌                   │
│ Human-readable ✅        │ Machine-optimized ✅             │
│ Linear access ✅         │ Semantic search ✅               │
│ Manual updates ✅        │ Auto-populated ✅                │
└──────────────────────────┴──────────────────────────────────┘
```

## What Goes Where

### Files: Strategic Context

**Purpose:** Human-readable project state and decisions

**Files:**
- `.claude/session-state.md` - Auto-tracked file modifications, next steps
- `.claude/tasks.md` - TodoWrite-integrated task tracking
- `.claude/context.md` - Strategic checkpoints, architecture decisions
- `.claude/claude.md` - General project context

**When to use:**
- Team needs to read/understand
- Strategic decisions with rationale
- Current session state
- Git-tracked history needed

**Example:**
```markdown
# Context

## Architecture Decision (2026-01-20)
We chose to use MCP Memory Server for semantic relationships
because it allows Claude to query and traverse knowledge graphs,
improving cross-session understanding.

**Alternatives considered:**
- Neo4j (too heavy)
- Pure files (no semantic query)

**Trade-offs:**
- Files remain human-readable
- Memory handles semantic relationships
```

### MCP Memory: Semantic Knowledge Graph

**Purpose:** Claude-optimized semantic understanding and relationships

**Storage:** `.claude/memory.json` (auto-managed)

**When to use:**
- Learned preferences and patterns
- Project relationships and dependencies
- Technical decisions with context
- Cross-project knowledge
- Facts that need semantic search

**Example:**
```json
{
  "entities": [
    {
      "name": "claude-code-toolkit",
      "entityType": "project",
      "observations": [
        "Maintained by chris",
        "Used as git submodule across projects",
        "Contains proactive-handoff hook system",
        "Integrates TodoWrite with persistent storage"
      ]
    },
    {
      "name": "chris",
      "entityType": "developer",
      "observations": [
        "Prefers private feature branches for WIP",
        "Uses MySQL databases frequently",
        "Works with multi-project submodule pattern",
        "Team: Sonovore"
      ]
    }
  ],
  "relations": [
    {
      "from": "chris",
      "to": "claude-code-toolkit",
      "relationType": "maintains"
    },
    {
      "from": "claude-code-toolkit",
      "to": "AgentModel",
      "relationType": "used_by"
    },
    {
      "from": "prompt-improver",
      "to": "AgentModel",
      "relationType": "reads_data_from"
    }
  ]
}
```

## Explicit Control Patterns

### Pattern 1: Direct Memory Instructions

**When:** You want specific facts in memory

```bash
# In Claude Code
> Remember that AgentModel has 30 mental model domains organized
> into cognitive science, systems thinking, and decision making categories

# I'll create:
create_entities({
  name: "AgentModel",
  entityType: "project",
  observations: [
    "Has 30 mental model domains",
    "Organized into cognitive science, systems thinking, decision making"
  ]
})
```

### Pattern 2: Relationship Declarations

**When:** You want me to understand connections

```bash
> The prompt-improver skill integrates with AgentModel by reading
> mental-model-domains.json

# I'll create:
create_relations({
  from: "prompt-improver",
  to: "AgentModel",
  relationType: "integrates_with"
})

add_observations({
  entityName: "prompt-improver",
  contents: ["Reads mental-model-domains.json from AgentModel"]
})
```

### Pattern 3: Preference Learning

**When:** You want me to remember how you work

```bash
> I prefer to use symlinks for .mcp.json so it stays in sync with toolkit updates

# I'll create/update:
add_observations({
  entityName: "chris",
  contents: ["Prefers symlinks for .mcp.json to stay in sync with toolkit"]
})
```

### Pattern 4: Strategic Decisions → Files

**When:** Team needs context

```bash
> Document in context.md why we chose the hybrid memory approach

# I'll write to .claude/context.md:
```
```markdown
## Memory Strategy (2026-01-23)

**Decision:** Hybrid approach with files + MCP Memory

**Rationale:**
- Files: Human-readable, git-tracked, team-shared
- Memory: Semantic search, relationship traversal, Claude-optimized

**Implementation:**
- Files handle strategic decisions and current state
- Memory handles learned patterns and relationships
```

## Access Patterns

### Query Files (Linear)
```bash
# Read entire file
cat .claude/context.md

# Search for keyword
grep "AgentModel" .claude/context.md
```

### Query Memory (Semantic)
```bash
# In conversation:
> What projects am I working on?

# I use:
search_nodes("projects")
→ claude-code-toolkit, AgentModel, prompt-improver

> How does prompt-improver relate to AgentModel?

# I use:
open_nodes(["prompt-improver", "AgentModel"])
→ Shows: "integrates_with" relation + observations
```

### Traversal (Memory Only)
```bash
> What does claude-code-toolkit depend on?

# I use:
open_nodes(["claude-code-toolkit"])
→ Relations: used_by AgentModel, maintained_by chris
→ Observations: "Contains proactive-handoff hook system"

# Then follow relations:
open_nodes(["AgentModel"])
→ Full context about AgentModel
```

## Data Flow

### Session Start
```
1. SessionStart hook loads files
   ├─ session-state.md → Current state
   ├─ tasks.md → Create TodoWrite
   └─ context.md → Strategic context

2. MCP Memory auto-loads
   └─ memory.json → Knowledge graph available

3. Claude has both:
   ├─ Files: Current strategic context
   └─ Memory: Semantic knowledge + relationships
```

### During Work
```
Files:
├─ Auto-track: session-state.md (file modifications)
├─ Manual update: tasks.md (TodoWrite → markdown)
└─ Explicit: context.md (strategic decisions)

Memory:
├─ Auto-learn: Preferences, patterns
├─ Explicit: When you say "remember X"
└─ Relationships: Project dependencies, integrations
```

### PreCompact
```
1. Re-inject files (strategic context preserved)
   ├─ session-state.md
   ├─ tasks.md
   └─ context.md

2. Memory persists automatically
   └─ memory.json survives compaction (not in conversation)

3. Both available post-compaction
```

### Session End
```
Files:
└─ Persisted to disk, committed to git

Memory:
└─ .claude/memory.json persisted (.gitignored)
```

## Migration Strategy

### Step 1: Enable Memory Server
```bash
# Already in .mcp.json, just ensure it's enabled
claude mcp list | grep memory
```

### Step 2: Add to .gitignore
```bash
echo "" >> .gitignore
echo "# MCP Memory (auto-managed by Claude)" >> .gitignore
echo ".claude/memory.json" >> .gitignore
```

### Step 3: Seed Initial Knowledge
```bash
# In Claude Code
> Create entities in memory for:
> - claude-code-toolkit (project)
> - AgentModel (project)
> - prompt-improver (skill)
> - chris (developer)
>
> And relations:
> - chris maintains claude-code-toolkit
> - prompt-improver integrates_with AgentModel
> - claude-code-toolkit used_by AgentModel
```

### Step 4: Let It Learn
```bash
# From now on:
# - Files: I'll update when you ask or for strategic decisions
# - Memory: I'll auto-populate as I learn
```

## Example Session

```bash
=== Session Start ===

# Files loaded (strategic context)
=== Context ===
[Architecture decisions, current status]

=== Tasks ===
- [ ] Add MCP Memory integration
- [ ] Document hybrid pattern

# Memory available (semantic knowledge)
# (Auto-loads, no output)

# During work:

> What projects am I maintaining?

# I query memory:
search_nodes("projects maintained by chris")
→ claude-code-toolkit

> What does claude-code-toolkit integrate with?

# I traverse relations:
open_nodes(["claude-code-toolkit"])
→ Relations: used_by AgentModel
→ Observations: "Contains proactive-handoff", "Uses submodule pattern"

> Remember that I prefer to test MCP changes locally first

# I update memory:
add_observations({
  entityName: "chris",
  contents: ["Prefers to test MCP changes locally first"]
})

> Document the hybrid memory decision in context.md

# I update files:
Edit .claude/context.md
[Added strategic decision with rationale]

=== PreCompact ===
# Files re-injected (context.md, tasks.md, session-state.md)
# Memory persists automatically

=== Post-Compaction ===
# Both still available!
```

## Benefits

| Capability | Files Only | Memory Only | Hybrid |
|------------|------------|-------------|--------|
| Human-readable | ✅ | ❌ | ✅ |
| Git-tracked | ✅ | ❌ | ✅ |
| Semantic search | ❌ | ✅ | ✅ |
| Relationship traversal | ❌ | ✅ | ✅ |
| Team-shareable | ✅ | ❌ | ✅ |
| Auto-learning | ❌ | ✅ | ✅ |
| Strategic decisions | ✅ | ❌ | ✅ |
| Cross-project knowledge | ❌ | ✅ | ✅ |

## When to Use What

### Use Files When:
- ✅ Team needs to read/understand
- ✅ Strategic decision with rationale
- ✅ Current session state tracking
- ✅ Git history/audit trail needed
- ✅ Human editing required

### Use Memory When:
- ✅ Learning user preferences
- ✅ Project relationships/dependencies
- ✅ Cross-session knowledge
- ✅ Semantic search needed
- ✅ Relationship traversal needed

### Use Both When:
- ✅ Strategic decision (file) + learned pattern (memory)
- ✅ Current task (file) + project context (memory)
- ✅ Architecture choice (file) + technical rationale (memory)

## Maintenance

### Files
```bash
# Review and commit periodically
git diff .claude/context.md
git add .claude/context.md .claude/tasks.md
git commit -m "Update project context"
```

### Memory
```bash
# Inspect knowledge graph
> Show me everything in memory about AgentModel

# I'll use:
open_nodes(["AgentModel"])

# Clean up if needed
> Remove the observation about AgentModel having 142 research files

# I'll use:
delete_observations({
  entityName: "AgentModel",
  observations: ["Has 142 research files"]
})
```

## See Also

- [TODOWRITE-INTEGRATION.md](TODOWRITE-INTEGRATION.md) - TodoWrite + tasks.md integration
- [DESIGN.md](DESIGN.md) - Proactive handoff design philosophy
- [MCP Memory Server](https://github.com/modelcontextprotocol/servers/tree/main/src/memory)
