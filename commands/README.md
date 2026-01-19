# Claude Code Commands

Commands are slash commands (like `/handoff-context`) that you can invoke in Claude Code. They're markdown files that provide instructions Claude follows when you invoke them.

## Installation

1. Copy the `.md` file to your project's `.claude/commands/` directory
2. Restart Claude Code
3. Invoke with `/<command-name>`

## Available Commands

| Command | Description |
|---------|-------------|
| [handoff-context](handoff-context/) | Save session context for the next session |
| [edit-settings](edit-settings/) | Reference guide for editing settings.json |

## Creating Your Own Commands

Create a file `.claude/commands/my-command.md`:

```markdown
Description of what this command does.

## Instructions

Step-by-step instructions for Claude to follow.

## Arguments
$ARGUMENTS
```

Use `$ARGUMENTS` to capture any text after the command name.
