#!/usr/bin/env bash
set -euo pipefail

# dev.sh — Start Hugo development environment
#
# Usage:
#   tools/scripts/dev.sh start      # Start Hugo development server
#   tools/scripts/dev.sh stop       # Stop Hugo development server  
#   tools/scripts/dev.sh restart    # Restart Hugo development server
#   tools/scripts/dev.sh build      # Build site for testing
#
# What it does:
#   - Starts Hugo development server with live reload
#   - Shows helpful URLs and status
#   - Provides easy content creation commands

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/tools/scripts/load-env.sh"
SITE_DIR="$ROOT_DIR/sites/hugo"
PID_FILE="$SITE_DIR/.hugo-dev.pid"
HUGO_PORT="${HUGO_PORT:-1313}"
LOG_DIR="$SITE_DIR/.hugo-logs"
LOG_FILE="$LOG_DIR/hugo.log"
TRACE_FILE="$LOG_DIR/hugo.trace"
HUGO_START_TIMEOUT="${HUGO_START_TIMEOUT:-10}"   # seconds to wait for server readiness
HUGO_BUILD_TIMEOUT="${HUGO_BUILD_TIMEOUT:-60}"   # seconds to allow a build to run
HUGO_STOP_TIMEOUT="${HUGO_STOP_TIMEOUT:-5}"      # seconds to allow graceful stop
HUGO_BIND="${HUGO_BIND:-127.0.0.1}"

# --- Helpers ---
have() { command -v "$1" >/dev/null 2>&1; }
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [DEV] $*"; }
success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [DEV] ✅ $*"; }
warning() { echo "$(date '+%Y-%m-%d %H:%M:%S') [DEV] ⚠️  $*"; }
error() { echo "$(date '+%Y-%m-%d %H:%M:%S') [DEV] ❌ $*"; exit 1; }

validate_deps() {
  log "🔍 Validating development environment..."
  
  have hugo || error "Hugo not found. Install: brew install hugo"
  success "Hugo $(hugo version | cut -d' ' -f2) found"
  
  if [[ ! -f "$SITE_DIR/config/_default/hugo.toml" ]]; then
    error "Hugo configuration not found. Make sure you're in the project root."
  fi
  
  success "Hugo site configuration validated"
}

prepare_logs() {
  mkdir -p "$LOG_DIR"
  # rotate previous log/trace
  if [[ -f "$LOG_FILE" ]]; then mv "$LOG_FILE" "$LOG_FILE.$(date +%s)" || true; fi
  if [[ -f "$TRACE_FILE" ]]; then mv "$TRACE_FILE" "$TRACE_FILE.$(date +%s)" || true; fi
}

print_log_tail() {
  if [[ -f "$LOG_FILE" ]]; then
    echo "----- Last 200 log lines ($LOG_FILE) -----"
    tail -n 200 "$LOG_FILE" || true
    echo "-----------------------------------------"
  fi
  if [[ -f "$TRACE_FILE" ]]; then
    echo "(Trace available at $TRACE_FILE)"
  fi
}

start_hugo() {
  log "🚀 Starting Hugo development server..."
  
  cd "$SITE_DIR"
  prepare_logs
  
  # Check if server is already running
  if lsof -i ":$HUGO_PORT" >/dev/null 2>&1; then
    warning "Port $HUGO_PORT is already in use. Trying to stop existing server..."
    stop_hugo
    sleep 2
  fi
  
  log "Starting Hugo server on port $HUGO_PORT..."
  # Stream both stdout/stderr to log via tee
  (
    hugo server \
      --port "$HUGO_PORT" \
      --bind "$HUGO_BIND" \
      --buildDrafts \
      --buildFuture \
      --disableFastRender \
      --logLevel debug \
      --panicOnWarning \
      --printI18nWarnings \
      --printPathWarnings \
      --templateMetrics \
      --templateMetricsHints \
      --trace "$TRACE_FILE" \
      2>&1 | tee -a "$LOG_FILE"
  ) &
  HUGO_PID=$!
  
  # Save PID for later cleanup
  echo "$HUGO_PID" > "$PID_FILE"
  
  # Wait for server to report readiness with timeout
  log "Waiting for Hugo server to start..."
  seconds_waited=0
  while (( seconds_waited < HUGO_START_TIMEOUT )); do
    if lsof -i ":$HUGO_PORT" >/dev/null 2>&1; then
      break
    fi
    sleep 1
    seconds_waited=$((seconds_waited+1))
  done
  
  if lsof -i ":$HUGO_PORT" >/dev/null 2>&1; then
    success "Hugo development server running"
    echo ""
    echo "📝 Development URLs:"
    echo "   Site:     http://localhost:$HUGO_PORT"
    echo "   Config:   sites/hugo/hugo.toml"
    echo "   Logs:     $LOG_FILE"
    echo "   Trace:    $TRACE_FILE"
    echo ""
    echo "📄 Quick commands:"
    echo "   New post:    tools/scripts/new-post.sh \"My new post\""
    echo "   New page:    hugo new page/my-page/index.md" 
    echo "   Stop server: tools/scripts/dev.sh stop"
    echo ""
    echo "🔄 The server will automatically reload when you make changes."
    echo "Press Ctrl+C to stop the server."
    
    # Wait for user interrupt
    wait $HUGO_PID
  else
    warning "Timeout: Hugo server not reachable on port $HUGO_PORT after ${HUGO_START_TIMEOUT}s."
    # Kill the background server process to avoid dangling jobs
    if kill -0 "$HUGO_PID" 2>/dev/null; then
      kill "$HUGO_PID" 2>/dev/null || true
      sleep 1
      kill -9 "$HUGO_PID" 2>/dev/null || true
    fi
    print_log_tail
    error "Hugo server failed to start"
  fi
  
}

