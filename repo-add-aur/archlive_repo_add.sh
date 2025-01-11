#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define directories for cloned AUR packages and custom repository
CLONEDIR="$HOME/utono/archlive_aur_packages"
CUSTOM_REPOS="$HOME/utono/archlive_aur_repository"

# Request sudo access upfront and keep it alive for the duration of the script
sudo -v

# Function to keep sudo session alive
keep_sudo_alive() {
  while true; do
    sudo -n true
    sleep 60
  done
}

# Start the keep-alive process in the background and capture its PID
keep_sudo_alive &
KEEP_SUDO_ALIVE_PID=$!

# Function to clean up background process on exit
cleanup() {
  kill "$KEEP_SUDO_ALIVE_PID"
}
trap cleanup EXIT

clone_and_build_package() {
  local PKG_NAME=$1
  echo "Processing package: $PKG_NAME"

  mkdir -p "$CLONEDIR"
  cd "$CLONEDIR" || exit

  # Remove old package directory if it exists
  [ -d "$PKG_NAME" ] && rm -rf "$PKG_NAME"

  # Clone the package
  git clone "https://aur.archlinux.org/$PKG_NAME.git"
  cd "$PKG_NAME" || exit

  # Build and install the package with logging
  BUILDDIR="$PWD" makepkg --syncdeps --install --needed --noconfirm --cleanbuild | tee "$PKG_NAME-build.log"

  if [ $? -ne 0 ]; then
    echo "Error building $PKG_NAME. Check $PKG_NAME-build.log for details."
    exit 1
  fi

  # Remove old package from the repository if it exists
  [ -f "$CUSTOM_REPOS/$PKG_NAME"*.pkg.tar.zst ] && rm -f "$CUSTOM_REPOS/$PKG_NAME"*.pkg.tar.zst

  # Copy the new package to the custom repository
  cp -v "$PKG_NAME"*.pkg.tar.zst "$CUSTOM_REPOS"
}

# Prepare directories
echo "Preparing directories..."
sudo rm -rf "$CLONEDIR"
mkdir -p "$CLONEDIR" "$CUSTOM_REPOS"

# List of packages to clone and build
packages=(
  "neovim-nightly-bin"
  # "paru"
  # "wezterm-git"
  # Add more packages here if needed
)

# Clone and build each package
for pkg in "${packages[@]}"; do
  clone_and_build_package "$pkg"
done

# Update the custom repository
echo "Updating custom repository..."
repo-add "$CUSTOM_REPOS/archlive_aur_repository.db.tar.gz" "$CUSTOM_REPOS"/*.pkg.tar.zst

echo "All packages processed successfully!"
