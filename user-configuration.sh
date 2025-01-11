#!/usr/bin/env bash

# This script sets up a new user environment.
#
# The user is added to the groups: keyd and input.
# The user's essential directories are created and ownership
# and attributes (chattr -V +C) are assigned.
#
# It performs the following tasks:
# 1. Creates a predefined list of user directories under the home directory of 
#    the specified username.
# 2. Sets the "no copy-on-write" attribute for these directories using `chattr`.
# 3. Sets the ownership of the directories to the specified user.
# 4. Adds the user to predefined groups, which must exist on the system.
#
# Usage:
#   ./script_name.sh <username>
#     <username> - The username for which the setup will be performed.
#
# Example:
#   ./script_name.sh john
#
# Requirements:
# - The script must be run with sufficient privileges to create directories,
#   modify attributes, change ownership, and add users to groups.
# - The groups specified in the script must already exist.
#
# Exit Codes:
# - 1: Indicates a failure in creating directories, setting attributes, 
#      changing ownership, or adding the user to a group.
#
# Notes:
# - The script uses `set -euo pipefail` to ensure strict error handling.

set -euo pipefail

# Function to create user directories
create_user_directories() {
    local username="$1"

    # List of directories to create
    local DIRECTORIES=(
        "archlive"
        "hard_disk_images"
        "Music"
        "Videos"
        "rips"
    )

    # Create and configure necessary directories
    for dir in "${DIRECTORIES[@]}"; do
        local path="/home/$username/$dir"
        if ! mkdir -p "$path"; then
            echo "Failed to create directory: $path" >&2
            exit 1
        fi
        if ! chattr -V +C "$path"; then
            echo "Failed to set attributes on directory: $path" >&2
            exit 1
        fi
        if ! chown -R "$username:$username" "$path"; then
            echo "Failed to set ownership for: $path" >&2
            exit 1
        fi
    done
    echo "All user directories created successfully for $username."
}

# Function to add user to a group
add_user_to_group() {
    local username="$1"
    local group="$2"

    if [ -z "$group" ]; then
        echo "Skipping empty or invalid group." >&2
        return
    fi
    echo "Processing group: $group" # Debug statement
    if getent group "$group" > /dev/null 2>&1; then
        if sudo gpasswd -a "$username" "$group"; then
            echo "Successfully added $username to the $group group."
        else
            echo "Failed to add $username to the $group group." >&2
            exit 1
        fi
    else
        echo "The '$group' group does not exist. Please create it first." >&2
        exit 1
    fi
}

# Ensure the script is called with a valid argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <username>" >&2
    exit 1
fi

username="$1"

create_user_directories "$username"

# Add the user to predefined groups
add_user_to_group "$username" "keyd"
add_user_to_group "$username" "input"
