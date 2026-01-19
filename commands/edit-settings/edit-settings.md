---
description: Edit Claude Code settings.json files with correct patterns
---

Edit Claude Code settings.json files, especially permissions patterns.

## Arguments
$ARGUMENTS

## Settings File Locations

Claude Code uses multiple settings.json files in priority order:

| Location | Scope | Purpose |
|----------|-------|---------|
| `~/.claude/settings.json` | User | Personal preferences, env vars |
| `.claude/settings.json` | Project | Project-specific permissions |
| `.claude-shared/settings.json` | Team | Shared team settings (gitignored) |

Settings merge with later files taking precedence.

## File Structure

```json
{
  "env": {
    "PATH": "/custom/path:$PATH"
  },
  "permissions": {
    "allow": [
      "ToolName",
      "ToolName(pattern)",
      "ToolName(pattern:*)"
    ],
    "deny": [
      "ToolName(dangerous-pattern)"
    ],
    "additionalDirectories": [
      "/path/to/allow"
    ]
  },
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "Stop": [...],
    "PreCompact": [...]
  }
}
```

## The `cd &&` Problem

Commands like `cd /some/path && git status` won't match permission rules that expect commands to start with `git`. The entire command string must match the pattern.

**Example that FAILS:**
```
Permission: "Bash(git status)"
Command:    cd "$(git rev-parse --show-toplevel)" && git status
Result:     ❌ Doesn't match (command starts with "cd", not "git")
```

### Solutions

1. **Use `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1` (Recommended)**
   - Set this environment variable to reset to project dir after each bash command
   - Prevents Claude from getting "lost" after cd'ing somewhere
   - Add to settings.json: `"env": { "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": "1" }`

2. **Wrap Multi-Step Commands in Scripts**
   - Create: `.claude/scripts/my-command.sh`
   - Allowlist: `Bash(.claude/scripts/my-command.sh:*)`
   - Pros: Clean, auditable, version-controlled

3. **Use PreToolUse Hook with Regex (Advanced)**
   - For complex patterns, use a hook that does regex matching
   - **claude-code-permissions-hook**: Rust-based tool that intercepts permission checks
     - Uses TOML config with regex patterns instead of prefix matching
     - Can match patterns like `&& git status$` (end of command)
     - Can block dangerous patterns (pipes, semicolons, backticks)
     - Runs alongside settings.json (two configs to maintain)
     - Source: https://blog.korny.info/2025/10/10/better-claude-code-permissions
     - GitHub: https://github.com/kornysietsma/claude-code-permissions-hook
   - **Revisit if**: CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR doesn't solve most cases

4. **Allow `cd` Broadly (Use with Caution)**
   - `"Bash(cd:*)"` allows ANY command starting with cd
   - Very broad - allows `cd /anywhere && rm -rf *`

5. **Accept Some Permission Prompts** - For infrequent commands, let Claude ask

### Environment Variable Configuration

Add to settings.json to apply to all sessions:
```json
{
  "env": {
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": "1"
  }
}
```

Related: `CLAUDE_ENV_FILE` can be set to a script path that's sourced before each bash command, enabling persistent environment setup.

## Permission Pattern Syntax

