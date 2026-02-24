# Bash Guard Hook

A PreToolUse hook that enforces three safety rules on Bash tool calls:

1. **No command chaining** — Blocks `&&`, `||`, and `;`. Forces Claude to use separate Bash tool calls, making each command individually reviewable and approvable.
2. **Dedicated tool enforcement** — Blocks `grep`, `find`, `cat`, `head`, `tail`, and `awk` in Bash, since Claude Code has dedicated tools (Grep, Glob, Read, Edit) that are more reviewable.
3. **Directory restriction** — Limits write-capable commands (`sed`, `mkdir`, `chmod`, `python`, etc.) to allowed directories only.

## Why Use This

Claude Code can chain multiple commands in a single Bash call, making it hard to review what's actually running. It also tends to fall back to `grep`/`cat`/`find` instead of using its dedicated tools. This hook forces better habits:

- Every command gets its own approval prompt
- File searches and reads use the proper tools (with better output formatting)
- Write operations are sandboxed to your project

## Configuration

### Allowed Directories

By default, write-capable commands are restricted to:
- The current git repository root (auto-detected)
- `~/.claude`

To customize, set `BASH_GUARD_ALLOWED_DIRS` as a colon-separated list:

```bash
export BASH_GUARD_ALLOWED_DIRS="/path/to/project:/path/to/other:/Volumes/external"
```

### Write-Capable Commands

The following commands are restricted to allowed directories:
`sed`, `mkdir`, `chmod`, `python`, `python3`, `uv`, `pip`, `npm`, `npx`

Edit the `WRITE_COMMANDS` variable in the script to customize.

## Requirements

- `jq` — JSON processor for parsing hook input
  ```bash
  # macOS
  brew install jq

  # Ubuntu/Debian
  apt install jq
  ```

## Installation

### 1. Copy the script

```bash
mkdir -p .claude/hooks
cp bash-guard.sh .claude/hooks/
chmod +x .claude/hooks/bash-guard.sh
```

### 2. Add to settings.json

Copy the contents of `settings-snippet.json` into your `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/bash-guard.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. (Optional) Set allowed directories

```bash
# In your shell profile or .claude/settings.json env
export BASH_GUARD_ALLOWED_DIRS="/my/project:/other/path"
```

If not set, defaults to git repo root + `~/.claude`.

### 4. Restart Claude Code

## What Gets Blocked

### Command chaining
```
$ git add . && git commit -m "msg"
BLOCKED: Split chained commands into separate Bash tool calls.
```

Shell constructs (`for`, `while`, `if`) are allowed since they legitimately use `;`.

### Dedicated tool commands
```
$ grep -r "pattern" src/
BLOCKED: Use the Grep tool instead of 'grep' in Bash.

$ cat README.md
BLOCKED: Use the Read tool instead of 'cat' in Bash.

$ find . -name "*.py"
BLOCKED: Use the Glob tool instead of 'find' in Bash.
```

### Out-of-bounds writes
```
$ mkdir /tmp/something
BLOCKED: 'mkdir' targets '/tmp/something' which is outside allowed directories.

$ sed -i '' 's/foo/bar/' /etc/config
BLOCKED: 'sed' targets '/etc/config' which is outside allowed directories.
```

## Customization

- **Add write commands**: Edit `WRITE_COMMANDS` in the script
- **Add allowed dirs**: Set `BASH_GUARD_ALLOWED_DIRS` or edit the default logic
- **Remove a guard**: Comment out the relevant section (chain detection, tool enforcement, or directory restriction)
