#!/bin/bash
# Proactive Handoff - Track session state for context handoff
# Purpose: Maintain live session state that survives context compaction
# Usage: proactive-handoff.sh <event> [args...]
#
# Events:
#   init              - Initialize new session state
#   file <path>       - Track file modification
#   agent-start <id>  - Track agent spawn
#   agent-stop <id>   - Track agent completion
#   save              - Save state before compaction
#   load              - Load state at session start
#   cleanup           - Remove completed agents and old file entries
#   next <step>       - Add next step (what to do if interrupted)
#   clear-next        - Clear next steps (task complete)
#
# TODO: Agent tracking (agent-start/agent-stop) needs Claude Code hooks
#       to be wired up. Check if SubagentStart/SubagentStop or similar
#       hook events exist. If not, may need to track via Task tool wrapper
#       or post-process the transcript. Currently these commands work
#       manually but aren't automatically triggered.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_FILE="$REPO_ROOT/.claude/session-state.md"
BACKUP_FILE="$REPO_ROOT/.claude/session-state.md.bak"
LOG_FILE="$REPO_ROOT/.claude/session-history.log"

# Ensure .claude directory exists
mkdir -p "$REPO_ROOT/.claude"

# Get current timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Initialize empty state file
init_state() {
    local ts
    ts=$(timestamp)
    cat > "$STATE_FILE" << EOF
# Session State

Auto-updated during session. Read at session start for continuity.

## Active Work

<!-- Updated by proactive-handoff.sh -->

### Current Focus
- None

### Modified Files
<!-- Files touched this session -->

### Running Agents
<!-- Background agents still executing -->

### Next Steps
<!-- What to do next if interrupted -->

## Session Info

- **Started:** $ts
- **Last Updated:** $ts

## Notes

<!-- Manual notes can be added here -->
EOF
}

# Update the "Last Updated" timestamp
update_timestamp() {
    if [ -f "$STATE_FILE" ]; then
        sed -i '' "s/\*\*Last Updated:\*\* .*/\*\*Last Updated:\*\* $(timestamp)/" "$STATE_FILE"
    fi
}

