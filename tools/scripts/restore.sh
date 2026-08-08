#!/bin/bash

# restore.sh — Git-based restore using release tags
#
# Usage:
#   tools/scripts/restore.sh --list              # List available releases
#   tools/scripts/restore.sh release-20250825-1923  # Restore to specific release
#   tools/scripts/restore.sh --latest            # Restore to latest release
#
# What it does:
#   - Uses git tags to restore to previous production releases
#   - Much simpler than the old backup system
#   - Works with any git repository

set -euo pipefail

# --- Helpers ---
have() { command -v "$1" >/dev/null 2>&1; }
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [RESTORE] $*"; }
success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [RESTORE] ✅ $*"; }
warning() { echo "$(date '+%Y-%m-%d %H:%M:%S') [RESTORE] ⚠️  $*"; }
error() { echo "$(date '+%Y-%m-%d %H:%M:%S') [RESTORE] ❌ $*"; exit 1; }

validate_deps() {
  log "🔍 Validating dependencies..."
  
  have git || error "Git not found"
  have hugo || error "Hugo not found. Install: brew install hugo"
  
  if [[ ! -d ".git" ]]; then
    error "Not in a git repository. Make sure you're in the project root."
  fi
  
  success "Dependencies validated"
}

list_releases() {
  log "📋 Available production releases:"
  echo ""
  
  # Get release tags sorted by date (newest first)
  local tags
  tags=$(git tag -l "release-*" --sort=-creatordate)
  
  if [[ -z "$tags" ]]; then
    echo "No release tags found. Deploy to production first with:"
    echo "  tools/scripts/deploy-production.sh"
    echo ""
    return
  fi
  
  local count=0
  while IFS= read -r tag; do
    if [[ -n "$tag" ]]; then
      count=$((count + 1))
      local date_part=$(echo "$tag" | sed 's/release-//')
      local formatted_date=$(echo "$date_part" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)-\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
      
      echo "  $count. $tag ($formatted_date)"
      
      # Show tag message (first line only)
      local message=$(git tag -l --format='%(contents:lines=1)' "$tag")
      echo "     $message"
      echo ""
    fi
  done <<< "$tags"
  
  if [[ $count -eq 0 ]]; then
    echo "No release tags found."
  else
    echo "To restore: tools/scripts/restore.sh <tag-name>"
    echo "Example:    tools/scripts/restore.sh $(echo "$tags" | head -1)"
  fi
  echo ""
}

get_latest_release() {
  git tag -l "release-*" --sort=-creatordate | head -1
}

restore_to_release() {
  local tag_name="$1"
  
  log "🔄 Restoring to release: $tag_name"
  
  # Verify tag exists
  if ! git tag -l | grep -q "^$tag_name$"; then
    error "Release tag '$tag_name' not found. Use --list to see available releases."
  fi
  
  # Show what we're restoring to
  echo ""
  echo "📋 Release Information:"
  git tag -l --format='%(contents)' "$tag_name"
  echo ""
  
  # Confirm with user
  read -p "Continue with restore to $tag_name? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Restore cancelled by user"
    exit 0
  fi
  
  # Check for uncommitted changes
  if ! git diff --quiet || ! git diff --staged --quiet; then
    warning "You have uncommitted changes. They will be lost!"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "Restore cancelled. Commit your changes first."
      exit 0
    fi
  fi
  
  # Create a backup branch of current state
  local backup_branch="backup-before-restore-$(date +%Y%m%d-%H%M%S)"
  git checkout -b "$backup_branch"
  git checkout main
  success "Created backup branch: $backup_branch"
  
  # Reset to the release tag
  git reset --hard "$tag_name"
  
  success "Restored to release: $tag_name"
  
  # Redeploy to make the restore live
  echo ""
  log "🚀 Redeploying restored version..."
  if ./tools/scripts/deploy-production.sh; then
    success "🎉 Restore complete and deployed!"
    echo ""
    echo "📝 Your previous state was backed up in branch: $backup_branch"
    echo "🔄 To undo this restore: git checkout $backup_branch && git checkout main && git reset --hard $backup_branch"
  else
    error "Deployment failed. Check the logs above."
  fi
}

show_help() {
  echo "Git-based Restore Script"
  echo ""
  echo "Usage:"
  echo "  tools/scripts/restore.sh --list              List available releases"
  echo "  tools/scripts/restore.sh --latest            Restore to latest release"
  echo "  tools/scripts/restore.sh <tag-name>          Restore to specific release"
  echo "  tools/scripts/restore.sh --help              Show this help"
  echo ""
  echo "Examples:"
  echo "  tools/scripts/restore.sh --list"
  echo "  tools/scripts/restore.sh release-20250825-1923"
  echo "  tools/scripts/restore.sh --latest"
  echo ""
}

main() {
  local action="${1:-}"
  
  case "$action" in
    "--list")
      validate_deps
      list_releases
      ;;
    "--latest")
      validate_deps
      local latest=$(get_latest_release)
      if [[ -z "$latest" ]]; then
        error "No releases found. Deploy to production first."
      fi
      restore_to_release "$latest"
      ;;
    "--help"|"-h"|"help")
      show_help
      ;;
    "")
      error "Please specify an action. Use --help for usage information."
      ;;
    *)
      validate_deps
      restore_to_release "$action"
      ;;
  esac
}

# Run main function
main "$@"
