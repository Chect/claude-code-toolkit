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
| [proactive-handoff](hooks/proactive-handoff/) | Track session state for continuity across sessions and through compaction |

See [hooks/README.md](hooks/README.md) for general hook documentation.

### Commands

Slash commands (`/command-name`) that extend Claude's capabilities.

| Command | Description |
|---------|-------------|
| [handoff](commands/handoff/) | **Interactive** session handoff - choose context, task, bug, or clean mode |
| [handoff-context](commands/handoff-context/) | Save general session context (legacy, use /handoff instead) |
| [handoff-context-bug](commands/handoff-context-bug/) | Save bug investigation context (legacy, use /handoff instead) |
| [edit-settings](commands/edit-settings/) | Comprehensive reference for editing settings.json |

See [commands/README.md](commands/README.md) for general command documentation.

### Scripts

Standalone scripts for automation and workflows.

| Script | Description |
|--------|-------------|
| [setup-mcp.sh](scripts/setup-mcp.sh) | Automated MCP server setup |

See [scripts/README.md](scripts/README.md) for general script documentation.

### Submodules

| Submodule | Description |
|-----------|-------------|
| [claude-squash-merge](claude-squash-merge/) | WIP branch workflow: auto-checkpoints, branch management, squash merge to main |

**WIP Branch Workflow Quick Start:**
```bash
# Add to your project
git submodule add https://github.com/Chect/claude-squash-merge.git .claude/claude-squash-merge

# Or use the interactive setup
/setup-wip-workflow
```

See [claude-squash-merge/README.md](claude-squash-merge/README.md) for full documentation.

### MCP Servers

Shared MCP (Model Context Protocol) server configuration for team use across multiple projects.

| Feature | Description |
|---------|-------------|
| [Shared MCP Config](.mcp.json) | Git, filesystem, sequential-thinking, memory, Notion, MySQL, Brave Search |
| [Setup Script](scripts/setup-mcp.sh) | Automated setup for projects using toolkit as submodule |
| [Documentation](MCP-SETUP.md) | Complete guide to MCP server configuration |

**Quick setup:**
```bash
./claude-code-toolkit/scripts/setup-mcp.sh
```

See [MCP-SETUP.md](MCP-SETUP.md) for detailed configuration and usage.

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
