#!/bin/bash
# Wrapper that makes existing scripts behave like scout bees
# Key: Remove goal-oriented behavior, add exploration; emit signals only

set -euo pipefail

SCRIPT_PATH="$1"; shift || true
SIGNALS_DIR="$(dirname "$0")/../../hive-signals"
mkdir -p "$SIGNALS_DIR/discoveries" "$SIGNALS_DIR/metrics"

# Run the target script in exploration-friendly mode when possible
if [[ -x "$SCRIPT_PATH" ]]; then
  if "$SCRIPT_PATH" --help >/dev/null 2>&1; then
    bash "$SCRIPT_PATH" --extract-only --threshold 0.6 "$@" || bash "$SCRIPT_PATH" "$@"
  else
    bash "$SCRIPT_PATH" "$@"
  fi | tee >(awk '{ print } END { }' >"$SIGNALS_DIR/discoveries/scout-$(date +%s).log")
else
  echo "Script not executable: $SCRIPT_PATH" >&2
  exit 1
fi