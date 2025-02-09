#!/usr/bin/env bash

# This script synchronizes a local fork of a repository with its remote parent,
# fetches updates, and creates symbolic links in the target directory (~/.config)
# pointing to the source configuration directory. Conflicting files or directories
# in the target are backed up.

# Set repository paths and directories
REPO_DIR="$HOME/utono/cachyos-hyprland-settings"
REMOTE_REPO="git@github.com:CachyOS/cachyos-hyprland-settings.git"
SOURCE="$REPO_DIR/etc/skel/.config"
TARGET="$HOME/.config"
BACKUP_DIR="$HOME/backups/.config"

# Ensure the repository directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Repository directory $REPO_DIR does not exist."
    exit 1
fi

# Navigate to the repository
cd "$REPO_DIR" || exit

# Fetch updates from the remote repository
git fetch origin
echo "Fetched updates from remote repository."

# Ensure target and backup directories exist
mkdir -p "$TARGET"
mkdir -p "$BACKUP_DIR"

# Loop through the contents of the source directory
for item in "$SOURCE"/*; do
    base=$(basename "$item")
    target_item="$TARGET/$base"
    backup_item="$BACKUP_DIR/${base}_$(date +%Y%m%d%H%M%S)"

    # Check if a conflicting directory or file exists in the target
    if [ -e "$target_item" ] || [ -L "$target_item" ]; then
        mv "$target_item" "$backup_item"
        echo "Moved existing $target_item to $backup_item"
    fi

    # Create a symlink in the target directory
    ln -s "$item" "$target_item"
    echo "Created symlink: $target_item -> $item"
done

echo "Symlinks created in $TARGET pointing to $SOURCE, with backups stored in $BACKUP_DIR"
