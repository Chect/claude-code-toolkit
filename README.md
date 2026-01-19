# Claude Code Toolkit

A collection of hooks, commands, scripts, and patterns for enhancing [Claude Code](https://docs.anthropic.com/en/docs/claude-code) workflows.

## Quick Start

1. Browse the components below
2. Copy files to your project's `.claude/` directory
3. Follow the README in each component for setup
4. Restart Claude Code

## Components

### Hooks

Scripts that run at specific points during Claude Code execution.

| Hook | Description |
|------|-------------|
| [dangerous-command-check](hooks/dangerous-command-check/) | Warns before executing `rm -rf` and other destructive commands |

See [hooks/README.md](hooks/README.md) for general hook documentation.

### Commands

Slash commands (`/command-name`) that extend Claude's capabilities.

| Command | Description |
|---------|-------------|
| [handoff-context](commands/handoff-context/) | Save session context for continuity across sessions |
| [edit-settings](commands/edit-settings/) | Comprehensive reference for editing settings.json |

See [commands/README.md](commands/README.md) for general command documentation.

### Scripts

Standalone scripts for automation and workflows.

| Script | Description |
|--------|-------------|
| [wip-branch-workflow](scripts/wip-branch-workflow/) | Startup script for WIP branch pattern |

See [scripts/README.md](scripts/README.md) for general script documentation.

## Installation

Each component includes:
- A README explaining what it does and why
- The actual file(s) to copy
- Setup instructions

## Requirements

- Claude Code CLI
- `jq` (for JSON parsing in hooks) - install via `brew install jq` or `apt install jq`

## Contributing

Contributions welcome! Please:
1. Follow the existing directory structure
2. Include a README with clear documentation
3. Test before submitting

## License

MIT - see [LICENSE](LICENSE)
