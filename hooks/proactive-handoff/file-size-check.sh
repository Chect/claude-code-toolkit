#!/bin/bash
# Monitor file sizes for proactive-handoff system
# Part of proactive-handoff cleanup system

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "Proactive Handoff File Size Report"
echo "===================================="
echo ""

# Helper function to get file size
get_size() {
    local file="$1"
    if [ -f "$file" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            stat -f%z "$file"
        else
            stat -c%s "$file"
        fi
    else
        echo "0"
    fi
}

# Helper function to format size
format_size() {
    local size=$1
    local size_kb=$((size / 1024))
    if [ "$size_kb" -gt 1024 ]; then
        local size_mb=$((size_kb / 1024))
        echo "${size_mb}MB"
    else
        echo "${size_kb}KB"
    fi
}

# Check main files
TOTAL_SIZE=0

echo "Core Files"
echo "----------"
for file in session-state.md tasks.md context.md claude.md; do
    if [ -f ".claude/$file" ]; then
        SIZE=$(get_size ".claude/$file")
        SIZE_FORMATTED=$(format_size "$SIZE")
        LINES=$(wc -l < ".claude/$file" | tr -d ' ')
        printf "%-20s %8s  %5s lines\n" "$file" "$SIZE_FORMATTED" "$LINES"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
done

echo ""
echo "MCP Memory"
echo "----------"
if [ -f ".claude/memory.json" ]; then
    SIZE=$(get_size ".claude/memory.json")
    SIZE_FORMATTED=$(format_size "$SIZE")
    printf "%-20s %8s\n" "memory.json" "$SIZE_FORMATTED"
    TOTAL_SIZE=$((TOTAL_SIZE + SIZE))

    # Warn if large
    SIZE_KB=$((SIZE / 1024))
    if [ "$SIZE_KB" -gt 500 ]; then
        echo "  ⚠️  Large memory file, consider cleanup"
    fi
else
    echo "memory.json          not created yet"
fi

echo ""
echo "Supporting Files"
echo "----------------"
for file in session-state.md.bak session-history.log; do
    if [ -f ".claude/$file" ]; then
        SIZE=$(get_size ".claude/$file")
        SIZE_FORMATTED=$(format_size "$SIZE")
        printf "%-20s %8s\n" "$file" "$SIZE_FORMATTED"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
done

echo ""
echo "Archives"
echo "--------"
if [ -d ".claude/archives" ]; then
    ARCHIVE_SIZE=$(du -sk .claude/archives 2>/dev/null | cut -f1)
    ARCHIVE_SIZE_MB=$((ARCHIVE_SIZE / 1024))
    FILE_COUNT=$(find .claude/archives -type f | wc -l | tr -d ' ')
    echo "Total archived:      ${ARCHIVE_SIZE_MB}MB ($FILE_COUNT files)"
    TOTAL_SIZE=$((TOTAL_SIZE + (ARCHIVE_SIZE * 1024)))
else
    echo "No archives directory"
fi

echo ""
echo "Total Storage"
echo "-------------"
TOTAL_FORMATTED=$(format_size "$TOTAL_SIZE")
echo "Total: $TOTAL_FORMATTED"

echo ""

# Recommendations
WARNINGS=0

for file in session-state.md tasks.md context.md; do
    if [ -f ".claude/$file" ]; then
        SIZE=$(get_size ".claude/$file")
        SIZE_KB=$((SIZE / 1024))
        LINES=$(wc -l < ".claude/$file" | tr -d ' ')

        if [ "$file" = "session-state.md" ] && [ "$LINES" -gt 200 ]; then
            echo "⚠️  $file has $LINES lines (>200)"
            echo "   Run: .claude/hooks/proactive-handoff.sh cleanup 20"
            WARNINGS=$((WARNINGS + 1))
        fi

        if [ "$file" = "tasks.md" ]; then
            COMPLETED=$(grep -c '^- \[x\]' ".claude/$file" 2>/dev/null || echo "0")
            if [ "$COMPLETED" -gt 20 ]; then
                echo "⚠️  $file has $COMPLETED completed tasks (>20)"
                echo "   Run: .claude/hooks/archive-tasks.sh"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    fi
done

if [ "$WARNINGS" -eq 0 ]; then
    echo "✓ All files are within healthy size limits"
fi

echo ""
echo "Cleanup Commands"
echo "----------------"
echo "Session state:  .claude/hooks/proactive-handoff.sh cleanup 20"
echo "Archive tasks:  .claude/hooks/archive-tasks.sh"
echo "Memory health:  .claude/hooks/check-memory-health.sh"
