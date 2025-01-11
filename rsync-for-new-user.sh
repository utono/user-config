#!/usr/bin/env bash

# This script synchronizes and reorganizes files for the specified user.

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
  ["SOURCE_UTONO"]="/root/utono/"
  ["DESTINATION_UTONO"]="/home/$USERNAME/utono"
  ["SOURCE_MPV"]="/home/$USERNAME/utono/mpv-utono/"
  ["DESTINATION_MPV"]="/home/$USERNAME/.config/mpv/"
  ["SOURCE_NVIM"]="/home/$USERNAME/utono/kickstart-modular.nvim/"
  ["DESTINATION_NVIM"]="/home/$USERNAME/.config/nvim/"
  ["TTY_SOURCE"]="/home/$USERNAME/utono/tty-dotfiles/"
  ["TTY_DESTINATION"]="/home/$USERNAME/tty-dotfiles/"
  ["CACHY_DOTS_SOURCE"]="/home/$USERNAME/utono/cachy-dots/"
  ["CACHY_DOTS_DESTINATION"]="/home/$USERNAME/cachy-dots/"
  ["SOURCE_WEZTERM"]="/home/$USERNAME/utono/wezterm-config/"
  ["DESTINATION_WEZTERM"]="/home/$USERNAME/.config/wezterm-config/"
)

# Ensure ~/.config exists and is owned by the user
mkdir -p "/home/$USERNAME/.config"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config"

# Ensure destination directory exists
mkdir -p "${DIRS["DESTINATION_UTONO"]}"
chown -R "$USERNAME:$USERNAME" "${DIRS["DESTINATION_UTONO"]}"

# Synchronize /root/utono/ to /home/<username>/utono/
if ! rsync -al --progress "${DIRS["SOURCE_UTONO"]}" "${DIRS["DESTINATION_UTONO"]}"; then
  echo "Error: Failed to sync the contents of 'utono' directory."
  exit 1
fi

# Move ~/utono/cachy-dots to ~/cachy-dots
if [[ -d "${DIRS["CACHY_DOTS_SOURCE"]}" ]]; then
  echo "Moving '${DIRS["CACHY_DOTS_SOURCE"]}' to '${DIRS["CACHY_DOTS_DESTINATION"]}'."
  if ! mv "${DIRS["CACHY_DOTS_SOURCE"]}" "${DIRS["CACHY_DOTS_DESTINATION"]}"; then
    echo "Error: Failed to move '${DIRS["CACHY_DOTS_SOURCE"]}' to '${DIRS["CACHY_DOTS_DESTINATION"]}'."
    exit 1
  fi
else
  echo "Directory '${DIRS["CACHY_DOTS_SOURCE"]}' does not exist. Skipping move."
fi

# Move ~/utono/tty-dotfiles to ~/tty-dotfiles
if [[ -d "${DIRS["TTY_SOURCE"]}" ]]; then
  echo "Moving '${DIRS["TTY_SOURCE"]}' to '${DIRS["TTY_DESTINATION"]}'."
  if ! mv "${DIRS["TTY_SOURCE"]}" "${DIRS["TTY_DESTINATION"]}"; then
    echo "Error: Failed to move '${DIRS["TTY_SOURCE"]}' to '${DIRS["TTY_DESTINATION"]}'."
    exit 1
  fi
else
  echo "Directory '${DIRS["TTY_SOURCE"]}' does not exist. Skipping move."
fi

# Synchronize MPV, NVIM, and WEZTERM directories
if ! rsync -al --progress "${DIRS["SOURCE_MPV"]}" "${DIRS["DESTINATION_MPV"]}"; then
  echo "Error: Failed to sync 'mpv' directory."
  exit 1
fi

if ! rsync -al --progress "${DIRS["SOURCE_NVIM"]}" "${DIRS["DESTINATION_NVIM"]}"; then
  echo "Error: Failed to sync 'nvim' directory."
  exit 1
fi

if ! rsync -al --progress "${DIRS["SOURCE_WEZTERM"]}" "${DIRS["DESTINATION_WEZTERM"]}"; then
  echo "Error: Failed to sync 'wezterm' directory."
  exit 1
fi

# Change ownership of all synchronized files and directories
if ! chown -R "$USERNAME:$USERNAME" "${DIRS["DESTINATION_UTONO"]}" "${DIRS["TTY_DESTINATION"]}" "${DIRS["DESTINATION_MPV"]}" "${DIRS["DESTINATION_NVIM"]}" "${DIRS["DESTINATION_WEZTERM"]}"; then
  echo "Error: Failed to change ownership of directories."
  exit 1
fi

# Success message
echo "Synchronization complete. Ownership of 'utono', 'tty-dotfiles', 'mpv', 'nvim', and 'wezterm-config' changed to $USERNAME."
