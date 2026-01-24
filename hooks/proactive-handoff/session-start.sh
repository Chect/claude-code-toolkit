#!/bin/bash
# SessionStart hook - loads previous session state
# Part of proactive-handoff system

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Load previous session state if exists, or initialize new one
if [ -f ".claude/session-state.md" ]; then
    echo "=== Session State (previous session) ==="
    cat ".claude/session-state.md"
    echo ""
    # Initialize fresh state for new session
    .claude/hooks/proactive-handoff.sh init 2>/dev/null || true
elif [ -f ".claude/hooks/proactive-handoff.sh" ]; then
    # No previous state, just initialize
    .claude/hooks/proactive-handoff.sh init 2>/dev/null || true
fi

# Load tasks and instruct Claude to create TodoWrite from them
if [ -f ".claude/tasks.md" ]; then
    echo "=== Tasks (use TodoWrite tool to track these) ==="
    cat ".claude/tasks.md"
    echo ""
    echo "IMPORTANT: Create TodoWrite todos from the Active Tasks above."
    echo "Update .claude/tasks.md as you complete tasks."
    echo ""
fi