# Track a file modification
track_file() {
    local file_path="$1"
    if [ -f "$STATE_FILE" ]; then
        # Check if file already tracked
        if ! grep -q "^- \`$file_path\`" "$STATE_FILE"; then
            # Add file to Modified Files section
            sed -i '' "/<!-- Files touched this session -->/a\\
- \`$file_path\` ($(timestamp))
" "$STATE_FILE"
        fi
        update_timestamp
    fi
}

# Track agent start
track_agent_start() {
    local agent_id="$1"
    local agent_type="${2:-unknown}"
    if [ -f "$STATE_FILE" ]; then
        # Add to Running Agents section
        sed -i '' "/<!-- Background agents still executing -->/a\\
- **$agent_id** ($agent_type) - started $(timestamp)
" "$STATE_FILE"
        update_timestamp
    fi
}

# Track agent stop
track_agent_stop() {
    local agent_id="$1"
    if [ -f "$STATE_FILE" ]; then
        # Remove from Running Agents (mark as completed)
        sed -i '' "s/\*\*$agent_id\*\* .* - started .*/\*\*$agent_id\*\* - completed $(timestamp)/" "$STATE_FILE"
        update_timestamp
    fi
}

# Update next steps (replaces existing content)
update_next_steps() {
    local steps="$1"
    if [ -f "$STATE_FILE" ]; then
        # Append the step if not already present
        if ! grep -qF "$steps" "$STATE_FILE"; then
            sed -i '' "/<!-- What to do next if interrupted -->/a\\
- $steps
" "$STATE_FILE"
        fi
        update_timestamp
    fi
}

# Clear next steps (call when task complete)
clear_next_steps() {
    if [ -f "$STATE_FILE" ]; then
        # Remove all lines starting with "- " between Next Steps marker and Session Info
        sed -i '' '/<!-- What to do next if interrupted -->/,/## Session Info/{/^- /d;}' "$STATE_FILE"
        update_timestamp
    fi
}

# Save state before compaction
save_state() {
    if [ -f "$STATE_FILE" ]; then
        cp "$STATE_FILE" "$BACKUP_FILE"
        update_timestamp
    fi
}

# Load state at session start
load_state() {
    if [ -f "$STATE_FILE" ]; then
        echo "=== Previous Session State ==="
        cat "$STATE_FILE"
        echo ""
    elif [ -f "$BACKUP_FILE" ]; then
        echo "=== Restored Session State ==="
        cp "$BACKUP_FILE" "$STATE_FILE"
        cat "$STATE_FILE"
        echo ""
    fi
}

# Cleanup: remove completed agents and optionally trim file list
# Writes removed entries to session-history.log for audit trail
cleanup_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "No state file to clean up" >&2
        return
    fi

    local keep_files="${1:-20}"  # Keep last N file entries (default 20)
    local ts
    ts=$(timestamp)

    # Log header for this cleanup
    echo "" >> "$LOG_FILE"
    echo "=== Cleanup: $ts ===" >> "$LOG_FILE"

    # Extract and log completed agents before removing
    local completed_agents
    completed_agents=$(grep '- \*\*.*\*\* - completed' "$STATE_FILE" 2>/dev/null || true)
    if [ -n "$completed_agents" ]; then
        echo "Completed agents:" >> "$LOG_FILE"
        echo "$completed_agents" >> "$LOG_FILE"
    fi

    # Remove lines with "completed" in Running Agents section
    sed -i '' '/- \*\*.*\*\* - completed/d' "$STATE_FILE"

    # Count current file entries
    local file_count
    file_count=$(grep -c '^- `.*` (' "$STATE_FILE" 2>/dev/null || echo "0")

    if [ "$file_count" -gt "$keep_files" ]; then
        # Calculate how many to remove
        local remove_count=$((file_count - keep_files))

        # Extract entries to remove (oldest ones) and log them
        local removed_files
        removed_files=$(grep '^- `.*` (' "$STATE_FILE" | head -n "$remove_count")
        echo "Removed files ($remove_count):" >> "$LOG_FILE"
        echo "$removed_files" >> "$LOG_FILE"

        # Remove oldest entries (they appear first after the comment)
        local temp_file
        temp_file=$(mktemp)

        # Extract file entries, keep last N
        grep '^- `.*` (' "$STATE_FILE" | tail -n "$keep_files" > "$temp_file"

        # Remove all file entries from state file
        sed -i '' '/^- `.*` (/d' "$STATE_FILE"

        # Re-add the kept entries after the marker
        while IFS= read -r line; do
            sed -i '' "/<!-- Files touched this session -->/a\\
$line
" "$STATE_FILE"
        done < "$temp_file"

        rm -f "$temp_file"

        echo "Cleaned up: removed $remove_count old file entries, kept $keep_files"
        echo "Kept $keep_files files" >> "$LOG_FILE"
    else
        echo "Cleaned up: removed completed agents, $file_count file entries (under limit)"
        echo "Files under limit ($file_count), none removed" >> "$LOG_FILE"
    fi

    update_timestamp
}

# Main command dispatch
case "${1:-help}" in
    init)
        init_state
        echo "Session state initialized: $STATE_FILE"
        ;;
    file)
        if [ -n "${2:-}" ]; then
            track_file "$2"
        else
            echo "Usage: $0 file <path>" >&2
            exit 1
        fi
        ;;
    agent-start)
        if [ -n "${2:-}" ]; then
            track_agent_start "$2" "${3:-}"
        else
            echo "Usage: $0 agent-start <id> [type]" >&2
            exit 1
        fi
        ;;
    agent-stop)
        if [ -n "${2:-}" ]; then
            track_agent_stop "$2"
        else
            echo "Usage: $0 agent-stop <id>" >&2
            exit 1
        fi
        ;;
    save)
        save_state
        ;;
    load)
        load_state
        ;;
    cleanup)
        cleanup_state "${2:-20}"
        ;;
    next)
        if [ -n "${2:-}" ]; then
            update_next_steps "$2"
        else
            echo "Usage: $0 next <step description>" >&2
            exit 1
        fi
        ;;
    clear-next)
        clear_next_steps
        ;;
    help|*)
        echo "Usage: $0 <event> [args...]"
        echo ""
        echo "Events:"
        echo "  init              - Initialize new session state"
        echo "  file <path>       - Track file modification"
        echo "  agent-start <id>  - Track agent spawn"
        echo "  agent-stop <id>   - Track agent completion"
        echo "  save              - Save state before compaction"
        echo "  load              - Load state at session start"
        echo "  cleanup [N]       - Remove completed agents, keep last N files (default 20)"
        echo "  next <step>       - Add a next step (what to do if interrupted)"
        echo "  clear-next        - Clear all next steps (task complete)"
        ;;
esac

exit 0
