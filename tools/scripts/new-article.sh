#!/usr/bin/env bash
set -euo pipefail

# new-article.sh — Preferred helper to create a new article
# Delegates to new-post.sh but standardizes terminology

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TITLE="${1:-}"
if [[ -z "$TITLE" ]]; then
  echo "Usage: tools/scripts/new-article.sh \"Article Title\""
  exit 1
fi

"$SCRIPT_DIR/new-post.sh" "$TITLE"

