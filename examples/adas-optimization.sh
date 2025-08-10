#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT_DIR/orchestrate-evolution.sh" adas "${1:-code-automation}" "${2:-1}"