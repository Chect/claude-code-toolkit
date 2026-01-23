# MCP Server Configuration

This toolkit includes a shared MCP (Model Context Protocol) server configuration for use across multiple projects.

## Quick Setup

From your project root (where claude-code-toolkit is a submodule):

```bash
./claude-code-toolkit/scripts/setup-mcp.sh
```

This will either symlink or copy the `.mcp.json` configuration to your project root.

## Included MCP Servers

### Always Enabled

| Server | Purpose | Setup |
|--------|---------|-------|
| **git** | Git operations (status, diff, log, commits) | No setup needed |
| **filesystem** | Secure file operations with access controls | No setup needed |
| **sequential-thinking** | Enhanced problem-solving and reasoning | No setup needed |
| **memory** | Persistent knowledge graph across sessions | No setup needed |

### Requires Configuration (Disabled by Default)

| Server | Purpose | Setup |
|--------|---------|-------|
| **mysql** | MySQL database queries and operations | Set env vars, enable in .mcp.json |
| **brave-search** | Privacy-focused web and local search | Get API key, enable in .mcp.json |

## Environment Variables

### MySQL Configuration

```bash
export MYSQL_HOST=localhost        # Default: localhost
export MYSQL_PORT=3306             # Default: 3306
export MYSQL_USER=your_user
export MYSQL_PASSWORD=your_password
export MYSQL_DATABASE=your_database
```

### Brave Search

```bash
export BRAVE_API_KEY=your_api_key  # Get from https://brave.com/search/api/
```

## Enabling Disabled Servers

Edit `.mcp.json` and change `"disabled": true` to `"disabled": false`:

```json
{
  "mcpServers": {
    "mysql": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-mysql"],
      "env": { ... },
      "disabled": false  // Changed from true
    }
  }
}
```

## Setup Methods

### Method 1: Symlink (Recommended)

Stays synchronized with toolkit updates:

```bash
ln -sf claude-code-toolkit/.mcp.json .mcp.json
```

### Method 2: Copy

Allows local customization:

```bash
cp claude-code-toolkit/.mcp.json .mcp.json
```

## Project-Specific Environment Variables

Create `.env` or set in your shell profile:

```bash
# In your project root
cat > .env << 'EOF'
MYSQL_HOST=localhost
MYSQL_USER=devuser
MYSQL_PASSWORD=devpass
MYSQL_DATABASE=myapp_dev
BRAVE_API_KEY=your_brave_key
EOF

# Add to .gitignore
echo ".env" >> .gitignore
```

## Using MCP Servers in Claude Code

### Check configured servers

```bash
claude mcp list
```

### Check server status

Within Claude Code:
```
/mcp
```

### Example usage

Once configured, Claude Code can:
- Run git operations without bash commands
- Query your MySQL database directly
- Search the web for documentation
- Maintain persistent memory across sessions
- Access files with proper security controls

## Adding More Servers

Edit `.mcp.json` to add additional MCP servers:

```json
{
  "mcpServers": {
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${POSTGRES_URL}"
      }
    }
  }
}
```

## Security Notes

1. **Never commit credentials** to `.mcp.json` - use environment variables
2. **Use `${VAR}` syntax** for environment variable expansion
3. **Filesystem server** respects configured directory restrictions
4. **Disable unused servers** to reduce attack surface
5. **Keep MCP servers updated** - especially after security advisories

## Troubleshooting

### Servers not showing up

```bash
# Verify configuration
cat .mcp.json

# Check Claude Code can find it
claude mcp list

# Restart Claude Code
```

### Environment variables not working

```bash
# Check variables are set
echo $MYSQL_USER

# Try explicit value (testing only)
# Edit .mcp.json temporarily with hardcoded value
```

### npx command fails

```bash
# Install Node.js if not present
# Verify npx is available
npx --version

# Try installing package globally
npm install -g @modelcontextprotocol/server-git
```

## References

- [Claude Code MCP Documentation](https://code.claude.com/docs/en/mcp)
- [Model Context Protocol Specification](https://modelcontextprotocol.io)
- [Official MCP Servers Repository](https://github.com/modelcontextprotocol/servers)
