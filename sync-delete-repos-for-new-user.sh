#!/usr/bin/env bash

# Usage: ./script.sh <utono_directory>
#
# Description: Script to clone or update GitHub repositories belonging to the GitHub user 'utono'.
# The script requires the user to set the GITHUB_TOKEN environment variable.
# It prompts the user to confirm the token before proceeding.
# This script works for any user and can be run without root privileges.

# Ensure the utono directory is passed as a parameter

if [ -z "$1" ]; then
    echo "❌ Error: Missing required parameter <utono_directory>."
    exit 1
fi

UTONO_DIR="$1"

# Array of non-utono directories containing repositories
declare -A EXTERNAL_REPO_DIRS=(
  ["DESTINATION_NVIM"]="$HOME/.config/nvim"
  ["DESTINATION_MPV"]="$HOME/.config/mpv"
  ["TTY_DESTINATION"]="$HOME/tty-dotfiles"
)

# Ensure GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable is not set."
    exit 1
fi

echo "🔍 Using GitHub token (partial view): ${GITHUB_TOKEN:0:4}...${GITHUB_TOKEN: -4}"
read -p "⚠️  Do you want to use this token? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Operation cancelled by user."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required to parse JSON responses. Please install jq."
    exit 1
fi

# Validate GitHub token
check_github_token() {
    echo "🔍 Verifying GitHub token..."
    local http_status
    http_status=$(curl -o /dev/null -s -w "%{http_code}\n" -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/user)
    if [[ "$http_status" -ne 200 ]]; then
        echo "❌ Error: Invalid or expired GitHub token. HTTP status: $http_status"
        exit 1
    fi
    echo "✅ GitHub token verified successfully."
}

# Clone or update repositories
manage_repositories() {
    local dirs=("$UTONO_DIR" "${EXTERNAL_REPO_DIRS[DESTINATION_NVIM]}" "${EXTERNAL_REPO_DIRS[DESTINATION_MPV]}" "${EXTERNAL_REPO_DIRS[TTY_DESTINATION]}")
    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        echo "📂 Checking repositories in $dir..."
        cd "$dir" || continue
        for repo in */; do
            [[ -d "$repo/.git" ]] || continue
            echo "🔄 Updating repository $repo..."
            cd "$repo" || continue
            git pull origin main || git pull origin master
            cd "$dir" || exit
        done
    done
}

# Main Execution
check_github_token
manage_repositories

echo "✅ Repository update completed."
exit 0
