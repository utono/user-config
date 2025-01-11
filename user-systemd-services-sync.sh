#!/usr/bin/env bash

# User-Level Systemd Service Manager
# This script helps manage user-level systemd services by allowing you to:
# 1. Select a .service file from ~/tty-dotfiles/systemd/.config/systemd/user using `fzf`.
# 2. Create a symlink to the selected service file in ~/.config/systemd/user.
# 3. Reload systemd, enable the service, and start it.

set -uo pipefail

# Define paths
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SOURCE_DIR="$HOME/tty-dotfiles/systemd/.config/systemd/user"

# Ensure `fzf` is installed
if ! command -v fzf &> /dev/null; then
    echo -e "\033[31mError:\033[0m 'fzf' is required but not installed. Please install 'fzf' and try again."
    exit 1
fi

# Function: Create a symlink for the selected service file
create_symlink() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        echo -e "\033[33mSymlink already exists:\033[0m $dest"
        echo -e "\033[34mCommand:\033[0m ls -l $dest"
        ls -l "$dest"
        return 0
    fi

    if [ -f "$src" ]; then
        echo -e "\033[34mCreating symlink:\033[0m ln -sf $src $dest"
        mkdir -p "$(dirname "$dest")"  # Ensure destination directory exists
        ln -sf "$src" "$dest" || {
            echo -e "\033[31mError:\033[0m Failed to create symlink."
            exit 1
        }
        echo -e "\033[32mSymlink created successfully:\033[0m $dest -> $src"
    else
        echo -e "\033[31mError:\033[0m Source file does not exist: $src"
        exit 1
    fi
}

# Function: Reload systemd and manage the service
manage_service() {
    local service_name="$1"

    echo -e "\033[34mReloading user systemd daemon...\033[0m: systemctl --user daemon-reload"
    systemctl --user daemon-reload || {
        echo -e "\033[31mError:\033[0m Failed to reload user systemd daemon."
        exit 1
    }

    echo -e "\033[34mEnabling and starting the user-level service:\033[0m systemctl --user enable --now $service_name"
    systemctl --user enable --now "$service_name" || {
        echo -e "\033[31mError:\033[0m Failed to enable/start the service."
        echo "Possible reasons:"
        echo "- The service might have a misconfiguration."
        echo "- The service's executable or dependencies might be missing."
        echo "Check the service logs for more details:"
        echo "  journalctl --user -u $service_name"
        exit 1
    }

    echo -e "\033[32mUser-level service '$service_name' enabled and started successfully.\033[0m"
}

# Main function: Select, create symlink, and manage service
main() {
    echo -e "\033[34mSearching for .service files...\033[0m"
    local selected_file
    selected_file=$(find "$SOURCE_DIR" -name "*.service" | fzf --prompt="Select a .service file to sync: ") || {
        echo -e "\033[33mNo .service file selected. Exiting.\033[0m"
        exit 0
    }

    local service_name
    service_name=$(basename "$selected_file")
    local dest_service="$USER_SYSTEMD_DIR/$service_name"

    create_symlink "$selected_file" "$dest_service"
    manage_service "$service_name"

    echo -e "\033[34mTo check the service status:\033[0m systemctl --user status $service_name"
}

main "$@"
