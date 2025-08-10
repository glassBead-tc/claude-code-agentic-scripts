#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT_DIR/orchestrate-evolution.sh" scout