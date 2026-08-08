#!/usr/bin/env bash
set -euo pipefail

# ci-guard.sh — Verify environment correctness in build artifacts
# Usage:
#   HUGO_ENV=production tools/scripts/ci-guard.sh sites/hugo/public
#   HUGO_ENV=staging    tools/scripts/ci-guard.sh sites/hugo/public-staging

ARTIFACT_DIR="${1:-}"
if [[ -z "$ARTIFACT_DIR" || ! -d "$ARTIFACT_DIR" ]]; then
  echo "Usage: HUGO_ENV=<production|staging> $0 <artifact-dir>" >&2
  exit 1
fi

ENV="${HUGO_ENV:-}"
if [[ "$ENV" != "production" && "$ENV" != "staging" ]]; then
  echo "HUGO_ENV must be production or staging" >&2
  exit 1
fi

# Check baseURL in generated index.html
INDEX="$ARTIFACT_DIR/index.html"
if [[ ! -f "$INDEX" ]]; then
  echo "Index file not found: $INDEX" >&2
  exit 1
fi

if [[ "$ENV" == "production" ]]; then
  grep -q 'content="https://.*/"' "$INDEX" || echo "WARN: canonical/og url not found in index" >&2
  # Production must include sitemap
  if [[ ! -f "$ARTIFACT_DIR/sitemap.xml" ]]; then
    echo "ERROR: sitemap.xml missing in production artifact" >&2
    exit 1
  fi
else
  # Staging index should include noindex meta
  if ! grep -qi '<meta name="robots" content="noindex' "$INDEX"; then
    echo "ERROR: meta robots noindex not found in staging index" >&2
    exit 1
  fi
fi

# GTM guard: non-production must NOT include GTM snippets
if [[ "$ENV" != "production" ]]; then
  if grep -Rqi 'www.googletagmanager.com' "$ARTIFACT_DIR"; then
    echo "ERROR: GTM detected in non-production artifact" >&2
    exit 1
  fi
fi

## Duplicate content guard: detect both section _index.md and page index.md for same slug
if command -v fd >/dev/null 2>&1; then
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  while IFS= read -r slug; do
    if [ -f "$ROOT_DIR/sites/hugo/content/page/$slug/index.md" ]; then
      echo "ERROR: Duplicate content detected for '$slug': both content/$slug/_index.md and content/page/$slug/index.md exist" >&2
      exit 1
    fi
  done < <(fd -a -t f '^_index\.md$' "$ROOT_DIR/sites/hugo/content" | sed -E 's#.*/content/([^/]+)/_index.md#\1#' | sort -u)
fi

echo "✅ CI guard checks passed for $ENV"


