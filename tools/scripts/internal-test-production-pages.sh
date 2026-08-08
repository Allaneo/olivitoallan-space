#!/bin/bash

# Test production pages for comprehensive validation before deployment
# This script validates production-specific features that aren't available in staging
# Usage: ./internal-test-production-pages.sh [public-directory]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default to production build directory
PUBLIC_DIR="${1:-$PROJECT_ROOT/public}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((++TESTS_RUN))
    echo -e "${YELLOW}🧪 Testing: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}  ✅ PASS: $test_name${NC}"
        ((++TESTS_PASSED))
        return 0
    else
        echo -e "${RED}  ❌ FAIL: $test_name${NC}"
        ((++TESTS_FAILED))
        return 0
    fi
}

# Function to check if file exists and is not empty
check_file_exists() {
    local file="$1"
    [[ -f "$file" && -s "$file" ]]
}

# Function to check if HTML file contains required elements
check_html_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        return 0
    else
        echo -e "${RED}    Missing: $description${NC}"
        return 1
    fi
}

# Function to validate production-specific SEO elements
validate_production_seo() {
    local file="$1"
    local errors=0
    
    # Check for proper meta robots (should NOT be noindex in production)
    if grep -qi 'content="noindex' "$file" 2>/dev/null; then
        echo -e "${RED}    Found noindex directive (should not be in production)${NC}"
        ((errors++))
    fi
    
    # Check for analytics/tracking (Google Analytics, etc.)
    if ! grep -qi 'gtag\|google-analytics\|gtm' "$file" 2>/dev/null; then
        echo -e "${YELLOW}    Warning: No analytics tracking detected${NC}"
        # Not a failure, just a warning
    fi
    
    # Check for proper canonical URLs (should not contain staging URLs)
    if grep -qi 'staging\.' "$file" 2>/dev/null; then
        echo -e "${RED}    Found staging URLs in production build${NC}"
        ((errors++))
    fi
    
    return $errors
}

# Function to validate sitemap content
validate_sitemap() {
    local sitemap="$1"
    local errors=0
    
    # Check sitemap is valid XML
    if ! grep -q '<?xml' "$sitemap" 2>/dev/null; then
        echo -e "${RED}    Sitemap is not valid XML${NC}"
        ((errors++))
    fi
    
    # Check sitemap contains actual URLs
    if ! grep -q '<url>' "$sitemap" 2>/dev/null; then
        echo -e "${RED}    Sitemap contains no URLs${NC}"
        ((errors++))
    fi
    
    # Check sitemap doesn't contain staging URLs
    if grep -qi 'staging\.' "$sitemap" 2>/dev/null; then
        echo -e "${RED}    Sitemap contains staging URLs${NC}"
        ((errors++))
    fi
    
    return $errors
}

echo -e "${BLUE}🧪 Running production page tests on: $PUBLIC_DIR${NC}"
echo ""

# Verify build directory exists
if [[ ! -d "$PUBLIC_DIR" ]]; then
    echo -e "${RED}❌ Build directory not found: $PUBLIC_DIR${NC}"
    echo -e "${YELLOW}💡 Run the production build first${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build directory found${NC}"
echo ""

# Test 1: Production-specific SEO validation
if [[ -f "$PUBLIC_DIR/index.html" ]]; then
    run_test "Production SEO compliance" "validate_production_seo '$PUBLIC_DIR/index.html'"
fi

# Test 2: Sitemap validation (required in production)
run_test "Sitemap exists" "check_file_exists '$PUBLIC_DIR/sitemap.xml'"
if [[ -f "$PUBLIC_DIR/sitemap.xml" ]]; then
    run_test "Sitemap content validation" "validate_sitemap '$PUBLIC_DIR/sitemap.xml'"
fi

# Test 3: RSS feed validation
run_test "RSS feed exists" "check_file_exists '$PUBLIC_DIR/index.xml'"
if [[ -f "$PUBLIC_DIR/index.xml" ]]; then
    run_test "RSS feed is valid XML" "grep -q '<?xml' '$PUBLIC_DIR/index.xml'"
fi

# Test 4: Essential pages exist with production content
run_test "Home page exists" "check_file_exists '$PUBLIC_DIR/index.html'"
run_test "About page exists" "check_file_exists '$PUBLIC_DIR/about/index.html'"
run_test "404 page exists" "check_file_exists '$PUBLIC_DIR/404.html'"

# Test 5: Static assets exist
run_test "CSS files exist" "[[ \$(find '$PUBLIC_DIR' -name '*.css' | wc -l) -gt 0 ]]"
run_test "JS files exist" "[[ \$(find '$PUBLIC_DIR' -name '*.js' | wc -l) -gt 0 ]]"
run_test "Favicon exists" "check_file_exists '$PUBLIC_DIR/favicon.svg'"

# Test 6: Robots.txt validation (production-specific)
run_test "Robots.txt exists" "check_file_exists '$PUBLIC_DIR/robots.txt'"
if [[ -f "$PUBLIC_DIR/robots.txt" ]]; then
    # In production, robots.txt should allow crawling
    if grep -qi "disallow: /" "$PUBLIC_DIR/robots.txt" 2>/dev/null; then
        run_test "Robots.txt allows crawling" "false"  # Force fail
    else
        run_test "Robots.txt allows crawling" "true"
    fi
fi

# Test 7: Optional articles validation
if [[ -d "$PUBLIC_DIR/posts" ]]; then
    run_test "Posts section exists" "check_file_exists '$PUBLIC_DIR/posts/index.html'"
    
    while read -r article; do
        if [[ -n "$article" && -f "$article" ]]; then
            article_path=$(dirname "$article")
            article_name=$(basename "$article_path")
            
            run_test "Article production SEO: $article_name" "validate_production_seo '$article'"
            
            # Check for action panels (should work in production)
            run_test "Action panel in $article_name" "check_html_content '$article' 'bf-action-panel\|bf-action-float' 'Action panel components'"
        fi
    done < <(find "$PUBLIC_DIR/posts" -name "index.html" -not -path "*/posts/index.html" -not -path "*/page/*/index.html" | head -3)
fi

# Test 8: Performance checks (production-specific)
if [[ -f "$PUBLIC_DIR/index.html" ]]; then
    # Check for minification
    run_test "HTML is minified" "! grep -q '^[[:space:]]*$' '$PUBLIC_DIR/index.html'"
    
    # Check for compression-friendly content
    home_size=$(wc -c < "$PUBLIC_DIR/index.html")
    if [[ $home_size -gt 100000 ]]; then  # 100KB threshold
        run_test "Home page size reasonable" "false"
        echo -e "${RED}    Home page is ${home_size} bytes (> 100KB)${NC}"
    else
        run_test "Home page size reasonable" "true"
    fi
fi

# Test 9: Security headers preparation (check for CSP-ready content)
if [[ -f "$PUBLIC_DIR/index.html" ]]; then
    # Check for inline styles (CSP concern)
    if grep -q 'style=' "$PUBLIC_DIR/index.html" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Warning: Inline styles detected (may need CSP adjustments)${NC}"
    fi
fi

echo ""
echo -e "${BLUE}📊 Production Test Results Summary${NC}"
echo -e "  Tests run: ${TESTS_RUN}"
echo -e "  ${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "  ${RED}Failed: ${TESTS_FAILED}${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 All production tests passed! Site is ready for deployment.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some production tests failed. Please fix issues before deploying.${NC}"
    echo -e "${YELLOW}💡 Production deployment requires all tests to pass for SEO and performance compliance.${NC}"
    exit 1
fi
