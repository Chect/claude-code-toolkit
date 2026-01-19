# Claude Code Toolkit

A collection of hooks, scripts, and patterns for enhancing [Claude Code](https://docs.anthropic.com/en/docs/claude-code) workflows.

## Quick Start

1. Copy the hook script to your project's `.claude/hooks/` directory
2. Add the corresponding settings snippet to your `.claude/settings.json`
3. Restart Claude Code

## Components

### Hooks

| Hook | Description |
|------|-------------|
| [dangerous-command-check](hooks/dangerous-command-check/) | Warns before executing `rm -rf` and other destructive commands |

## Installation

Each component includes:
- A README explaining what it does and why
- The script itself with detailed comments
- A `settings-snippet.json` you can copy into your settings

See the [hooks README](hooks/README.md) for general information about Claude Code hooks.

## Requirements

- Claude Code CLI
- `jq` (for JSON parsing in hooks) - install via `brew install jq` or `apt install jq`

## Contributing

Contributions welcome! Please:
1. Follow the existing directory structure
2. Include a README with clear documentation
3. Provide a `settings-snippet.json` for easy installation
4. Test your hook before submitting

## License

MIT - see [LICENSE](LICENSE)
