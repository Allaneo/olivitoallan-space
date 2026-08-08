#!/usr/bin/env bash
set -euo pipefail

# Build and deploy the site to production (no git writes)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HUGO_DIR="$ROOT_DIR/sites/hugo"

echo "🚀 Deploying website to production"

# Ensure clean and up-to-date (reuse the publish validations)
pushd "$ROOT_DIR" >/dev/null
./tools/scripts/internal-publish.sh
popd >/dev/null


