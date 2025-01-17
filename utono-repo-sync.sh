#!/usr/bin/env bash

# Description: Script to clone or update GitHub repositories belonging to the GitHub user 'utono'.
# The script requires the user to set the GITHUB_TOKEN environment variable.
# It prompts the user to confirm the token before proceeding.
# This script works for any user and can be run without root privileges.

# Ensure target directory is provided as the first argument
if [ $# -lt 1 ]; then
    echo "❌ Error: Missing target directory. Usage: $0 <target_directory>"
    exit 1
fi

# Use the provided directory as the target
targetDir="$1"

# Validate the target directory
if [ -z "$targetDir" ]; then
    echo "❌ Error: Target directory is empty."
    exit 1
fi

# Create the target directory if it doesn't exist
mkdir -p "$targetDir" || { echo "❌ Error: Failed to create target directory $targetDir"; exit 1; }

# GitHub Configuration
githubUser="utono"
cloneType="ssh"

# Ensure GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable is not set."
    echo "🔧 Please set your GitHub token with the following command:"
    echo
    echo "https://github.com/settings/tokens --> ~/.config/shell/exports"
    echo "    export GITHUB_TOKEN='your_personal_access_token'"
    echo
    echo "Or add it to your shell configuration file (~/.bashrc, ~/.zshrc, etc.)"
    echo "Then re-run this script."
    exit 1
fi

# Inform the user that GITHUB_TOKEN is being used
echo "🔍 Using GITHUB_TOKEN from your shell environment."
echo "Make sure it is set correctly in your shell configuration file (e.g., ~/.bashrc, ~/.zshrc) for future use."

# Echo the token that will be used (only show the first and last 4 characters for security)
echo "🔍 The following GitHub token will be used (partial view for security):"
echo "    ${GITHUB_TOKEN:0:4}...${GITHUB_TOKEN: -4}"

# Prompt the user to confirm the token
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

# Check for a valid GitHub token
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

# Clone or update repositories belonging to 'utono'
manage_repositories() {
    local listUserRepoUrl="https://api.github.com/user/repos?per_page=100&visibility=all"
    local userRepositories

    echo "📡 Fetching list of repositories for user '${githubUser}'..."
    userRepositories=$(curl -s "$listUserRepoUrl" -H "Authorization: token ${GITHUB_TOKEN}" | jq -r '.[].ssh_url')

    if [ -z "$userRepositories" ]; then
        echo "⚠️ No repositories found for user '${githubUser}'."
        return 0
    fi

    cd "$targetDir" || { echo "❌ Error: Failed to change to directory $targetDir"; exit 1; }
    echo "📂 Managing repositories in $(pwd)..."

    for repo in $userRepositories; do
        local repo_name=$(basename "$repo" .git)
        if [ -d "$repo_name" ]; then
            echo "🔄 Repository '$repo_name' already exists. Pulling updates..."
            cd "$repo_name" || continue
            git pull origin main || git pull origin master
            cd ..
        else
            echo "📥 Cloning repository: $repo"
            git clone --depth 1 "$repo" || { echo "❌ Error: Failed to clone $repo"; return 1; }
        fi
    done
}

# Main Execution
check_github_token
manage_repositories

echo "✅ All repositories belonging to '$githubUser' have been managed successfully in $targetDir."
exit 0
