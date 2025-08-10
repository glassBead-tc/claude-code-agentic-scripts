#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_URL="http://localhost:3000"

# Ensure server is running
if ! pgrep -f "ts-node/esm src/server.ts" >/dev/null 2>&1; then
  (cd "$ROOT_DIR/mcp-server" && npm run start &)
  sleep 2
fi

echo "--- Demo: Scout mode exploration ---"
"$ROOT_DIR/examples/scout-exploration.sh" || true

echo "--- Demo: ADAS directed design ---"
"$ROOT_DIR/examples/adas-optimization.sh" code-automation 1 || true

echo "--- Demo: Cross-pollination ---"
"$ROOT_DIR/mcp-server/scripts/cross-pollinator.sh" || true

echo "--- Demo: Hybrid mode ---"
"$ROOT_DIR/examples/hybrid-balanced.sh" code-automation 1 || true

echo "Artifacts:"
ls -1 "$ROOT_DIR/hive-signals"/* 2>/dev/null || true
ls -1 "$ROOT_DIR/colony-patterns"/* 2>/dev/null || true