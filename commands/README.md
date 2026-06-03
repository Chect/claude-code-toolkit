# Claude Code Commands

Commands are slash commands (like `/handoff-context`) that you can invoke in Claude Code. They're markdown files that provide instructions Claude follows when you invoke them.

## Installation

1. Copy the `.md` file to your project's `.claude/commands/` directory
2. Restart Claude Code
3. Invoke with `/<command-name>`

## Available Commands

| Command | Description |
|---------|-------------|
| [handoff](handoff/) | Interactive session handoff (context / task / bug / clean) |
| [edit-settings](edit-settings/) | Reference guide for editing settings.json |

### `/handoff` — how it works

`/handoff` saves session state so the next context window can pick up cold. It is written for what the *next* window needs to **act**: it prioritizes the forward-looking conversation — the decisions and discussion about what to do next — over a record of finished work (which is recoverable from git). When trimming to a size budget, historical narrative is cut first.

Modes:

- **Context** — general session context; clears task/bug state.
- **Task** — treated as a moving process. `current-task.md` leads with the decided direction, the immediate next action, and still-open questions; completed work is demoted to a brief git-recoverable fallback.
- **Bug** — subdivided into live state and an empirical ledger:
  - `current-bug.md` — status, current hypothesis, **Confirmed Facts** (don't re-investigate), **Ruled Out** dead ends (don't retry), next step.
  - `bug-test-log.md` — append-only. Every test as a `T#` entry with the **exact command**, the **actual result**, and a PASS / FAIL / INCONCLUSIVE verdict, so settled tests and dead ends are never re-run.
- **Clean** — reset session state, keep project config (`CLAUDE.md`, settings, and `.claude/docs|commands|skills|hooks`).

Task and Bug modes also capture the user's recent prompts to `recent-prompts.md` for intent and phrasing.

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
