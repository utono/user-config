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

logFile="$HOME/utono/user-config/utono-clone-failures.log"
: > "$logFile"  # Clear previous log contents

echo "📡 Fetching repository list for '$githubUser'..."
repoList=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  "https://api.github.com/user/repos?per_page=100&visibility=all" | \
  jq -r '.[].ssh_url')

if [ -z "$repoList" ]; then
    echo "⚠️ No repositories found for user '${githubUser}'."
    exit 0
fi

cd "$targetDir" || { echo "❌ Error: Failed to enter $targetDir"; exit 1; }

for repo in $repoList; do
    repo_name=$(basename "$repo" .git)
    if [ -d "$repo_name" ]; then
        echo "✅ Repository '$repo_name' already exists, skipping..."
        continue
    fi

    echo "📥 Cloning $repo_name..."

    # Try default clone
    if git clone --config remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*' --depth 1 "$repo"; then
        continue
    fi

    echo "⚠️ Default clone failed for $repo_name. Retrying with --single-branch --branch master..."
    if git clone --depth 1 --single-branch --branch master "$repo"; then
        continue
    fi

    echo "⚠️ Retry with 'master' failed. Trying with --single-branch --branch main..."
    if git clone --depth 1 --single-branch --branch main "$repo"; then
        continue
    fi

    echo "⚠️ Retry with 'main' failed. Trying with --no-tags..."
    if git clone --depth 1 --no-tags "$repo"; then
        continue
    fi

    echo "❌ Error cloning $repo_name: All fallback attempts failed."
    echo "$repo_name ($repo)" >> "$logFile"
done

echo "✅ Cloning complete."
echo "📄 Failed repositories (if any) logged to: $logFile"
exit 0
