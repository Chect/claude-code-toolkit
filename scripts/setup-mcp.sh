#!/bin/bash
# Setup MCP servers from claude-code-toolkit
# Run this from your project root where claude-code-toolkit is a submodule

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "Setting up MCP servers from claude-code-toolkit..."
echo ""
echo "Toolkit location: $TOOLKIT_ROOT"
echo "Project root: $PROJECT_ROOT"
echo ""

# Check if .mcp.json exists in project root
if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
    echo "WARNING: $PROJECT_ROOT/.mcp.json already exists"
    echo ""
    echo "Options:"
    echo "  1) Merge toolkit MCP config into existing .mcp.json (manual)"
    echo "  2) Backup existing and use toolkit version"
    echo "  3) Cancel"
    echo ""
    read -p "Choose option (1/2/3): " choice

    case $choice in
        1)
            echo ""
            echo "Please manually merge these servers from:"
            echo "  $TOOLKIT_ROOT/.mcp.json"
            echo "Into your existing:"
            echo "  $PROJECT_ROOT/.mcp.json"
            exit 0
            ;;
        2)
            echo "Backing up existing .mcp.json to .mcp.json.bak"
            cp "$PROJECT_ROOT/.mcp.json" "$PROJECT_ROOT/.mcp.json.bak"
            ;;
        3)
            echo "Cancelled"
            exit 0
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
fi

# Create symlink or copy
echo ""
echo "Setup method:"
echo "  1) Symlink (recommended - stays in sync with toolkit updates)"
echo "  2) Copy (allows local customization)"
echo ""
read -p "Choose option (1/2): " method

case $method in
    1)
        echo "Creating symlink..."
        ln -sf "$TOOLKIT_ROOT/.mcp.json" "$PROJECT_ROOT/.mcp.json"
        echo "✓ Symlinked $PROJECT_ROOT/.mcp.json -> $TOOLKIT_ROOT/.mcp.json"
        ;;
    2)
        echo "Copying file..."
        cp "$TOOLKIT_ROOT/.mcp.json" "$PROJECT_ROOT/.mcp.json"
        echo "✓ Copied $TOOLKIT_ROOT/.mcp.json to $PROJECT_ROOT/.mcp.json"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "MCP servers configured! Available servers:"
echo "  - git: Git operations"
echo "  - filesystem: Secure file operations"
echo "  - sequential-thinking: Enhanced problem-solving"
echo "  - memory: Persistent knowledge graph"
echo "  - mysql: MySQL database access (disabled by default, needs credentials)"
echo "  - brave-search: Web search (disabled by default, needs API key)"
echo ""
echo "To enable MySQL:"
echo "  1. Set environment variables: MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE"
echo "  2. Edit .mcp.json and set 'disabled: false' for mysql"
echo ""
echo "To enable Brave Search:"
echo "  1. Get API key from https://brave.com/search/api/"
echo "  2. Set BRAVE_API_KEY environment variable"
echo "  3. Edit .mcp.json and set 'disabled: false' for brave-search"
echo ""
echo "To see configured servers:"
echo "  claude mcp list"
echo ""
echo "To test in Claude Code:"
echo "  Use /mcp command"
