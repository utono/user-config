#!/usr/bin/env bash

# Usage: ./utono-update-repos.sh ~/utono
# Updates Git repositories inside the given directory and standalone repositories.

if [ $# -lt 1 ]; then
    echo "❌ Error: Missing target directory. Usage: $0 <target_directory>"
    exit 1
fi

# Primary directory (passed as argument)
targetDir="$1"

# List of standalone Git repositories
declare -a REPO_DIRS=(
    "$HOME/.config/mpv"
    "$HOME/.config/nvim"
    "$HOME/tty-dotfiles"
)

# Function to update a Git repository
update_repository() {
    local repo_dir="$1"

    # Ensure the directory exists and is a Git repository
    if [[ ! -d "$repo_dir/.git" ]]; then
        echo "⚠️ Skipping: '$repo_dir' is not a Git repository."
        return
    fi

    echo "🔄 Updating repository: $repo_dir"
    cd "$repo_dir" || { echo "❌ Error: Failed to enter $repo_dir"; return; }

    # Determine the current branch (prefer main, fallback to master)
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
        git pull origin "$branch"
    else
        echo "⚠️ Warning: No main or master branch detected. Checking remote..."
        if git show-ref --verify --quiet "refs/remotes/origin/main"; then
            git pull origin main
        elif git show-ref --verify --quiet "refs/remotes/origin/master"; then
            git pull origin master
        else
            echo "❌ Error: Neither 'main' nor 'master' branch found for '$repo_dir'. Skipping."
        fi
    fi
}

# Process all repositories inside the target directory
if [[ -d "$targetDir" ]]; then
    echo "📂 Searching for repositories in '$targetDir'..."
    for subdir in "$targetDir"/*; do
        [[ -d "$subdir/.git" ]] && update_repository "$subdir"
    done
else
    echo "❌ Error: Target directory '$targetDir' does not exist."
    exit 1
fi

# Update standalone repositories
for repo_dir in "${REPO_DIRS[@]}"; do
    [[ -d "$repo_dir" ]] && update_repository "$repo_dir"
done

echo "✅ Update complete."
exit 0
