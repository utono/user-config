#!/usr/bin/env bash

# git-pull-all-branches.sh
# Interactively pull and track all branches from the 'origin' remote using fzf.

set -euo pipefail

# Ensure we're in a Git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ Not inside a Git repository."
    exit 1
fi

echo "📡 Fetching all branches from origin..."
git fetch origin "+refs/heads/*:refs/remotes/origin/*"

echo "📋 Select remote branches to track (use TAB to select, ENTER to confirm):"

branches=$(git branch -r | grep 'origin/' | grep -v 'HEAD' | sed 's|origin/||' | fzf --multi)

if [[ -z "$branches" ]]; then
    echo "❌ No branches selected. Exiting."
    exit 1
fi

for branch in $branches; do
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        echo "🔁 Local branch '$branch' already exists. Skipping."
    else
        echo "✅ Creating local branch '$branch' tracking 'origin/$branch'"
        git branch --track "$branch" "origin/$branch"
    fi
done

echo "🎉 Done. You can now checkout any of the new branches."
