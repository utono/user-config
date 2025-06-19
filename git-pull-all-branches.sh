#!/usr/bin/env bash

# git-pull-all-branches.sh
# Interactively track remote branches from 'origin' using a robust fallback flow.

set -euo pipefail

# Ensure we're inside a Git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ Not inside a Git repository."
    exit 1
fi

echo "📡 Fetching all remote branches from 'origin'..."
git fetch origin "+refs/heads/*:refs/remotes/origin/*"

echo "📋 Select remote branches to track (TAB to select, ENTER to confirm):"

# Only list actual remote-tracking branches (no HEAD, no tags)
branches=$(git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin/ | \
    grep -v '^HEAD$' | fzf --multi)

if [[ -z "$branches" ]]; then
    echo "❌ No branches selected. Exiting."
    exit 1
fi

for branch in $branches; do
    # Check if the remote-tracking ref exists and is valid
    if ! git rev-parse --verify "refs/remotes/origin/$branch" &>/dev/null; then
        echo "⚠️  Skipping '$branch': not a valid remote-tracking ref."
        continue
    fi

    if git show-ref --quiet --verify "refs/heads/$branch"; then
        echo "🔁 Local branch '$branch' already exists. Repointing to origin/$branch."
    else
        echo "✅ Creating local branch '$branch' from origin/$branch"
    fi

    # Use checkout -B to force link without tracking errors
    git checkout -B "$branch" "origin/$branch" &>/dev/null

    # Manually set upstream tracking to be explicit
    git branch --set-upstream-to="origin/$branch" "$branch" &>/dev/null || true
done

echo "🎉 Done. Use 'git branch -vv' to review tracking setup."