stop_hugo() {
  log "🛑 Stopping Hugo development server..."
  
  # Kill by PID if available
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill "$pid" 2>/dev/null; then
      # Wait up to HUGO_STOP_TIMEOUT for graceful stop
      waited=0
      while kill -0 "$pid" 2>/dev/null && (( waited < HUGO_STOP_TIMEOUT )); do
        sleep 1
        waited=$((waited+1))
      done
      if kill -0 "$pid" 2>/dev/null; then
        warning "Graceful stop timed out after ${HUGO_STOP_TIMEOUT}s. Forcing..."
        kill -9 "$pid" 2>/dev/null || true
      fi
      success "Hugo server stopped (PID: $pid)"
    fi
    rm -f "$PID_FILE"
  fi
  
  # Kill any remaining Hugo processes on the port
  if lsof -i ":$HUGO_PORT" >/dev/null 2>&1; then
    local pids
    pids=$(lsof -ti ":$HUGO_PORT")
    if [[ -n "$pids" ]]; then
      echo "$pids" | xargs kill 2>/dev/null || true
      success "Stopped processes on port $HUGO_PORT"
    fi
  fi
}

build_hugo() {
  log "🏗️ Building Hugo site for testing..."
  
  cd "$SITE_DIR"
  prepare_logs
  
  (
    hugo \
      --buildDrafts \
      --buildFuture \
      --cleanDestinationDir \
      --logLevel debug \
      --panicOnWarning \
      --printI18nWarnings \
      --printPathWarnings \
      --templateMetrics \
      --templateMetricsHints \
      --trace "$TRACE_FILE" \
      2>&1 | tee -a "$LOG_FILE"
  ) &
  BUILD_PID=$!
  
  waited=0
  build_exit=0
  while kill -0 "$BUILD_PID" 2>/dev/null; do
    if (( waited >= HUGO_BUILD_TIMEOUT )); then
      warning "Timeout: Hugo build exceeded ${HUGO_BUILD_TIMEOUT}s. Terminating..."
      kill "$BUILD_PID" 2>/dev/null || true
      sleep 1
      kill -9 "$BUILD_PID" 2>/dev/null || true
      print_log_tail
      error "Hugo build timed out"
    fi
    sleep 1
    waited=$((waited+1))
  done
  
  # Capture exit code
  wait "$BUILD_PID" || build_exit=$?
  if (( build_exit == 0 )); then
    success "Hugo site built successfully"
    echo "📁 Built site available in: sites/hugo/public/"
    echo "🧪 Logs: $LOG_FILE"
    echo "🧵 Trace: $TRACE_FILE"
  else
    print_log_tail
    error "Hugo build failed (exit $build_exit)"
  fi
}

restart_hugo() {
  log "🔄 Restarting Hugo development server..."
  stop_hugo
  sleep 1
  start_hugo
}

show_help() {
  echo "Hugo Development Script"
  echo ""
  echo "Usage:"
  echo "  tools/scripts/dev.sh start      Start Hugo development server"
  echo "  tools/scripts/dev.sh stop       Stop Hugo development server" 
  echo "  tools/scripts/dev.sh restart    Restart Hugo development server"
  echo "  tools/scripts/dev.sh build      Build site for testing"
  echo "  tools/scripts/dev.sh help       Show this help"
  echo ""
  echo "Environment variables:"
  echo "  HUGO_PORT            Port for Hugo server (default: 1313)"
  echo "  HUGO_START_TIMEOUT   Seconds to wait for server readiness (default: 10)"
  echo "  HUGO_BUILD_TIMEOUT   Seconds to allow hugo build to run   (default: 60)"
  echo "  HUGO_STOP_TIMEOUT    Seconds to wait for graceful stop    (default: 5)"
  echo "  HUGO_BIND            Bind address for hugo server          (default: 127.0.0.1)"
}

main() {
  local action="${1:-start}"
  
  case "$action" in
    "start")
      validate_deps
      start_hugo
      ;;
    "stop")
      stop_hugo
      ;;
    "restart")
      validate_deps
      restart_hugo
      ;;
    "build")
      validate_deps
      build_hugo
      ;;
    "help"|"-h"|"--help")
      show_help
      ;;
    *)
      error "Unknown action: $action. Use 'help' for usage information."
      ;;
  esac
}

# Cleanup on exit
cleanup() {
  if [[ -f "$PID_FILE" ]]; then
    stop_hugo
  fi
}

trap cleanup EXIT INT TERM

# Run main function
main "$@"
