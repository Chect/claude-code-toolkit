#!/bin/bash
# SessionStart hook - surfaces handoff context + previous session state
# Part of proactive-handoff system

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# Surface all handoff artifacts written by /handoff (context.md, mode-matched
# current-task.md / current-bug.md + bug-test-log.md, recent-prompts.md) plus
# the previous live session-state.md. Without this, a post-/clear session is
# unaware a handoff occurred.
"$HOOK_DIR/proactive-handoff.sh" load 2>/dev/null || true

# Start a fresh live-state file for this session.
"$HOOK_DIR/proactive-handoff.sh" init 2>/dev/null || true
