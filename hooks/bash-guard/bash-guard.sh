#!/bin/bash
# PreToolUse hook for Bash commands
#
# Three independent guards:
# 1. Chain rejection — blocks &&, ||, ; (forces separate tool calls)
# 2. Dedicated tool enforcement — blocks grep/find/cat/etc in Bash
# 3. Directory restriction — limits write-capable commands to allowed dirs
#
# Configure allowed directories via BASH_GUARD_ALLOWED_DIRS environment variable
# (colon-separated list of absolute paths). Falls back to git repo root + ~/.claude.

# Input comes from stdin as JSON
input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

# Only check Bash tool calls
if [ "$tool" != "Bash" ]; then
    exit 0
fi

command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
    exit 0
fi

# ── Chain detection ──────────────────────────────────────────────────────
# Strip quoted strings, then check for chaining operators
stripped=$(echo "$command" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

if echo "$stripped" | grep -qE '&&|\|\||;'; then
    # Allow shell constructs (for/while/if)
    if echo "$command" | grep -qE '\b(for|while|if|do|done|then|fi|else|elif)\b'; then
        :
    else
        echo "BLOCKED: Split chained commands into separate Bash tool calls. Do not use &&, ||, or ; to chain commands." >&2
        exit 2
    fi
fi

# ── Extract verb (first word of command) ─────────────────────────────────
verb=$(echo "$command" | awk '{print $1}')

# ── Enforce dedicated tools ──────────────────────────────────────────────
# Block commands that have dedicated Claude Code tools
case "$verb" in
    grep|rg)
        echo "BLOCKED: Use the Grep tool instead of '$verb' in Bash." >&2
        exit 2 ;;
    find)
        echo "BLOCKED: Use the Glob tool instead of 'find' in Bash." >&2
        exit 2 ;;
    cat)
        echo "BLOCKED: Use the Read tool instead of 'cat' in Bash." >&2
        exit 2 ;;
    head|tail)
        echo "BLOCKED: Use the Read tool (with offset/limit) instead of '$verb' in Bash." >&2
        exit 2 ;;
    awk)
        echo "BLOCKED: Use the Edit tool instead of 'awk' in Bash." >&2
        exit 2 ;;
esac

# ── Directory restriction for write-capable commands ─────────────────────
# Build allowed directories list
if [ -n "$BASH_GUARD_ALLOWED_DIRS" ]; then
    # Use explicitly configured directories
    IFS=':' read -ra ALLOWED_DIRS <<< "$BASH_GUARD_ALLOWED_DIRS"
else
    # Default: git repo root (if in a repo) + ~/.claude
    ALLOWED_DIRS=()
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$git_root" ]; then
        ALLOWED_DIRS+=("$git_root")
    fi
    ALLOWED_DIRS+=("$HOME/.claude")
fi

# Commands that can modify files — must only target allowed directories
WRITE_COMMANDS="sed mkdir chmod python python3 uv pip npm npx"

is_write_cmd=false
for w in $WRITE_COMMANDS; do
    if [ "$verb" = "$w" ]; then
        is_write_cmd=true
        break
    fi
done

if $is_write_cmd; then
    # Extract all path-like arguments (anything starting with / or . or ~)
    # First strip single-quoted strings to avoid matching sed expressions as paths
    cmd_no_quotes=$(echo "$command" | sed -E "s/'[^']*'//g")
    paths=$(echo "$cmd_no_quotes" | grep -oE '(\/[^ ]+|\.\.?\/[^ ]+|~\/[^ ]+)' || true)

    for p in $paths; do
        # Resolve ~ to home
        resolved=$(echo "$p" | sed "s|^~|$HOME|")
        # Resolve to absolute (handles ../ etc)
        if [ -e "$resolved" ]; then
            resolved=$(cd "$(dirname "$resolved")" 2>/dev/null && pwd)/$(basename "$resolved")
        fi

        # Check if path is under any allowed directory
        allowed=false
        for dir in "${ALLOWED_DIRS[@]}"; do
            case "$resolved" in
                "$dir"*) allowed=true; break ;;
            esac
        done

        if ! $allowed; then
            dir_list=$(printf '%s, ' "${ALLOWED_DIRS[@]}")
            dir_list=${dir_list%, }
            echo "BLOCKED: '$verb' targets '$p' which is outside allowed directories ($dir_list)." >&2
            exit 2
        fi
    done
fi

exit 0
