#!/usr/bin/env bash

# Use the first parameter as the directory or prompt the user if not provided
REPO_DIR=${1:-}

if [ -z "$REPO_DIR" ]; then
    read -rp "Enter the directory containing Git repositories: " REPO_DIR
fi

# Validate the directory
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: The specified directory does not exist."
    exit 1
fi

# Loop through each subdirectory in the specified directory
for dir in "$REPO_DIR"/*/; do
    # Check if the directory is a Git repository
    if [ -d "$dir/.git" ]; then
        echo "Entering repository: $dir"
        cd "$dir" || continue
        
        # Check for uncommitted changes
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "Uncommitted changes found. Stashing changes..."
            git stash
            STASHED=true
        else
            STASHED=false
        fi
        
        # Pull the latest changes from the remote repository
        echo "Pulling latest changes..."
        git pull

        # Leave the stash untouched (do not pop or drop it)
        if [ "$STASHED" = true ]; then
            echo "Stashed changes have been left in the stash list."
        fi

        echo "Done with repository: $dir"
        echo "-------------------------"
    fi
done

echo "All repositories in $REPO_DIR processed."
