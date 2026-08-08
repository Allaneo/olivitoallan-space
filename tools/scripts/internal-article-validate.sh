#!/usr/bin/env bash
set -euo pipefail

# Validate published content before deployment.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SITE="$ROOT/sites/hugo"
failures=()

front_matter_value() {
  local key="$1"
  local file="$2"
  awk -v key="$key" '$0 ~ "^" key ":[[:space:]]*" { sub("^" key ":[[:space:]]*", ""); print; exit }' "$file"
}

validate_file() {
  local file="$1"
  local rel="${file#"$SITE/"}"
  local draft
  draft="$(front_matter_value "draft" "$file" | tr '[:upper:]' '[:lower:]')"

  [[ "$draft" == "true" ]] && return 0

  [[ -z "$(front_matter_value "title" "$file")" ]] &&
    failures+=("$rel: missing title")

  if [[ "$rel" == content/posts/* ]]; then
    [[ -z "$(front_matter_value "date" "$file")" ]] &&
      failures+=("$rel: missing date")
    [[ -z "$(front_matter_value "description" "$file")" ]] &&
      failures+=("$rel: missing description")
  fi

  if grep -Eqi '\bTODO\b' "$file"; then
    failures+=("$rel: contains TODO markers")
  fi
}

while IFS= read -r -d '' file; do
  validate_file "$file"
done < <(find "$SITE/content" -type f -name 'index.md' -print0)

if (( ${#failures[@]} > 0 )); then
  echo "Article validation failed:" >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi

echo "Articles validated."

