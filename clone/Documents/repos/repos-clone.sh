#!/usr/bin/env bash

# This script clones repositories from a list of Git URLs provided in a single
# text file passed as an argument. The URLs can be in the format
# git@github.com: or https://github.com/.

set -e  # Exit on error

# Base directory for repositories
REPOS_BASE="$HOME/Documents/repos"

# Function to extract GitHub username and repository name
extract_user_and_repo() {
    local repo_url="$1"
    if [[ "$repo_url" =~ git@github.com:(.+)/(.+)\.git ]] || [[ "$repo_url" =~ https://github.com/(.+)/(.+)\.git ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        echo "" # Return empty string if URL is invalid
    fi
}

# Function to clone a repository
clone_repo() {
    local base_dir="$1"
    local repo_url="$2"

    # Extract GitHub username and repository name
    local user_and_repo
    user_and_repo=$(extract_user_and_repo "$repo_url")

    if [[ -z "$user_and_repo" ]]; then
        echo "Invalid repository URL: $repo_url"
        return 1
    fi

    local user="$(echo $user_and_repo | awk '{print $1}')"
    local repo="$(echo $user_and_repo | awk '{print $2}')"

    local target_dir="${base_dir}/${user}/${repo}"

    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
        git clone --depth 1 "$repo_url" "$target_dir" >/dev/null \
            || { echo "Failed to clone $repo_url"; exit 1; }
    else
        echo "Repository $repo already exists at $target_dir"
    fi
    echo
}

# Function to process all repository URLs
clone_all_repos() {
    local base_dir="$1"
    while IFS= read -r repo_url; do
        [[ -z "$repo_url" || "$repo_url" =~ ^# ]] && continue # Skip empty lines or comments
        echo "Cloning repository: $repo_url"
        clone_repo "$base_dir" "$repo_url"
    done < "$2"
}

# Ensure only one argument is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <url-list-file>"
    exit 1
fi

url_list_file="$1"

if [[ ! -f "$url_list_file" ]]; then
    echo "URL list file $url_list_file not found"
    exit 1
fi

# Determine the base name of the URL list file (remove extension and directory)
config_base_name="$(basename "$url_list_file" | sed 's/\..*//')"
base_dir="${REPOS_BASE}/${config_base_name}"

# Execute the cloning process
clone_all_repos "$base_dir" "$url_list_file"
