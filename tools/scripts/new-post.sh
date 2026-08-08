#!/usr/bin/env bash
set -euo pipefail

# Create a draft post from the default Hugo archetype.
# Usage: tools/scripts/new-post.sh "Post title" [section]

TITLE="${1:-}"
SECTION="${2:-posts}"

if [[ -z "$TITLE" ]]; then
  echo "Usage: tools/scripts/new-post.sh \"Post title\" [section]" >&2
  exit 1
fi

if [[ ! "$SECTION" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Section must contain only lowercase letters, numbers, and hyphens." >&2
  exit 1
fi

SLUG="$(
  printf '%s' "$TITLE" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
)"

if [[ -z "$SLUG" ]]; then
  echo "The title did not produce a valid URL slug." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SITE_DIR="$ROOT_DIR/sites/hugo"
RELATIVE_PATH="$SECTION/$SLUG/index.md"

(
  cd "$SITE_DIR"
  hugo new content "$RELATIVE_PATH"
)

echo "Created: sites/hugo/content/$RELATIVE_PATH"
echo "Next: edit the file and set draft: false when it is ready to publish."

