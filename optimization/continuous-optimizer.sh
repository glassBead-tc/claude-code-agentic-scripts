#!/bin/bash

# Continuous Code Optimizer - Monitors and optimizes code in real-time
# Usage: ./continuous-optimizer.sh [directory] [--watch] [--auto-commit]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
TARGET_DIR=${1:-.}
WATCH_MODE=false
AUTO_COMMIT=false
OPTIMIZATION_LEVEL="balanced" # aggressive, balanced, conservative

# Parse arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --watch)
            WATCH_MODE=true
            shift
            ;;
        --auto-commit)
            AUTO_COMMIT=true
            shift
            ;;
        --level)
            OPTIMIZATION_LEVEL="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${MAGENTA}🚀 Continuous Code Optimizer${NC}"
echo "Target: $TARGET_DIR"
echo "Mode: $([ "$WATCH_MODE" = true ] && echo "Watch" || echo "Single run")"
echo "Optimization level: $OPTIMIZATION_LEVEL"
echo

# Initialize optimization session
SESSION_ID=$(claude -p "Initialize continuous optimization session for $TARGET_DIR" \
    --output-format json \
    --system-prompt "You are a code optimization expert specializing in performance, readability, and maintainability improvements." \
    2>/dev/null | jq -r '.session_id')

# Function to analyze code metrics
analyze_metrics() {
    local file=$1
    local metrics_file="metrics-$(basename "$file").json"
    
    METRICS_PROMPT=$(cat <<EOF
Analyze this code and provide detailed metrics:
{
  "performance": {
    "time_complexity": "O(n)",
    "space_complexity": "O(1)",
    "bottlenecks": ["list of bottlenecks"],
    "optimization_potential": 0-100
  },
  "quality": {
    "readability_score": 0-100,
    "maintainability_index": 0-100,
    "code_smells": ["list of issues"],
    "duplications": ["duplicate code blocks"]
  },
  "suggestions": {
    "quick_wins": ["easy optimizations"],
    "major_refactors": ["significant improvements"],
    "pattern_improvements": ["design pattern suggestions"]
  }
}

Code:
$(cat "$file")
EOF
)
    
    claude -p "$METRICS_PROMPT" \
        --resume "$SESSION_ID" \
        --output-format json \
        --max-turns 1 \
        2>/dev/null | jq -r '.result' > "$metrics_file"
    
    echo "$metrics_file"
}

# Function to optimize a single file
optimize_file() {
    local file=$1
    local backup_file="${file}.backup.$(date +%s)"
    
    echo -e "\n${BLUE}Analyzing: $file${NC}"
    
    # Create backup
    cp "$file" "$backup_file"
    
    # Get current metrics
    METRICS=$(analyze_metrics "$file" | xargs cat)
    
    # Check optimization potential
    OPT_POTENTIAL=$(echo "$METRICS" | jq -r '.performance.optimization_potential // 0')
    
    if [ "$OPT_POTENTIAL" -lt 20 ]; then
        echo -e "${GREEN}✓ Already optimized (potential: ${OPT_POTENTIAL}%)${NC}"
        rm "$backup_file"
        return 0
    fi
    
    echo -e "${YELLOW}Optimization potential: ${OPT_POTENTIAL}%${NC}"
    
    # Generate optimization plan
    OPTIMIZATION_PROMPT=$(cat <<EOF
Based on these metrics, optimize the code with focus on:
1. Performance improvements (reduce complexity)
2. Code quality (improve readability and maintainability)
3. Best practices and patterns
4. Security enhancements

Metrics analysis:
$METRICS

Optimization level: $OPTIMIZATION_LEVEL

Provide the optimized code maintaining exact functionality.
Include comments explaining significant changes.
EOF
)
    
    # Stream optimizations for large files
    if [ $(wc -l < "$file") -gt 500 ]; then
        echo -e "${CYAN}Large file detected, using streaming optimization...${NC}"
        
        # Split file into chunks and optimize
        split -l 100 "$file" "${file}.chunk."
        
        for chunk in "${file}.chunk."*; do
            OPTIMIZED_CHUNK=$(cat "$chunk" | claude -p "$OPTIMIZATION_PROMPT" \
                --resume "$SESSION_ID" \
                --output-format text \
                --max-turns 2)
            echo "$OPTIMIZED_CHUNK" > "${chunk}.optimized"
        done
        
        # Merge optimized chunks
        cat "${file}.chunk."*.optimized > "${file}.optimized"
        rm "${file}.chunk."*
    else
        # Optimize entire file
        OPTIMIZED_CODE=$(cat "$file" | claude -p "$OPTIMIZATION_PROMPT" \
            --resume "$SESSION_ID" \
            --output-format text \
            --max-turns 3)
        echo "$OPTIMIZED_CODE" > "${file}.optimized"
    fi
    
    # Validate optimized code
    echo -e "${BLUE}Validating optimizations...${NC}"
    
    VALIDATION_PROMPT=$(cat <<EOF
Compare these two versions and verify:
1. Functionality is preserved
2. No breaking changes introduced
3. Tests would still pass

Original:
$(cat "$backup_file")

Optimized:
$(cat "${file}.optimized")

Respond with JSON:
{
  "safe_to_apply": true/false,
  "breaking_changes": [],
  "test_impact": "none|minor|major",
  "confidence": 0-100
}
EOF
)
    
    VALIDATION=$(claude -p "$VALIDATION_PROMPT" \
        --resume "$SESSION_ID" \
        --output-format json \
        --max-turns 1 \
        2>/dev/null | jq -r '.result' | jq '.')
    
    SAFE_TO_APPLY=$(echo "$VALIDATION" | jq -r '.safe_to_apply')
    CONFIDENCE=$(echo "$VALIDATION" | jq -r '.confidence')
    
    if [[ "$SAFE_TO_APPLY" == "true" ]] && [ "$CONFIDENCE" -gt 80 ]; then
        echo -e "${GREEN}✅ Optimization validated (confidence: ${CONFIDENCE}%)${NC}"
        
        # Apply optimization
        mv "${file}.optimized" "$file"
        
        # Generate diff report
        diff -u "$backup_file" "$file" > "${file}.optimization.diff" || true
        
        # Auto-commit if enabled
        if [ "$AUTO_COMMIT" = true ] && [ -d .git ]; then
            git add "$file"
            COMMIT_MSG=$(claude -p "Generate a concise commit message for these optimizations" \
                --resume "$SESSION_ID" \
                --output-format text \
                --max-turns 1)
            git commit -m "$COMMIT_MSG" || true
        fi
        
        # Clean up backup
        rm "$backup_file"
        
        # Show improvements
        NEW_METRICS=$(analyze_metrics "$file" | xargs cat)
        echo -e "\n${CYAN}Improvements:${NC}"
        echo "  Performance: $(echo "$METRICS" | jq -r '.performance.optimization_potential')% → $(echo "$NEW_METRICS" | jq -r '.performance.optimization_potential')%"
        echo "  Readability: $(echo "$METRICS" | jq -r '.quality.readability_score') → $(echo "$NEW_METRICS" | jq -r '.quality.readability_score')"
        
    else
        echo -e "${YELLOW}⚠️  Optimization skipped (confidence: ${CONFIDENCE}%)${NC}"
        echo "Reasons: $(echo "$VALIDATION" | jq -r '.breaking_changes | join(", ")')"
        
        # Restore original
        mv "$backup_file" "$file"
        rm "${file}.optimized"
    fi
}

