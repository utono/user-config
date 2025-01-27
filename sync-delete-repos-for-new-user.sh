#!/usr/bin/env bash

# This script synchronizes the contents of source directories into destination directories
# for the current user, ensures proper permissions, and marks directories with chattr -V +C.
# Hidden files and directories are included.

# Usage: ./script_name.sh

# Get the username of the current user
USERNAME=$(whoami)

# Array of source and destination directories
declare -A DIRS=(
  ["SOURCE_NVIM"]="$HOME/utono/kickstart-modular.nvim"
  ["DESTINATION_NVIM"]="$HOME/.config/nvim"
  ["SOURCE_MPV"]="$HOME/utono/mpv-utono"
  ["DESTINATION_MPV"]="$HOME/.config/mpv"
  ["TTY_SOURCE"]="$HOME/utono/tty-dotfiles"
  ["TTY_DESTINATION"]="$HOME/tty-dotfiles"
)

# Ensure ~/.config exists and is marked with chattr -V +C
mkdir -p "$HOME/.config"
chattr -V +C "$HOME/.config"

# Function to create a directory with chattr -V +C
create_directory() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo "Creating directory: $dir"
    mkdir -p "$dir"
    chattr -V +C "$dir"
  fi
}

# Function to synchronize contents of source directory to destination directory
sync_contents() {
  local source="$1"
  local destination="$2"

  if [[ -d "$source" ]]; then
    echo "Synchronizing contents of '$source/' to '$destination/'."
    create_directory "$destination"
    if ! rsync -a --progress "$source/" "$destination/"; then
      echo "Error: Failed to synchronize contents of '$source/' to '$destination/'."
      exit 1
    fi
    # Delete the source directory after successful sync
    echo "Deleting source directory '$source'."
    rm -rf "$source"
  else
    echo "Directory '$source' does not exist. Skipping synchronization."
  fi
}

# Synchronize NVIM contents
sync_contents "${DIRS["SOURCE_NVIM"]}" "${DIRS["DESTINATION_NVIM"]}"

# Synchronize MPV contents
sync_contents "${DIRS["SOURCE_MPV"]}" "${DIRS["DESTINATION_MPV"]}"

# Synchronize tty-dotfiles contents
sync_contents "${DIRS["TTY_SOURCE"]}" "${DIRS["TTY_DESTINATION"]}"

# Ensure ownership of ~/utono is consistent (no root required here)
if [[ -d "$HOME/utono" ]]; then
  echo "Ensuring ownership of '$HOME/utono' and its contents is set to $USERNAME."
  chown -R "$USERNAME:$USERNAME" "$HOME/utono"
else
  echo "Directory '$HOME/utono' does not exist. Skipping ownership change."
fi

# Ensure ownership of all synchronized files and directories
if ! chown -R "$USERNAME:$USERNAME" \
  "${DIRS["DESTINATION_NVIM"]}" \
  "${DIRS["DESTINATION_MPV"]}" \
  "${DIRS["TTY_DESTINATION"]}"; then
  echo "Error: Failed to change ownership of destination directories."
  exit 1
fi

# Success message
echo "Synchronization complete. All directories created are marked with chattr -V +C."
