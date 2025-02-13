#!/usr/bin/env bash

# Usage: ./sync-delete-repos-for-new-user.sh
# This script synchronizes source directories to destination directories.
# If the destination exists, the source is deleted. Otherwise, it syncs before deletion.

# Get the username of the current user
USERNAME=$(whoami)

# Define source and destination directories
declare -A DIRS=(
  ["SOURCE_NVIM"]="$HOME/utono/kickstart-modular.nvim"
  ["DESTINATION_NVIM"]="$HOME/.config/nvim"
  ["SOURCE_MPV"]="$HOME/utono/mpv-utono"
  ["DESTINATION_MPV"]="$HOME/.config/mpv"
  ["SOURCE_TTY"]="$HOME/utono/tty-dotfiles"
  ["DESTINATION_TTY"]="$HOME/tty-dotfiles"
)

# Ensure ~/.config exists and is marked with chattr -V +C
mkdir -p "$HOME/.config"
chattr -V +C "$HOME/.config"

# Function to delete the source directory if the destination exists
delete_source_if_destination_exists() {
  local source="$1"
  local destination="$2"

  if [[ -d "$destination" && -d "$source" ]]; then
    echo "🚀 Destination '$destination' already exists. Deleting source '$source'."
    rm -rf "$source"
  fi
}

# Function to synchronize and then delete the source directory
sync_and_delete_source() {
  local source="$1"
  local destination="$2"

  if [[ -d "$source" ]]; then
    if [[ ! -d "$destination" ]]; then
      echo "📂 Destination '$destination' does not exist. Creating and syncing..."
      mkdir -p "$destination"
      chattr -V +C "$destination"
    fi

    echo "🔄 Synchronizing '$source' → '$destination'"
    if ! rsync -a --progress "$source/" "$destination/"; then
      echo "❌ Error: Failed to synchronize '$source' to '$destination'."
      exit 1
    fi

    echo "🗑️ Deleting source directory '$source'."
    rm -rf "$source"
  fi
}

# Process directories
for key in "${!DIRS[@]}"; do
  if [[ "$key" == SOURCE* ]]; then
    destination_key="${key/SOURCE/DESTINATION}"
    delete_source_if_destination_exists "${DIRS[$key]}" "${DIRS[$destination_key]}"
    sync_and_delete_source "${DIRS[$key]}" "${DIRS[$destination_key]}"
  fi
done

# Ensure ownership of ~/utono
if [[ -d "$HOME/utono" ]]; then
  echo "🔧 Ensuring ownership of '$HOME/utono' and its contents is set to $USERNAME."
  chown -R "$USERNAME:$USERNAME" "$HOME/utono"
fi

# Ensure ownership of all destination directories
for dest_key in "${!DIRS[@]}"; do
  if [[ "$dest_key" == DESTINATION* && -d "${DIRS[$dest_key]}" ]]; then
    chown -R "$USERNAME:$USERNAME" "${DIRS[$dest_key]}"
  fi
done

echo "✅ Synchronization complete. All created directories are marked with chattr -V +C."
