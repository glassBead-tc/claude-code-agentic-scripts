#!/bin/bash
# Wrapper for evolution/adas-meta-agent.sh adapted for MCP coordination
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SIGNALS_DIR="$ROOT_DIR/hive-signals"
ADAS_SCRIPT="$ROOT_DIR/evolution/adas-meta-agent.sh"

mkdir -p "$SIGNALS_DIR/metrics" "$SIGNALS_DIR/discoveries"

DOMAIN="${1:-code-automation}"
ITERATIONS="${2:-1}"

if [[ ! -x "$ADAS_SCRIPT" ]]; then
  chmod +x "$ADAS_SCRIPT" 2>/dev/null || true
fi

START_TS=$(date -u +%s)
set +e
OUTPUT="$("$ADAS_SCRIPT" "$DOMAIN" "$ITERATIONS" 2>&1)"
STATUS=$?
set -e
END_TS=$(date -u +%s)

# Emit metric signal
cat > "$SIGNALS_DIR/metrics/adas_run_${START_TS}.json" <<EOF
{
  "kind": "adas_run",
  "domain": "$DOMAIN",
  "iterations": $ITERATIONS,
  "status": $STATUS,
  "duration_sec": $((END_TS-START_TS))
}
EOF

# Emit discovery tail if success
if [[ $STATUS -eq 0 ]]; then
  echo "$OUTPUT" | tail -n 100 > "$SIGNALS_DIR/discoveries/adas_${END_TS}.log"
fi

echo "$OUTPUT"
exit $STATUS