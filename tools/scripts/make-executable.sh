#!/usr/bin/env bash
set -euo pipefail

# make-executable.sh — Ensure all scripts are executable
#
# Usage:
#   scripts/make-executable.sh
#
# This script makes all shell scripts in the scripts/ directory executable
# and provides a summary of what was updated.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helpers ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [EXEC] $*"; }

log "🔧 Making scripts executable..."

# Counter for changes
CHANGED=0
TOTAL=0

# Find all .sh files in tools/scripts and aws directories
while IFS= read -r -d '' script; do
  TOTAL=$((TOTAL + 1))
  BASENAME=$(basename "$script")
  
  # Check if already executable
  if [[ -x "$script" ]]; then
    log "✅ $BASENAME (already executable)"
  else
    log "🔧 $BASENAME (making executable)"
    chmod +x "$script"
    CHANGED=$((CHANGED + 1))
  fi
done < <(find "$SCRIPT_DIR" "$SCRIPT_DIR/../../aws" -maxdepth 1 -name "*.sh" -type f -print0)

# Summary
echo ""
log "📊 Summary:"
log "   Total scripts: $TOTAL"
log "   Made executable: $CHANGED"
log "   Already executable: $((TOTAL - CHANGED))"

if [[ $CHANGED -gt 0 ]]; then
  log "✅ $CHANGED script(s) updated!"
else
  log "✅ All scripts were already executable!"
fi

echo ""
log "📋 Current script permissions:"
ls -la "$SCRIPT_DIR"/*.sh 2>/dev/null | while read -r line; do
  echo "   $line"
done
ls -la "$SCRIPT_DIR/../../aws"/*.sh 2>/dev/null | while read -r line; do
  echo "   $line"
done

echo ""
log "🎉 Done! All scripts are now executable."
