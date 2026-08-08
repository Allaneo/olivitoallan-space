#!/usr/bin/env bash
set -euo pipefail

# internal-publish.sh — Production deployment; intended to be called by deploy-production.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT_DIR/tools/scripts/publish.sh" "$@"


