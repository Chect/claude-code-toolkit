#!/bin/bash
# Check MCP Memory health and provide cleanup recommendations
# Part of proactive-handoff cleanup system

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

MEMORY_FILE=".claude/memory.json"

echo "Memory Health Check"
echo "==================="
echo ""

if [ ! -f "$MEMORY_FILE" ]; then
    echo "✓ No memory file found (not yet created)"
    echo ""
    echo "Memory will be created when MCP Memory server is used."
    exit 0
fi

# Check file size
if [[ "$OSTYPE" == "darwin"* ]]; then
    SIZE=$(stat -f%z "$MEMORY_FILE")
    MODIFIED=$(stat -f%Sm -t "%Y-%m-%d %H:%M" "$MEMORY_FILE")
else
    SIZE=$(stat -c%s "$MEMORY_FILE")
    MODIFIED=$(stat -c%y "$MEMORY_FILE" | cut -d. -f1)
fi

SIZE_KB=$((SIZE / 1024))

echo "File: $MEMORY_FILE"
echo "Size: ${SIZE_KB}KB ($SIZE bytes)"
echo "Last modified: $MODIFIED"
echo ""

# Estimate entity count (rough heuristic)
if command -v jq &> /dev/null; then
    # Use jq if available for accurate count
    ENTITY_COUNT=$(jq '[.entities[]? // empty] | length' "$MEMORY_FILE" 2>/dev/null || echo "0")
    RELATION_COUNT=$(jq '[.relations[]? // empty] | length' "$MEMORY_FILE" 2>/dev/null || echo "0")
else
    # Fallback: count "name": occurrences (approximate)
    ENTITY_COUNT=$(grep -c '"name":' "$MEMORY_FILE" 2>/dev/null || echo "0")
    RELATION_COUNT=$(grep -c '"from":' "$MEMORY_FILE" 2>/dev/null || echo "0")
fi

echo "Entities: ~$ENTITY_COUNT"
echo "Relations: ~$RELATION_COUNT"
echo ""

# Health assessment
WARNINGS=0

if [ "$SIZE_KB" -gt 500 ]; then
    echo "⚠️  WARNING: Memory file is large (${SIZE_KB}KB)"
    echo "   Recommended actions:"
    echo "   - Review entities and remove old/completed projects"
    echo "   - Prune outdated observations"
    echo "   - Remove orphaned entities (no relations)"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$ENTITY_COUNT" -gt 100 ]; then
    echo "⚠️  INFO: High entity count ($ENTITY_COUNT)"
    echo "   Consider:"
    echo "   - Are all entities still relevant?"
    echo "   - Remove archived/completed projects"
    echo "   - Consolidate duplicate entities"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$SIZE_KB" -lt 10 ] && [ "$ENTITY_COUNT" -lt 10 ]; then
    echo "✓ Memory usage is healthy and minimal"
    echo ""
fi

if [ "$WARNINGS" -eq 0 ] && [ "$SIZE_KB" -ge 10 ]; then
    echo "✓ Memory size is reasonable (${SIZE_KB}KB)"
    echo "✓ Entity count is manageable ($ENTITY_COUNT entities)"
    echo ""
fi

# Cleanup recommendations
echo "Cleanup Commands"
echo "================"
echo ""
echo "To review and cleanup memory in Claude Code:"
echo ""
echo "  > Show me the entire knowledge graph"
echo "  > What projects are in memory?"
echo "  > Remove entity \"old-project-name\""
echo "  > Remove observation \"outdated fact\" from entity-name"
echo "  > Find entities with no relations"
echo ""
echo "See CLEANUP-STRATEGIES.md for detailed cleanup procedures."
