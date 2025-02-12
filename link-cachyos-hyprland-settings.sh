#!/usr/bin/env bash

# link-cachyos-hyprland-settings.sh
#
# Creates symbolic links from the ~/utono/cachyos-hyprland-settings repository 
# to ~/.config, backing up any existing conflicting files or directories.

# Define source, target, and backup directories
REPO_DIR="$HOME/utono/cachyos-hyprland-settings"
SOURCE="$REPO_DIR/etc/skel/.config"
TARGET="$HOME/.config"
BACKUP_DIR="$HOME/backups/.config"

# Ensure the repository directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Repository directory $REPO_DIR does not exist."
    exit 1
fi

# Ensure target and backup directories exist
mkdir -p "$TARGET"
mkdir -p "$BACKUP_DIR"

# Link each item in the source directory to the target directory
for item in "$SOURCE"/*; do
    base=$(basename "$item")
    target_item="$TARGET/$base"
    backup_item="$BACKUP_DIR/${base}_$(date +%Y%m%d%H%M%S)"

    # Backup existing files or symlinks before replacing them
    if [ -e "$target_item" ] || [ -L "$target_item" ]; then
        mv "$target_item" "$backup_item"
        echo "Backed up: $target_item -> $backup_item"
    fi

    # Create symbolic link to the source file/directory
    ln -s "$item" "$target_item"
    echo "Linked: $target_item -> $item"
done

echo "Hyprland configuration links updated in $TARGET. Backups stored in $BACKUP_DIR."
