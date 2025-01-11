#!/usr/bin/env bash
# intsall_package.sh

# Description:
# This script installs packages listed in one or more CSV files. Each file should
# contain package names, with optional comments and empty lines. The script will
# process each file, validate package names, and attempt to install the packages
# using `pacman` and `paru` (if available for AUR packages).
#
# Usage:
#   ./install_packages.sh <file1.csv> [file2.csv ...]
#
# Arguments:
#   <file1.csv>, [file2.csv ...] - One or more CSV files containing package names.
#
# Requirements:
#   - sudo privileges to run package management commands.
#   - `pacman` (required) and optionally `paru` for AUR packages.

# Check if at least one file is provided
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <file1.csv> [file2.csv ...]"
  echo "Error: No input files provided."
  exit 1
fi

# Ensure sudo privileges at the start
echo "Please enter your sudo password for unattended installation:"
if ! sudo -v; then
  echo "Error: Failed to authenticate with sudo."
  exit 1
fi

# Refresh sudo timestamp in the background
(while true; do sudo -v; sleep 60; done) &
SUDO_REFRESH_PID=$!

# Function to extract and install packages
install_packages() {
  local file="$1"
  echo "Processing file: $file"

  # Check if file exists
  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' does not exist."
    return 1
  fi

  # Parse valid package names from the file
  local packages=()
  while IFS= read -r line; do
    # Ignore empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Extract the package name (first field before a comma)
    pkg_name=$(echo "$line" | cut -d ',' -f1 | xargs)

    # Validate package name
    if [[ -n "$pkg_name" && "$pkg_name" =~ ^[a-zA-Z0-9.+_-]+$ ]]; then
      packages+=("$pkg_name")
    else
      echo "Skipping invalid entry: $line"
    fi
  done < "$file"

  # Install packages
  if [[ ${#packages[@]} -gt 0 ]]; then
    echo "Installing packages: ${packages[*]}"
    # Attempt to install via pacman first
    sudo pacman -Syu --needed --noconfirm "${packages[@]}" || {
      echo "Some packages may not be in the official repos. Attempting paru."
      paru -S --needed --noconfirm "${packages[@]}"
    }
  else
    echo "No valid packages found in $file."
  fi
}

# Process each file
for csv_file in "$@"; do
  install_packages "$csv_file"
done

# Kill the sudo refresh process
kill "$SUDO_REFRESH_PID" 2>/dev/null

echo "All done!"
