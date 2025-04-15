#!/usr/bin/env bash

# Usage: ./utono-clone-repos.sh ~/utono
# Clones all GitHub repositories belonging to 'utono' into the target directory.
#
# GITHUB_TOKEN must not be expired:
# https://github.com/settings/tokens

if [ $# -lt 1 ]; then
    echo "❌ Error: Missing target directory. Usage: $0 <target_directory>"
    exit 1
fi

targetDir="$1"
mkdir -p "$targetDir" || { echo "❌ Error: Failed to create target directory"; exit 1; }

githubUser="utono"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN is not set. Please export it in your shell configuration."
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "❌ Error: jq is required but not installed."
    exit 1
fi

echo "📡 Fetching repository list..."
repoList=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/user/repos?per_page=100&visibility=all" | jq -r '.[].ssh_url')

if [ -z "$repoList" ]; then
    echo "⚠️ No repositories found for user '${githubUser}'."
    exit 0
fi

cd "$targetDir" || { echo "❌ Error: Failed to enter $targetDir"; exit 1; }

for repo in $repoList; do
    repo_name=$(basename "$repo" .git)
    if [ ! -d "$repo_name" ]; then
        echo "📥 Cloning $repo_name..."
        git clone --depth 1 "$repo" || { echo "❌ Error cloning $repo_name"; }
    else
        echo "✅ Repository '$repo_name' already exists, skipping..."
    fi
done

echo "✅ Cloning complete."
exit 0
