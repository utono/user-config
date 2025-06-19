#!/usr/bin/env bash

# Restore executable permissions in all Git repositories under a given directory
# Usage: restore-git-permissions.sh [--dry-run] [optional_root_directory]
# Defaults to: ~/utono
# Dry-run: shows what would change without applying it

set -euo pipefail

# Argument parsing
DRY_RUN=0
ROOT_DIR="$HOME/utono"

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        *)
            ROOT_DIR="$arg"
            ;;
    esac
done

if [ ! -d "$ROOT_DIR" ]; then
    echo "❌ Error: Directory not found: $ROOT_DIR"
    exit 1
fi

echo "📦 Scanning for Git repositories under: $ROOT_DIR"
[[ $DRY_RUN -eq 1 ]] && echo "(Dry run enabled — no changes will be made)"
echo

# Find all .git directories (top-level only)
find "$ROOT_DIR" -type d -name ".git" | while read -r gitdir; do
    repo_dir="$(dirname "$gitdir")"
    echo "🔧 Checking repository: $repo_dir"

    (
        cd "$repo_dir"

        before=$(git diff --summary)

        if [[ -z "$before" ]]; then
            echo "✓ No permission changes needed."
        else
            echo "$before"

            if [[ $DRY_RUN -eq 1 ]]; then
                echo "→ Would restore executable bits."
            else
                echo "→ Restoring executable bits..."
                git restore .
                after=$(git diff --summary)
                restored=$(comm -13 <(echo "$after" | sort) <(echo "$before" | sort))

                if [[ -n "$restored" ]]; then
                    echo "✔ Restored:"
                    echo "$restored"
                else
                    echo "✓ No changes made during restore."
                fi
            fi
        fi

        echo
    )
done

echo "✅ All repositories processed."
[[ $DRY_RUN -eq 1 ]] && echo "(Dry run complete — no changes were made)"
