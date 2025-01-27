#!/usr/bin/env bash

# This script synchronizes the contents of source directories into destination directories
# for the specified user and ensures proper ownership. Hidden files and directories are included.

# Usage: sudo ./script_name.sh <username>
# Arguments:
#   <username> - The username of the user who will own the synchronized files.

# Check if a username argument is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# Assign the provided username to a variable
USERNAME="$1"

# Array of source and destination directories
declare -A DIRS=(
  ["SOURCE_NVIM"]="/home/$USERNAME/utono/kickstart-modular.nvim"
  ["DESTINATION_NVIM"]="/home/$USERNAME/.config/nvim"
  ["SOURCE_MPV"]="/home/$USERNAME/utono/mpv-utono"
  ["DESTINATION_MPV"]="/home/$USERNAME/.config/mpv"
  ["TTY_SOURCE"]="/home/$USERNAME/utono/tty-dotfiles"
  ["TTY_DESTINATION"]="/home/$USERNAME/tty-dotfiles"
)

# Ensure ~/.config exists and is owned by the user
mkdir -p "/home/$USERNAME/.config"
chattr -V +C ~/.config

# Function to synchronize contents of source directory to destination directory
sync_contents() {
  local source="$1"
  local destination="$2"

  if [[ -d "$source" ]]; then
    echo "Synchronizing contents of '$source/' to '$destination/'."
    mkdir -p "$destination" # Ensure destination directory exists
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

# Change ownership of ~/utono and its contents to the specified user
if [[ -d "/home/$USERNAME/utono" ]]; then
  echo "Changing ownership of '/home/$USERNAME/utono' and its contents to $USERNAME."
  if ! chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/utono"; then
    echo "Error: Failed to change ownership of '/home/$USERNAME/utono'."
    exit 1
  fi
else
  echo "Directory '/home/$USERNAME/utono' does not exist. Skipping ownership change."
fi

# Change ownership of all synchronized files and directories
if ! chown -R "$USERNAME:$USERNAME" \
  "${DIRS["DESTINATION_NVIM"]}" \
  "${DIRS["DESTINATION_MPV"]}" \
  "${DIRS["TTY_DESTINATION"]}"; then
  echo "Error: Failed to change ownership of destination directories."
  exit 1
fi

# Success message
echo "Synchronization complete. Ownership of 'utono', 'tty-dotfiles', 'mpv', and 'nvim' contents changed to $USERNAME."
