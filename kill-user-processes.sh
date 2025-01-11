#!/bin/bash

# Function to prompt for confirmation
confirm() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Check if the username is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME=$1

# Confirm the action
if confirm "Are you sure you want to kill all processes for user '$USERNAME'?"; then
    # Attempt to kill all processes owned by the user
    if pkill -u $USERNAME; then
        echo "Initial kill attempt for user '$USERNAME' processes completed."
    else
        echo "Initial attempt to kill processes for user '$USERNAME' failed or no processes found." 1>&2
    fi

    # Wait a moment to ensure processes have been terminated
    sleep 2

    # Double-check if any processes are still running and force kill them
    PIDS=$(pgrep -u $USERNAME)
    if [[ -n "$PIDS" ]]; then
        echo "Force killing remaining processes for user '$USERNAME'."
        kill -9 $PIDS
    fi

    # Ensure no processes are left
    if ! pgrep -u $USERNAME > /dev/null; then
        echo "All processes for user '$USERNAME' have been terminated."
    else
        echo "Failed to terminate all processes for user '$USERNAME'." 1>&2
        exit 1
    fi
else
    echo "Action cancelled."
fi
