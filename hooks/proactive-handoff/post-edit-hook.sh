#!/bin/bash
# PostToolUse hook for Edit/Write/NotebookEdit
# Purpose: Extract file path from hook input and track in session state
#
# Hook receives JSON via stdin with structure:
# { "tool_input": { "file_path": "/path/to/file" }, ... }

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path using jq (for Write/Edit, field is "file_path")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null || true)

# Only proceed if we got a file path
if [ -n "$FILE_PATH" ]; then
    .claude/hooks/proactive-handoff.sh file "$FILE_PATH" 2>/dev/null || true
fi

exit 0
