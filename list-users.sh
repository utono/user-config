#!/bin/bash

# Function to list and sort all users using awk and sort
list_and_sort_users() {
    awk -F':' '{ print $1 }' /etc/passwd | sort
}

# Execute the function
list_and_sort_users