# Function to watch for changes
watch_directory() {
    echo -e "${GREEN}👁️  Watching for changes...${NC}"
    echo "Press Ctrl+C to stop"
    
    # Use fswatch if available, otherwise fall back to polling
    if command -v fswatch &> /dev/null; then
        fswatch -r --event Created --event Updated --event Renamed \
            --exclude "\.git" --exclude "node_modules" --exclude "\.backup\." \
            "$TARGET_DIR" | while read event; do
                
            if [[ "$event" =~ \.(js|ts|py|go|java|cpp|c|rs|rb)$ ]]; then
                echo -e "\n${YELLOW}Change detected: $event${NC}"
                optimize_file "$event"
            fi
        done
    else
        # Polling fallback
        while true; do
            find "$TARGET_DIR" -type f \
                \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \
                   -o -name "*.java" -o -name "*.cpp" -o -name "*.c" \) \
                -newer .last_check 2>/dev/null | while read file; do
                optimize_file "$file"
            done
            touch .last_check
            sleep 5
        done
    fi
}

# Function to generate optimization report
generate_report() {
    echo -e "\n${BLUE}📊 Generating optimization report...${NC}"
    
    REPORT_PROMPT=$(cat <<EOF
Generate a comprehensive optimization report for this session including:
1. Files analyzed and optimized
2. Performance improvements achieved
3. Code quality improvements
4. Patterns identified across the codebase
5. Recommendations for architectural improvements
6. Technical debt identified
7. Next steps for further optimization

Format as a detailed markdown report.
EOF
)
    
    REPORT=$(claude -p "$REPORT_PROMPT" \
        --resume "$SESSION_ID" \
        --output-format text \
        --max-turns 2)
    
    REPORT_FILE="optimization-report-$(date +%Y%m%d-%H%M%S).md"
    echo "$REPORT" > "$REPORT_FILE"
    
    echo -e "${GREEN}✅ Report saved to: $REPORT_FILE${NC}"
}

# Main execution
if [ "$WATCH_MODE" = true ]; then
    watch_directory
else
    # Single run mode
    echo -e "${CYAN}Scanning for optimization opportunities...${NC}"
    
    # Find all code files
    FILES=$(find "$TARGET_DIR" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \
           -o -name "*.java" -o -name "*.cpp" -o -name "*.c" -o -name "*.rs" \
           -o -name "*.rb" \) \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/vendor/*" \
        -not -path "*/venv/*")
    
    FILE_COUNT=$(echo "$FILES" | wc -l)
    echo "Found $FILE_COUNT files to analyze"
    
    # Create optimization batch
    CURRENT=0
    echo "$FILES" | while read file; do
        CURRENT=$((CURRENT + 1))
        echo -e "\n${CYAN}[$CURRENT/$FILE_COUNT]${NC} Processing..."
        optimize_file "$file"
    done
    
    # Generate final report
    generate_report
fi

echo -e "\n${GREEN}✨ Optimization complete!${NC}"

# Cleanup
find . -name "metrics-*.json" -mmin +60 -delete 2>/dev/null || true