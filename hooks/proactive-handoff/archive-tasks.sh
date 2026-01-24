#!/bin/bash
# Archive completed tasks from tasks.md
# Part of proactive-handoff cleanup system

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

TASKS_FILE=".claude/tasks.md"
ARCHIVE_DIR=".claude/archives"
WEEK=$(date +%Y-W%U)
ARCHIVE_FILE="$ARCHIVE_DIR/tasks-$WEEK.md"

# Check if tasks.md exists
if [ ! -f "$TASKS_FILE" ]; then
    echo "No tasks.md file found"
    exit 0
fi

# Create archives directory
mkdir -p "$ARCHIVE_DIR"

# Extract completed tasks
COMPLETED=$(sed -n '/## Completed/,/^##\|^$/p' "$TASKS_FILE" | grep '^- \[x\]' || true)

if [ -z "$COMPLETED" ]; then
    echo "No completed tasks to archive"
    exit 0
fi

# Count completed tasks
COUNT=$(echo "$COMPLETED" | wc -l | tr -d ' ')

# Create or append to weekly archive
if [ ! -f "$ARCHIVE_FILE" ]; then
    cat > "$ARCHIVE_FILE" << EOF
# Completed Tasks - $WEEK

## Tasks

$COMPLETED
EOF
else
    # Append to existing archive
    echo "" >> "$ARCHIVE_FILE"
    echo "$COMPLETED" >> "$ARCHIVE_FILE"
fi

# Remove completed tasks from tasks.md
# Keep the "## Completed" header but remove completed items
sed -i '' '/## Completed/,/^##\|^$/{/^- \[x\]/d;}' "$TASKS_FILE"

echo "✓ Archived $COUNT completed tasks to $ARCHIVE_FILE"
echo "  Cleared from $TASKS_FILE"
