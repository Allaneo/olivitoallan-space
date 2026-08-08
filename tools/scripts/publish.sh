#!/usr/bin/env bash
set -euo pipefail

# Get the directory of this script and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/load-env.sh"

# publish.sh — Production deployment only
#
# Usage:
#   scripts/publish.sh
#
# Requirements:
#   - Hugo installed (brew install hugo)
#   - sites/hugo/ directory with Hugo configuration
#   - AWS credentials configured (aws configure)
#   - Changes must be committed and pushed to git already
#   - DOMAIN_NAME and AWS settings configured in .env
#
# What it does:
#   1) Verifies the working tree is clean and synchronized
#   2) Builds sites/hugo/ for production
#   3) Syncs to production S3 and invalidates CloudFront

# No commit message needed - this is production-only deployment
AWS_REGION="${AWS_REGION:-us-east-1}"

# Stop AWS CLI from opening a pager
export AWS_PAGER=""
export AWS_CLI_PAGER=""

# --- Helpers ---
have() { command -v "$1" >/dev/null 2>&1; }
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [PUBLISH] $*"; }
success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [PUBLISH] ✅ $*"; }
warning() { echo "$(date '+%Y-%m-%d %H:%M:%S') [PUBLISH] ⚠️  $*"; }
error() { echo "$(date '+%Y-%m-%d %H:%M:%S') [PUBLISH] ❌ $*"; exit 1; }

validate_url() {
  local name="$1"
  local url="$2"
  
  if [[ -z "$url" ]]; then
    error "$name is required but not set"
  fi
  
  if [[ "$url" == "https://" || "$url" == "https://example.org" ]] || [[ "$url" == "https://example.com" ]]; then
    error "$name contains a default/example value: $url. Please set your actual domain."
  fi
  
  if [[ ! "$url" =~ ^https?:// ]]; then
    error "$name must start with http:// or https://"
  fi
}

validate_hugo_env() {
  log "🔍 Validating Hugo environment..."
  
  # Check for multi-file config structure (Blowfish)
  if [[ -f "sites/hugo/config/_default/hugo.toml" ]]; then
    CONFIG_FILE="sites/hugo/config/_default/hugo.toml"
    success "Found Blowfish multi-file configuration"
  elif [[ -f "sites/hugo/hugo.toml" ]]; then
    CONFIG_FILE="sites/hugo/hugo.toml"
    success "Found legacy single-file configuration"
  else
    error "Hugo configuration not found. Expected sites/hugo/config/_default/hugo.toml or sites/hugo/hugo.toml"
  fi
  
  # Check for required Hugo configuration
  if ! grep -q "baseURL" "$CONFIG_FILE"; then
    error "baseURL not found in $CONFIG_FILE"
  fi
  
  success "Hugo configuration validated: $CONFIG_FILE"
}

validate_staging_deployment() {
  log "🔍 Validating staging deployment..."

  # Require clean working tree
  if [[ -n "$(git status --porcelain)" ]]; then
    error "Working directory is not clean. Commit and push first."
  fi

  # Validate branch and remote sync
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$branch" == "HEAD" ]]; then
    error "Detached HEAD. Checkout a branch (e.g., main)."
  fi

  git fetch origin "$branch" --quiet || true
  local local_rev remote_rev base
  local_rev=$(git rev-parse "$branch")
  remote_rev=$(git rev-parse "origin/$branch" || echo "$local_rev")
  base=$(git merge-base "$branch" "origin/$branch" || echo "$local_rev")

  if [[ "$local_rev" != "$remote_rev" ]]; then
    if [[ "$local_rev" = "$base" ]]; then
      error "Branch is behind origin/$branch. Pull first."
    elif [[ "$remote_rev" = "$base" ]]; then
      error "Branch is ahead of origin/$branch. Push first."
    else
      error "Branch and origin/$branch have diverged. Reconcile first."
    fi
  fi

  success "Current commit validated in git history"
}



validate_deps() {
  log "🔍 Validating dependencies..."
  
  have hugo || error "Hugo not found. Install: brew install hugo"
  have git || error "Git not found"
  have aws || error "AWS CLI not found"
  
  BLOG_URL="https://${DOMAIN_NAME:-}"
  validate_url "BLOG_URL" "$BLOG_URL"
  validate_hugo_env
  
  success "All dependencies validated"
}

build_hugo_site() {
  log "🏗️ Building Hugo site for production..."
  
  cd sites/hugo
  
  "$PROJECT_ROOT/tools/scripts/internal-article-validate.sh"

  if ! hugo --environment production --baseURL "$BLOG_URL/" --minify --cleanDestinationDir; then
    error "Hugo build failed"
  fi
  
  cd ../..  # Back to project root
  
  # Copy built site to project root public/
  if [[ -d "public" ]]; then
    rm -rf public
  fi
  
  cp -r sites/hugo/public .
  
  success "Production Hugo site built and ready"
}

test_production_pages() {
  log "🧪 Testing production pages for deployment readiness..."
  
  # Run comprehensive production tests
  if ! "$PROJECT_ROOT/tools/scripts/internal-test-production-pages.sh" "$PROJECT_ROOT/public"; then
    error "Production page tests failed - aborting deployment"
  fi
  
  success "All production tests passed"
}

# No commit_and_push function needed - production deployment only

deploy_to_aws() {
  log "☁️ Deploying to AWS..."
  
  # Get S3 bucket and CloudFront distribution from CloudFormation
  local stack_name="${STACK_NAME_PREFIX:-website}-production"
  local bucket_name
  local distribution_id
  
  if ! bucket_name=$(aws cloudformation describe-stacks \
    --region "$AWS_REGION" \
    --stack-name "$stack_name" \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text 2>/dev/null); then
    error "Failed to get S3 bucket name from CloudFormation stack '$stack_name'"
  fi
  
  if ! distribution_id=$(aws cloudformation describe-stacks \
    --region "$AWS_REGION" \
    --stack-name "$stack_name" \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text 2>/dev/null); then
    error "Failed to get CloudFront distribution ID from CloudFormation stack '$stack_name'"
  fi
  
  log "📦 Syncing to S3 bucket: $bucket_name"
  
  # Sync to S3 with proper settings
  aws s3 sync public/ "s3://$bucket_name/" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "*.xml" \
    --exclude "*.json"
  
  # Upload HTML files with shorter cache
  aws s3 sync public/ "s3://$bucket_name/" \
    --cache-control "public, max-age=3600" \
    --include "*.html" \
    --include "*.xml" \
    --include "*.json"
  
  success "Files synced to S3"
  
  log "🔄 Invalidating CloudFront cache..."
  
  local invalidation_id
  invalidation_id=$(aws cloudfront create-invalidation \
    --distribution-id "$distribution_id" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)
  
  success "CloudFront invalidation created: $invalidation_id"
  
  log "🌐 Site deployed to: $BLOG_URL"
}

main() {
  log "🚀 Starting production deployment..."
  
  # Ensure we're in the project root
  cd "$PROJECT_ROOT"
  
  validate_deps
  validate_staging_deployment
  build_hugo_site
  test_production_pages
  deploy_to_aws
  
  success "🎉 Production deployment complete! Site is live at: $BLOG_URL"
}

# Run main function
main "$@"
