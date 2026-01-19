# Claude Code Hooks

Hooks let you run custom scripts at specific points during Claude Code's execution. They're useful for validation, logging, safety checks, and automation.

## Hook Types

| Hook | When it runs | Use cases |
|------|--------------|-----------|
| `PreToolUse` | Before a tool executes | Validate commands, warn about dangerous operations, require confirmation |
| `PostToolUse` | After a tool completes | Log activity, trigger notifications, run follow-up tasks |
| `Notification` | When Claude sends a notification | Custom notification handling |
| `Stop` | When Claude stops | Cleanup, final checks, session summaries |

## How Hooks Work

1. Claude Code triggers the hook event
2. Your script receives context via stdin (JSON)
3. Your script's exit code determines behavior:
   - `0` - Allow the operation to proceed
   - `2` - Block the operation (for PreToolUse hooks)
   - Other - Allow but may log warnings

## Installation

### 1. Create the hooks directory

```bash
mkdir -p .claude/hooks
```

### 2. Copy the hook script

```bash
cp dangerous-command-check.sh .claude/hooks/
chmod +x .claude/hooks/dangerous-command-check.sh
```

### 3. Register in settings.json

Add to `.claude/settings.json` (create if it doesn't exist):

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

### 4. Restart Claude Code

Settings changes require a restart to take effect.

## Hook Input Format

Hooks receive JSON on stdin with tool-specific data. For Bash tools:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/test"
  }
}
```

## Tips

- Use `jq` for reliable JSON parsing
- Always exit 0 unless you want to block (exit 2)
- Print warnings to stdout - they'll appear in the terminal
- Test hooks thoroughly before relying on them

## Available Hooks

| Hook | Description |
|------|-------------|
| [dangerous-command-check](dangerous-command-check/) | Warns on `rm -rf` and similar destructive commands |