### Tool Names
Standard tools: `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `WebFetch`, `WebSearch`, `Task`, `Skill`, `NotebookEdit`

### Pattern Matching Rules

| Pattern | Meaning | Example |
|---------|---------|---------|
| `Tool` | Allow tool with any args | `Read` allows reading any file |
| `Tool(exact)` | Exact command match | `Bash(git status)` only `git status` |
| `Tool(prefix:*)` | Prefix match with wildcard | `Bash(git diff:*)` allows `git diff HEAD`, `git diff --staged`, etc. |
| `Tool(path/file)` | Specific path | `Edit(TASK_QUEUE.md)` |
| `Tool(path/*)` | Path prefix | `Edit(.claude/*:*)` |

### CRITICAL: Colon-Asterisk Syntax

The `:*` suffix enables **prefix matching**. Without it, the pattern is an exact match.

```
"Bash(git status)"      # ONLY matches exactly "git status"
"Bash(git status:*)"    # Matches "git status", "git status --porcelain", etc.
```

**Common mistake**: Forgetting `:*` causes patterns to fail silently.

### Special Characters

| Character | Usage | Example |
|-----------|-------|---------|
| `:*` | Wildcard suffix for prefix matching | `Bash(git:*)` |
| `\|` | OR in hook matchers (NOT in allow) | `"matcher": "Edit\|Write"` |
| `$()` | Shell command substitution | `Bash("$(git rev-parse --show-toplevel)"/path)` |
| `"` | Must be escaped in JSON | Use single quotes in shell commands |

### Path Patterns

For paths with spaces or dynamic roots:

```json
"Bash(\"$(git rev-parse --show-toplevel)\"/.claude/build.sh:*)"
```

This resolves to the repo root at runtime.

## Common Permission Patterns

### Git Operations
```json
"Bash(git status)",
"Bash(git status --porcelain)",
"Bash(git diff:*)",
"Bash(git log:*)",
"Bash(git add:*)",
"Bash(git commit:*)",
"Bash(git checkout:*)",
"Bash(git branch:*)",
"Bash(git pull:*)",
"Bash(git push:*)"
```

### Build Commands
```json
"Bash(./.claude/build.sh:*)",
"Bash(make:*)",
"Bash(npm run:*)",
"Bash(cargo build:*)"
```

### File Operations
```json
"Bash(ls:*)",
"Bash(find:*)",
"Bash(cat:*)",
"Bash(head:*)",
"Bash(tail:*)"
```

### Python/Scripts
```json
"Bash(python3:*)",
"Bash(python:*)",
"Bash(./scripts/:*)"
```

### Dangerous - Use with Caution
```json
"Bash(rm:*)",           # Can delete files
"Bash(sudo:*)",         # Root access
"Bash(chmod:*)",        # Change permissions
"Bash(curl:*)",         # Network access
"Bash(wget:*)"          # Network access
```

## Hooks Configuration

### Hook Types
- `PreToolUse` - Before a tool runs (can block)
- `PostToolUse` - After a tool runs
- `Stop` - When session ends
- `PreCompact` - Before context summarization

### Hook Structure
```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "path/to/script.sh"
        }
      ]
    }
  ]
}
```

### Matcher Patterns
Hook matchers use regex-like patterns:
- `"Bash"` - Matches Bash tool
- `"Edit|Write|NotebookEdit"` - Matches any of these tools
- No wildcards in hook matchers (use `|` for OR)

## Step-by-Step: Adding a New Permission

1. **Identify the exact command** you want to allow
2. **Decide scope**: exact match or prefix match?
3. **Choose the right pattern**:
   - Exact: `"Bash(command arg1 arg2)"`
   - Prefix: `"Bash(command:*)"`
4. **Test the pattern** by running the command
5. **Restart Claude Code** (required for settings changes)

## Validation Checklist

Before saving settings.json:

- [ ] Valid JSON (no trailing commas, proper quotes)
- [ ] All patterns use correct `:*` suffix where needed
- [ ] Paths with spaces are properly quoted
- [ ] No duplicate entries in allow array
- [ ] Shell command substitution uses correct escaping

## Troubleshooting

### Pattern Not Working
1. Check for missing `:*` suffix
2. Verify exact spacing matches
3. Check for typos in command name
4. Restart Claude Code (settings require restart)

### Permission Denied Despite Pattern
1. Check if `deny` list overrides `allow`
2. Verify pattern matches full command prefix
3. Check for conflicting patterns in other settings files

### Hook Not Running
1. Verify script exists and is executable
2. Check `matcher` regex is correct
3. Use `|` for OR, not wildcards

## Example: Complete Project Settings

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Edit(TASK_QUEUE.md)",
      "Write(TASK_QUEUE.md)",
      "Bash(git status)",
      "Bash(git status --porcelain)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(ls:*)",
      "Bash(./.claude/build.sh:*)",
      "WebSearch",
      "Skill(embedded-c)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/check-dangerous.sh"
          }
        ]
      }
    ]
  }
}
```

## Instructions

When user asks to edit settings.json:

1. **Read the current file** to understand existing configuration
2. **Ask clarifying questions** if the request is ambiguous:
   - Which settings file? (user, project, shared)
   - Exact match or prefix match?
   - Any security concerns?
3. **Apply the change** using Edit tool
4. **Validate JSON** syntax
5. **Remind user** to restart Claude Code for changes to take effect
