#!/bin/bash

# Deploy to staging environment (read-only git)
# This script does NOT commit or push. It enforces:
#  - Clean working tree (no uncommitted or staged changes)
#  - Local main is up-to-date with origin/main
#  - Then builds the site and deploys to staging S3 + invalidates CloudFront
# Usage: ./deploy-staging.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HUGO_DIR="$PROJECT_ROOT/sites/hugo"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/load-env.sh"
DOMAIN="${DOMAIN_NAME:-}"
STAGING_STACK="${STACK_NAME_PREFIX:-website}-staging"

if [[ -z "$DOMAIN" || "$DOMAIN" == "example.org" ]]; then
    echo "Set DOMAIN_NAME in .env before deploying." >&2
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying website to staging environment${NC}"

# Change to project root for git checks
cd "$PROJECT_ROOT"

echo -e "${YELLOW}🔍 Verifying git status (no auto-commit/push)...${NC}"

# Require clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo -e "${RED}❌ Working directory has uncommitted changes.${NC}"
  echo -e "${YELLOW}💡 Please commit and push manually before deploying to staging.${NC}"
  exit 1
fi

# Ensure we are on main (or allow an override via BRANCH)
BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
if [[ "$BRANCH" == "HEAD" ]]; then
  echo -e "${RED}❌ You are in a detached HEAD state. Checkout a branch (e.g., main).${NC}"
  exit 1
fi

# Ensure branch is up to date with origin
git fetch origin "$BRANCH" --quiet || true
LOCAL=$(git rev-parse "$BRANCH")
REMOTE=$(git rev-parse "origin/$BRANCH" || echo "$LOCAL")
BASE=$(git merge-base "$BRANCH" "origin/$BRANCH" || echo "$LOCAL")

if [[ "$LOCAL" != "$REMOTE" ]]; then
  if [[ "$LOCAL" = "$BASE" ]]; then
    echo -e "${RED}❌ Your branch is behind origin/$BRANCH. Pull first.${NC}"
    exit 1
  elif [[ "$REMOTE" = "$BASE" ]]; then
    echo -e "${RED}❌ Your branch is ahead of origin/$BRANCH. Push first.${NC}"
    exit 1
  else
    echo -e "${RED}❌ Your branch and origin/$BRANCH have diverged. Reconcile first.${NC}"
    exit 1
  fi
fi
echo -e "${GREEN}✅ Git checks passed (clean and up-to-date)${NC}"

# Change to Hugo directory for build
cd "$HUGO_DIR"

# Get staging bucket name from CloudFormation
echo -e "${YELLOW}🔍 Getting staging bucket name...${NC}"

# Check if AWS CLI is available and configured
if ! command -v aws >/dev/null 2>&1; then
    echo -e "${RED}❌ AWS CLI not found. Please install and configure AWS CLI.${NC}"
    exit 1
fi

# Try to get the staging bucket name with proper error handling
AWS_ERROR=$(mktemp)
STAGING_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STAGING_STACK" \
    --query 'Stacks[0].Outputs[?OutputKey==`StagingBucketName`].OutputValue' \
    --output text 2>"$AWS_ERROR")
AWS_EXIT_CODE=$?

if [[ $AWS_EXIT_CODE -ne 0 ]]; then
    echo -e "${RED}❌ AWS CLI error when getting staging bucket:${NC}"
    cat "$AWS_ERROR"
    rm -f "$AWS_ERROR"
    echo -e "${YELLOW}💡 Check your AWS credentials and region configuration${NC}"
    echo -e "${YELLOW}💡 Ensure the staging stack '$STAGING_STACK' exists${NC}"
    exit 1
fi

rm -f "$AWS_ERROR"

if [[ -z "$STAGING_BUCKET" || "$STAGING_BUCKET" == "None" ]]; then
    echo -e "${RED}❌ Could not find staging bucket. Is the staging infrastructure deployed?${NC}"
    echo -e "${YELLOW}💡 Run: aws/deploy-staging-infra.sh to provision staging infra (one-time)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Staging bucket: $STAGING_BUCKET${NC}"

# Build the site with Blowfish theme
echo -e "${YELLOW}🔎 Validating articles before build...${NC}"
"$PROJECT_ROOT/tools/scripts/internal-article-validate.sh"

echo -e "${YELLOW}🔨 Building site with Blowfish theme (staging env)...${NC}"
pushd "$HUGO_DIR" >/dev/null
hugo --environment staging --baseURL "https://staging.$DOMAIN/" --cleanDestinationDir --minify --destination public-staging
popd >/dev/null

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Hugo build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Site built successfully${NC}"

