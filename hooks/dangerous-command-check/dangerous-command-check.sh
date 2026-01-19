#!/bin/bash
#
# dangerous-command-check.sh
# PreToolUse hook for Claude Code
#
# PURPOSE:
#   Displays a prominent warning when Claude is about to execute
#   destructive commands like `rm -rf`. Does NOT block the command -
#   just warns so you can review before approving.
#
# USAGE:
#   1. Copy to .claude/hooks/dangerous-command-check.sh
#   2. chmod +x .claude/hooks/dangerous-command-check.sh
#   3. Add PreToolUse hook to .claude/settings.json (see settings-snippet.json)
#   4. Restart Claude Code
#
# REQUIREMENTS:
#   - jq (brew install jq / apt install jq)
#
# INPUT:
#   Receives JSON on stdin from Claude Code:
#   {
#     "tool_name": "Bash",
#     "tool_input": {
#       "command": "the shell command"
#     }
#   }
#
# EXIT CODES:
#   0 - Allow command (always, this hook only warns)
#   2 - Would block command (not used by this hook)
#

# Read the tool input JSON from stdin
input=$(cat)

# Extract the command using jq
# Falls back gracefully if jq isn't installed
if command -v jq &> /dev/null; then
    command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
    # Fallback to python3 if jq not available
    command=$(echo "$input" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('tool_input', {}).get('command', ''))" 2>/dev/null)
fi

# Check for dangerous patterns
# Matches: rm -rf, rm -fr, rm -rfi, rm -fR, etc.
if echo "$command" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r)|-rf|-fr)\s'; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  DANGER: rm -rf DETECTED! ⚠️                                      ║"
    echo "╠══════════════════════════════════════════════════════════════════════╣"
    echo "║  This command will PERMANENTLY DELETE files without confirmation!    ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Command: $command"
    echo ""
    echo "Review carefully before approving!"
    echo ""
fi

# Always exit 0 to allow the command
# User controls approval through Claude Code's normal flow
exit 0
