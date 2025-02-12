#!/usr/bin/env bash

# Usage: ./utono-update-repos.sh ~/utono
# Updates all repositories in the given directory by running `git pull`.

if [ $# -lt 1 ]; then
    echo "❌ Error: Missing target directory. Usage: $0 <target_directory>"
    exit 1
fi

targetDir="$1"

if [ ! -d "$targetDir" ]; then
    echo "❌ Error: Target directory does not exist."
    exit 1
fi

cd "$targetDir" || { echo "❌ Error: Failed to enter $targetDir"; exit 1; }

for dir in */; do
    [ -d "$dir/.git" ] || continue
    echo "🔄 Updating $dir..."
    cd "$dir" || continue
    git pull origin main || git pull origin master
    cd ..
done

echo "✅ Update complete."
exit 0
