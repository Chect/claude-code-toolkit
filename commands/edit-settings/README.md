# Edit Settings Command

A comprehensive reference guide for editing Claude Code's `settings.json` files.

## What It Does

When you run `/edit-settings`, Claude has access to detailed documentation about:

- Settings file locations and priority
- Permission pattern syntax (the tricky `:*` suffix)
- Common permission patterns for git, build, file operations
- Hook configuration
- The `cd &&` problem and solutions
- Troubleshooting tips

## Why Use This

Claude Code's permission patterns have subtle syntax rules that are easy to get wrong:

```json
"Bash(git status)"     // ONLY matches exactly "git status"
"Bash(git status:*)"   // Matches "git status", "git status --porcelain", etc.
```

This command gives Claude the knowledge to edit settings correctly.

## Installation

```bash
cp edit-settings.md ~/.claude/commands/
# or for project-specific:
cp edit-settings.md .claude/commands/
```

## Usage

```
/edit-settings add permission for npm test
/edit-settings add a PreToolUse hook for Bash commands
```

## Key Concepts Covered

- **`:*` suffix**: Enables prefix matching (without it, exact match only)
- **Settings precedence**: User → Project → Shared
- **The `cd &&` problem**: Why `cd /path && git status` won't match `Bash(git:*)`
- **Hook matchers**: Use `|` for OR, not wildcards
