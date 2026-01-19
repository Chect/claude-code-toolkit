# Dangerous Command Check Hook

A PreToolUse hook that displays a prominent warning when Claude is about to execute destructive commands like `rm -rf`.

## Why Use This

Claude Code can execute shell commands, and sometimes those commands are destructive. This hook:

- Displays a bright red warning box in your terminal
- Shows the exact command about to run
- Gives you a moment to review before approving
- Does NOT block the command - you still control approval

## What It Catches

Currently detects:
- `rm -rf` (recursive force delete)
- `rm -fr` (same thing, different flag order)
- Various flag combinations like `rm -rfi`, `rm -fR`, etc.

## Requirements

- `jq` - JSON processor for parsing hook input
  ```bash
  # macOS
  brew install jq
  
  # Ubuntu/Debian
  apt install jq
  
  # Fedora
  dnf install jq
  ```

## Installation

### 1. Copy the script

```bash
mkdir -p .claude/hooks
cp dangerous-command-check.sh .claude/hooks/
chmod +x .claude/hooks/dangerous-command-check.sh
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
            "command": "./.claude/hooks/dangerous-command-check.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. Restart Claude Code

## Example Output

When Claude tries to run `rm -rf /some/path`:

```
╔══════════════════════════════════════════════════════════════════════╗
║  ⚠️  DANGER: rm -rf DETECTED! ⚠️                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  This command will PERMANENTLY DELETE files without confirmation!    ║
╚══════════════════════════════════════════════════════════════════════╝

Command: rm -rf /some/path

Review carefully before approving!
```

## Customization

Edit the script to add more patterns. The regex currently catches:

```bash
rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r)|-rf|-fr)\s
```

You could extend it to catch:
- `sudo rm`
- `chmod 777`
- `> /dev/sda`
- Any other patterns you want to flag

## How It Works

1. Claude Code calls this hook before executing any Bash command
2. The script receives JSON with the command on stdin
3. It extracts the command using `jq`
4. If the command matches dangerous patterns, it prints a warning
5. It always exits 0 (allowing the command) - you control approval
