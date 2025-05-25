#!/usr/bin/env bash

# Clone Git repositories listed in a *.urls file into
# ~/Documents/repos/<default-dir>/<username>/<repository>/
# The default dir is derived from the basename of the *.urls parameter.

set -e  # Exit on error

DEFAULT_BASE="$HOME/Documents/repos"

# Ensure exactly one argument is passed
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <url-list-file>"
    exit 1
fi

url_list_file="$1"

if [[ ! -f "$url_list_file" ]]; then
    echo "URL list file $url_list_file not found"
    exit 1
fi

# Get default subdirectory from basename (strip .urls extension)
default_dir="$(basename "${url_list_file%.urls}")"

# Prompt user for subdirectory under ~/Documents/repos
read -rp "Enter subdirectory under ~/Documents/repos (default: $default_dir): " SUBDIR
SUBDIR="${SUBDIR:-$default_dir}"

REPOS_BASE="${DEFAULT_BASE}/${SUBDIR}"

# Function to extract GitHub username and repository name
extract_user_and_repo() {
    local repo_url="$1"
    if [[ "$repo_url" =~ git@github.com:([^/]+)/([^/]+)\.git ]] || [[ "$repo_url" =~ https://github.com/([^/]+)/([^/]+)\.git ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        echo ""
    fi
}

# Function to clone a repository
clone_repo() {
    local repo_url="$1"
    local user_and_repo
    user_and_repo=$(extract_user_and_repo "$repo_url")

    if [[ -z "$user_and_repo" ]]; then
        echo "Invalid repository URL: $repo_url"
        return 1
    fi

    local username repo_name
    read -r username repo_name <<< "$user_and_repo"

    local target_dir="${REPOS_BASE}/${username}/${repo_name}"

    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        git clone --depth 1 "$repo_url" "$target_dir" >/dev/null \
            || { echo "Failed to clone $repo_url"; exit 1; }
    else
        echo "Repository already exists at $target_dir"
    fi
    echo
}

# Process all repository URLs in the list
clone_all_repos() {
    while IFS= read -r repo_url || [[ -n "$repo_url" ]]; do
        [[ -z "$repo_url" || "$repo_url" =~ ^# ]] && continue
        echo "Cloning repository: $repo_url"
        clone_repo "$repo_url"
    done < "$url_list_file"
}

# Start cloning process
clone_all_repos
