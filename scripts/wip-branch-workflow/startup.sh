#!/bin/bash
# Claude startup script - handles branch setup
# Run at the start of each session to ensure proper git state

set -e

cd "$(git rev-parse --show-toplevel)"

USER_NAME=$(echo $USER)
WIP_BRANCH="claude-wip-$USER_NAME"

echo "=== Claude Startup ==="
echo ""

# --- Main repo branch setup ---
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ]; then
    MAIN_STATUS=$(git status --porcelain)

    if [ -z "$MAIN_STATUS" ]; then
        # Clean - pull and switch to wip
        echo "Main repo: clean, pulling latest..."
        git pull origin main

        if git show-ref --verify --quiet "refs/heads/$WIP_BRANCH"; then
            git checkout "$WIP_BRANCH"
            echo "Main repo: switched to existing $WIP_BRANCH"
        else
            git checkout -b "$WIP_BRANCH" main
            echo "Main repo: created new $WIP_BRANCH"
        fi
    else
        # Dirty - warn and move to wip without pulling
        echo "WARNING: Found uncommitted changes on main:"
        echo "$MAIN_STATUS"
        echo ""
        echo "Moving changes to $WIP_BRANCH (not pulling to avoid conflicts)"

        if git show-ref --verify --quiet "refs/heads/$WIP_BRANCH"; then
            git checkout "$WIP_BRANCH"
        else
            git checkout -b "$WIP_BRANCH"
        fi
    fi
else
    echo "Main repo: already on $CURRENT_BRANCH (leaving as-is)"
fi

echo ""
echo "=== Startup Complete ==="
