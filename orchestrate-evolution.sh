#!/bin/bash
# Main entry point to orchestrate evolution
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_URL="http://localhost:3000"
MODE="${1:-auto}"
DOMAIN="${2:-code-automation}"
ITERATIONS="${3:-1}"

if [[ "$MODE" == "auto" ]]; then
  # Ask server to pick based on a simple feature set
  MODE=$(node -e 'const f={problemSize:200,timeBudgetSec:120,noveltyRequired:true}; console.log((f.noveltyRequired&&!f.reliabilityRequired)?"scout":"hybrid")')
fi

echo "Selected mode: $MODE"

case "$MODE" in
  scout)
    curl -s -X POST "$SERVER_URL/run-script" \
      -H 'Content-Type: application/json' \
      -d '{"mode":"scout","scriptPath":"evolution/emergent-capability-discovery.sh","params":{}}' | sed -n '1,120p'
    ;;
  adas)
    "$ROOT_DIR/mcp-server/scripts/adas-wrapper.sh" "$DOMAIN" "$ITERATIONS"
    ;;
  hybrid)
    # Trigger ADAS then pattern extraction
    "$ROOT_DIR/mcp-server/scripts/adas-wrapper.sh" "$DOMAIN" "$ITERATIONS" || true
    curl -s -X POST "$SERVER_URL/run-script" \
      -H 'Content-Type: application/json' \
      -d '{"mode":"scout","scriptPath":"evolution/cross-script-learning-network.sh","params":{}}' | sed -n '1,120p'
    ;;
  *)
    echo "Unknown mode: $MODE" >&2; exit 1
    ;;
fi