# Test pages before deployment
echo -e "${YELLOW}🧪 Testing pages for rendering issues...${NC}"
"$PROJECT_ROOT/tools/scripts/test-staging-pages.sh" "$HUGO_DIR/public-staging"

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Page tests failed - aborting deployment${NC}"
    echo -e "${YELLOW}💡 Fix the issues above before deploying${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All page tests passed${NC}"

# Sync to S3 with appropriate cache headers
echo -e "${YELLOW}☁️  Uploading to S3 bucket: $STAGING_BUCKET${NC}"

# Upload HTML files with short cache (staging should be fresh)
aws s3 sync "$HUGO_DIR/public-staging/" s3://$STAGING_BUCKET/ \
    --exclude "*" \
    --include "*.html" \
    --cache-control "max-age=300" \
    --delete

# Upload CSS/JS with longer cache but not too long for staging
aws s3 sync "$HUGO_DIR/public-staging/" s3://$STAGING_BUCKET/ \
    --exclude "*" \
    --include "*.css" \
    --include "*.js" \
    --cache-control "max-age=3600" \
    --delete

# Upload images with medium cache
aws s3 sync "$HUGO_DIR/public-staging/" s3://$STAGING_BUCKET/ \
    --exclude "*" \
    --include "*.png" \
    --include "*.jpg" \
    --include "*.jpeg" \
    --include "*.gif" \
    --include "*.svg" \
    --include "*.webp" \
    --cache-control "max-age=7200" \
    --delete

# Upload everything else with default cache
aws s3 sync "$HUGO_DIR/public-staging/" s3://$STAGING_BUCKET/ \
    --exclude "*.html" \
    --exclude "*.css" \
    --exclude "*.js" \
    --exclude "*.png" \
    --exclude "*.jpg" \
    --exclude "*.jpeg" \
    --exclude "*.gif" \
    --exclude "*.svg" \
    --exclude "*.webp" \
    --cache-control "max-age=1800" \
    --delete

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Upload completed successfully!${NC}"
    
    # Get CloudFront distribution ID for cache invalidation
    echo -e "${YELLOW}🔄 Getting CloudFront distribution ID...${NC}"
    
    AWS_ERROR=$(mktemp)
    DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STAGING_STACK" \
        --query 'Stacks[0].Outputs[?OutputKey==`StagingDistributionId`].OutputValue' \
        --output text 2>"$AWS_ERROR")
    AWS_EXIT_CODE=$?
    
    if [[ $AWS_EXIT_CODE -ne 0 ]]; then
        echo -e "${YELLOW}⚠️  Warning: Could not get CloudFront distribution ID:${NC}"
        cat "$AWS_ERROR"
        rm -f "$AWS_ERROR"
        echo -e "${YELLOW}💡 Skipping cache invalidation - deployment still successful${NC}"
    else
        rm -f "$AWS_ERROR"
        
        if [[ -n "$DISTRIBUTION_ID" && "$DISTRIBUTION_ID" != "None" ]]; then
            echo -e "${YELLOW}♻️  Creating CloudFront invalidation...${NC}"
            
            AWS_ERROR=$(mktemp)
            INVALIDATION_ID=$(aws cloudfront create-invalidation \
                --distribution-id "$DISTRIBUTION_ID" \
                --paths "/*" \
                --query 'Invalidation.Id' \
                --output text 2>"$AWS_ERROR")
            INVALIDATION_EXIT_CODE=$?
            
            if [[ $INVALIDATION_EXIT_CODE -ne 0 ]]; then
                echo -e "${YELLOW}⚠️  Warning: Could not create CloudFront invalidation:${NC}"
                cat "$AWS_ERROR"
                rm -f "$AWS_ERROR"
                echo -e "${YELLOW}💡 You may need to wait for CDN cache to expire naturally${NC}"
            else
                rm -f "$AWS_ERROR"
                echo -e "${GREEN}✅ Invalidation created: $INVALIDATION_ID${NC}"
                echo -e "${YELLOW}⏳ Cache invalidation may take 5-15 minutes${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No CloudFront distribution found - skipping invalidation${NC}"
        fi
    fi
    
    echo -e "${GREEN}🎉 Staging deployment complete!${NC}"
    echo -e "${BLUE}🌐 Staging URL: https://staging.$DOMAIN${NC}"
    echo -e "${YELLOW}📝 Note: Allow 5-10 minutes for DNS/CDN propagation${NC}"
    
else
    echo -e "${RED}❌ Upload failed${NC}"
    exit 1
fi
