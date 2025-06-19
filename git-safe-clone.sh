#!/usr/bin/env bash

# git-safe-clone.sh
# Drop-in replacement for `git clone` to bypass fatal ref update errors.

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <repo-url> [target-dir]"
    exit 1
fi

REPO="$1"
DIR="${2:-$(basename "$REPO" .git)}"

echo "🔁 Attempting normal 'git clone' into $DIR..."
if git clone "$REPO" "$DIR"; then
    echo "✅ Clone succeeded normally."
    exit 0
fi

echo "⚠️  Normal clone failed. Retrying with manual init/fetch workaround..."
mkdir -p "$DIR"
cd "$DIR"
git init
git remote add origin "$REPO"
git fetch origin
DEFAULT_BRANCH=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
git checkout -b "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"
git branch --set-upstream-to="origin/$DEFAULT_BRANCH"

echo "✅ Repo restored manually to $DEFAULT_BRANCH in $DIR."
