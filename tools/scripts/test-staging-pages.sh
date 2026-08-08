#!/bin/bash

# Test staging pages for rendering issues before deployment
# This script validates that key pages render correctly and contain expected content
# Usage: ./test-staging-pages.sh [public-directory]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HUGO_DIR="$PROJECT_ROOT/sites/hugo"

# Default to staging build directory
PUBLIC_DIR="${1:-$HUGO_DIR/public-staging}"

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

# Function to validate HTML structure
validate_html_structure() {
    local file="$1"
    local errors=0
    
    # Check for basic HTML structure (minified, so patterns are flexible)
    check_html_content "$file" "<html" "HTML tag" || ((errors++))
    check_html_content "$file" "<head>" "HEAD section" || ((errors++))
    check_html_content "$file" "<body" "BODY section" || ((errors++))
    check_html_content "$file" "<title>" "TITLE tag" || ((errors++))
    
    # Check for Blowfish theme elements (case insensitive)
    if ! grep -qi "blowfish" "$file" 2>/dev/null; then
        echo -e "${RED}    Missing: Blowfish theme references${NC}"
        ((errors++))
    fi
    
    # Check for no obvious errors (excluding JavaScript console methods)
    if grep -qi "error:" "$file" 2>/dev/null && ! grep -qi "console\.error" "$file" 2>/dev/null; then
        echo -e "${RED}    Found error messages in HTML${NC}"
        ((errors++))
    fi
    
    return $errors
}

# Function to check page performance indicators
check_page_performance() {
    local file="$1"
    local errors=0
    
    # Check for minification (no excessive whitespace)
    local file_size=$(wc -c < "$file")
    if [[ $file_size -gt 500000 ]]; then  # 500KB threshold
        echo -e "${YELLOW}    Warning: Large HTML file (${file_size} bytes)${NC}"
    fi
    
    # Check for critical CSS/JS loading (handle both quoted and unquoted attributes)
    if ! grep -q 'rel=stylesheet\|rel="stylesheet"' "$file" 2>/dev/null; then
        echo -e "${RED}    Missing: CSS stylesheets${NC}"
        ((errors++))
    fi
    
    return $errors
}

echo -e "${BLUE}🧪 Running staging page tests on: $PUBLIC_DIR${NC}"
echo ""

# Verify build directory exists
if [[ ! -d "$PUBLIC_DIR" ]]; then
    echo -e "${RED}❌ Build directory not found: $PUBLIC_DIR${NC}"
    echo -e "${YELLOW}💡 Run the build first: hugo --environment staging${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build directory found${NC}"
echo ""

# Test 1: Home page exists and renders
run_test "Home page exists" "check_file_exists '$PUBLIC_DIR/index.html'"
if [[ -f "$PUBLIC_DIR/index.html" ]]; then
    run_test "Home page HTML structure" "validate_html_structure '$PUBLIC_DIR/index.html'"
    run_test "Home page performance" "check_page_performance '$PUBLIC_DIR/index.html'"
fi

# Test 2: Essential pages exist
run_test "About page exists" "check_file_exists '$PUBLIC_DIR/about/index.html'"
run_test "404 page exists" "check_file_exists '$PUBLIC_DIR/404.html'"

# Test 3: Posts section and any articles supplied by the site owner
run_test "Posts section exists" "check_file_exists '$PUBLIC_DIR/posts/index.html'"

# Test up to three articles when content has been added.
if [[ -d "$PUBLIC_DIR/posts" ]]; then
    while read -r article; do
        if [[ -n "$article" && -f "$article" ]]; then
            article_path=$(dirname "$article")
            article_name=$(basename "$article_path")
            
            run_test "Article: $article_name" "validate_html_structure '$article'"
            
            # Check for action panel in articles
            run_test "Action panel in $article_name" "check_html_content '$article' 'bf-action-panel\|bf-action-float' 'Action panel components'"
        fi
    done < <(find "$PUBLIC_DIR/posts" -name "index.html" -not -path "*/posts/index.html" -not -path "*/page/*/index.html" | head -3)
fi

# Test 4: Static assets exist
run_test "CSS files exist" "[[ \$(find '$PUBLIC_DIR' -name '*.css' | wc -l) -gt 0 ]]"
run_test "JS files exist" "[[ \$(find '$PUBLIC_DIR' -name '*.js' | wc -l) -gt 0 ]]"
run_test "Favicon exists" "check_file_exists '$PUBLIC_DIR/favicon.svg'"

# Test 5: SEO and meta files (sitemap may be disabled in staging)
if [[ -f "$PUBLIC_DIR/sitemap.xml" ]]; then
    run_test "Sitemap exists" "check_file_exists '$PUBLIC_DIR/sitemap.xml'"
else
    echo -e "${YELLOW}🧪 Skipping: Sitemap (disabled in staging environment)${NC}"
fi
run_test "Robots.txt exists" "check_file_exists '$PUBLIC_DIR/robots.txt'"

# Test 6: RSS feeds
run_test "Main RSS feed exists" "check_file_exists '$PUBLIC_DIR/index.xml'"

# Test 7: Check for broken internal links (sample)
if command -v grep >/dev/null 2>&1; then
    run_test "No obvious broken links" "! find '$PUBLIC_DIR' -name '*.html' -exec grep -l 'href=\"broken\"\\|href=\"404\"' {} \\; | head -1 | grep -q ."
fi

# Test 8: Accessibility basics
if [[ -f "$PUBLIC_DIR/index.html" ]]; then
    run_test "Alt tags present" "check_html_content '$PUBLIC_DIR/index.html' 'alt=' 'Image alt attributes'"
    run_test "ARIA labels present" "check_html_content '$PUBLIC_DIR/index.html' 'aria-label' 'ARIA accessibility labels'"
fi

# Test 9: Theme-specific checks (check for Hugo theme CSS/JS)
run_test "Theme CSS/JS assets" "[[ \$(find '$PUBLIC_DIR' -name '*.css' -o -name '*.js' | wc -l) -gt 0 ]]"

echo ""
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo -e "  Tests run: ${TESTS_RUN}"
echo -e "  ${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "  ${RED}Failed: ${TESTS_FAILED}${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed! Site is ready for deployment.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please fix issues before deploying.${NC}"
    echo -e "${YELLOW}💡 Check the failed tests above for specific issues.${NC}"
    exit 1
fi
