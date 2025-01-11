#!/bin/sh

# Function to add user and change password
add_user() {
    local username=$1
    # Check if 'wheel' group exists
    if ! getent group wheel >/dev/null; then
        groupadd wheel
    fi
    useradd -m -g wheel -s /bin/zsh "$username"
    # sudo passwd $username
    echo "$username:password" | sudo chpasswd
}

# Function to confirm user creation and list groups
confirm_user_creation() {
    local username=$1
    if id "$username" >/dev/null 2>&1; then
        echo "User '$username' has been created successfully."
        echo "Groups for user '$username':"
        id -Gn "$username"
    else
        echo "Failed to create user '$username'." 1>&2
        exit 1
    fi
}

# Main script
main() {
    if [ -z "$1" ]; then
        echo "Usage: $0 <username>"
        exit 1
    fi

    local username=$1
    add_user "$username"
    confirm_user_creation "$username"
}

main "$1"
