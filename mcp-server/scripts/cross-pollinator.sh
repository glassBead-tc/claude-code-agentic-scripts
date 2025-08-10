#!/bin/bash
# Cross-Pollinator: Combine patterns from different sources and merge agent designs
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LEARNING_DIR="$ROOT_DIR/cross-script-learning"
ARCHIVE_DIR="$ROOT_DIR/evolution-archive"
OUTPUT_DIR="$ROOT_DIR/colony-patterns"
SIGNALS_DIR="$ROOT_DIR/hive-signals"

mkdir -p "$OUTPUT_DIR" "$SIGNALS_DIR/discoveries"

PATTERNS_FILE="$LEARNING_DIR/knowledge-base/consolidated_patterns.json"
DISCOVERED_DIR="$ARCHIVE_DIR/discovered"

# Collect latest patterns (fallback to simple heuristics)
PATTERNS_JSON="{}"
if [[ -f "$PATTERNS_FILE" ]]; then
  PATTERNS_JSON="$(cat "$PATTERNS_FILE" 2>/dev/null || echo '{}')"
fi

# Gather up to 2 latest discovered agents
mapfile -t AGENTS < <(ls -1t "$DISCOVERED_DIR"/*.sh 2>/dev/null | head -2 || true)

MERGE_PROMPT=$(cat <<'EOF'
You are a creative agent architect. Merge the strengths of these agent scripts and the cross-script patterns into a superior hybrid agent.

Instructions:
- Preserve safety and autonomy (no destructive operations)
- Prefer simple, composable interfaces (args/stdin/stdout)
- Add light telemetry/logging for observability
- Keep script POSIX-compatible as much as possible

Return output with markers:
AGENT_NAME: <Name>
REASONING: <Short reasoning>
---SCRIPT_START---
#!/bin/bash
# ... merged agent script ...
---SCRIPT_END---
EOF
)

# Append pattern summary
MERGE_PROMPT+=$'\n\nCROSS_SCRIPT_PATTERNS:\n'
MERGE_PROMPT+="$(echo "$PATTERNS_JSON" | head -200)"

# Append parent scripts
idx=0
for agent in "${AGENTS[@]:-}"; do
  ((idx++))
  MERGE_PROMPT+=$"\n\nPARENT_$idx: $(basename "$agent")\n"
  MERGE_PROMPT+=$'---PARENT_START---\n'
  MERGE_PROMPT+="$(head -200 "$agent" 2>/dev/null)"
  MERGE_PROMPT+=$'\n---PARENT_END---\n'
done

OUT_NAME="hybrid-$(date +%s)"
OUT_SCRIPT="$OUTPUT_DIR/${OUT_NAME}.sh"
OUT_META="$OUTPUT_DIR/${OUT_NAME}.meta.json"

# Try Claude; fallback to simple concatenation
if command -v claude >/dev/null 2>&1; then
  RESPONSE="$(echo "$MERGE_PROMPT" | claude --print 2>/dev/null || true)"
  AGENT_NAME=$(echo "$RESPONSE" | grep -E "^AGENT_NAME:" | cut -d' ' -f2- | head -1)
  SCRIPT=$(echo "$RESPONSE" | sed -n '/---SCRIPT_START---/,/---SCRIPT_END---/p' | sed '1d;$d')
  if [[ -z "$SCRIPT" ]]; then
    SCRIPT="# Fallback merged agent\necho 'No merged script generated'"
  fi
else
  AGENT_NAME="$OUT_NAME"
  {
    echo "#!/bin/bash"
    echo "# Fallback hybrid agent (concatenated parents)"
    echo "set -e"
    for agent in "${AGENTS[@]:-}"; do
      echo "# === From: $(basename "$agent") ==="
      sed 's/^/## /g' "$agent" | head -50
    done
    echo "echo 'Hybrid agent placeholder executed'"
  } > "$OUT_SCRIPT"
  chmod +x "$OUT_SCRIPT"
fi

if [[ ! -f "$OUT_SCRIPT" ]]; then
  echo "$SCRIPT" > "$OUT_SCRIPT"
  chmod +x "$OUT_SCRIPT"
fi

cat > "$OUT_META" <<EOF
{
  "id": "$OUT_NAME",
  "name": "${AGENT_NAME:-$OUT_NAME}",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "parents": [$(printf '"%s"' "${AGENTS[0]-}" | xargs -I{} basename {} .sh), $(printf '"%s"' "${AGENTS[1]-}" | xargs -I{} basename {} .sh)],
  "source": "cross-pollinator",
  "patterns_used": true
}
EOF

echo "Created hybrid agent: $OUT_SCRIPT"

echo "hybrid_created: $OUT_NAME" >> "$SIGNALS_DIR/discoveries/cross-pollination.log"