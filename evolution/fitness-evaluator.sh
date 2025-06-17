#!/bin/bash

# Fitness Evaluator - Multi-objective fitness evaluation for evolved agents
# Usage: ./fitness-evaluator.sh <agent-id> [--verbose]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
ARCHIVE_DIR="evolution-archive"
SANDBOX_DIR="evolution-sandbox"
BENCHMARK_DIR="fitness-benchmarks"
RESULTS_DIR="fitness-results"
VERBOSE=false

# Parse arguments
AGENT_ID=$1
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Initialize directories
mkdir -p "$SANDBOX_DIR" "$BENCHMARK_DIR" "$RESULTS_DIR"

echo -e "${MAGENTA}🏃 Fitness Evaluator${NC}"

# Function to create test scenarios
create_test_scenarios() {
    echo -e "${BLUE}Creating test scenarios...${NC}"
    
    # Scenario 1: Code Review Challenge
    cat > "$BENCHMARK_DIR/code-review-test.diff" << 'EOF'
diff --git a/auth.js b/auth.js
index 1234567..abcdefg 100644
--- a/auth.js
+++ b/auth.js
@@ -10,7 +10,7 @@ function authenticate(username, password) {
-    const user = db.query(`SELECT * FROM users WHERE username = '${username}'`);
+    const user = db.query("SELECT * FROM users WHERE username = '" + username + "'");
     
-    if (user && user.password === password) {
+    if (user && user.password == password) {
         return { success: true, token: generateToken(user) };
     }
     
+    console.log("Failed login for: " + username + " with password: " + password);
     return { success: false };
 }

+function generateToken(user) {
+    return Math.random().toString(36);
+}
EOF

    # Scenario 2: Test Generation Challenge
    cat > "$BENCHMARK_DIR/function-to-test.js" << 'EOF'
// Complex function that needs comprehensive testing
function processPayment(amount, currency, customer, options = {}) {
    if (!amount || amount <= 0) {
        throw new Error('Invalid amount');
    }
    
    if (!['USD', 'EUR', 'GBP'].includes(currency)) {
        throw new Error('Unsupported currency');
    }
    
    const fee = options.expedited ? amount * 0.03 : amount * 0.01;
    const total = amount + fee;
    
    if (total > customer.balance) {
        return { 
            success: false, 
            error: 'Insufficient funds',
            required: total,
            available: customer.balance
        };
    }
    
    // Process payment...
    return {
        success: true,
        transactionId: Date.now().toString(36),
        amount: amount,
        fee: fee,
        total: total
    };
}
EOF

    # Scenario 3: Bug Finding Challenge
    cat > "$BENCHMARK_DIR/buggy-code.py" << 'EOF'
def merge_lists(list1, list2):
    """Merge two sorted lists into one sorted list"""
    result = []
    i = j = 0
    
    while i < len(list1) and j < len(list2):
        if list1[i] < list2[j]:
            result.append(list1[i])
            i += 1
        else:
            result.append(list2[j])
            j += 1
    
    # Bug: Doesn't handle remaining elements
    return result

def calculate_average(numbers):
    """Calculate average of a list of numbers"""
    # Bug: Division by zero not handled
    return sum(numbers) / len(numbers)

def find_duplicates(items):
    """Find duplicate items in a list"""
    seen = set()
    duplicates = []
    
    for item in items:
        if item in seen:
            duplicates.append(item)  # Bug: Adds duplicates multiple times
        seen.add(item)
    
    return duplicates
EOF

    # Scenario 4: Performance Optimization Challenge
    cat > "$BENCHMARK_DIR/slow-code.js" << 'EOF'
// Inefficient code that needs optimization
function findCommonElements(arr1, arr2) {
    const common = [];
    for (let i = 0; i < arr1.length; i++) {
        for (let j = 0; j < arr2.length; j++) {
            if (arr1[i] === arr2[j] && !common.includes(arr1[i])) {
                common.push(arr1[i]);
            }
        }
    }
    return common;
}

function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

async function processItems(items) {
    const results = [];
    for (const item of items) {
        const processed = await processItem(item);
        results.push(processed);
    }
    return results;
}
EOF
}

# Function to evaluate agent on a specific task
evaluate_task() {
    local AGENT_SCRIPT=$1
    local TASK_TYPE=$2
    local TEST_FILE=$3
    
    echo -e "\n${CYAN}Testing: $TASK_TYPE${NC}"
    
    # Create isolated sandbox
    SANDBOX_TASK="$SANDBOX_DIR/${AGENT_ID}-${TASK_TYPE}"
    rm -rf "$SANDBOX_TASK"
    mkdir -p "$SANDBOX_TASK"
    
    # Copy agent and test file to sandbox
    cp "$AGENT_SCRIPT" "$SANDBOX_TASK/agent.sh"
    cp "$TEST_FILE" "$SANDBOX_TASK/$(basename "$TEST_FILE")"
    
    cd "$SANDBOX_TASK"
    
    # Run agent with timeout
    TIMEOUT_SECONDS=300
    START_TIME=$(date +%s)
    
    # Capture output and errors
    if timeout $TIMEOUT_SECONDS bash agent.sh "$(basename "$TEST_FILE")" > output.log 2> error.log; then
        EXECUTION_SUCCESS=true
    else
        EXECUTION_SUCCESS=false
    fi
    
    END_TIME=$(date +%s)
    EXECUTION_TIME=$((END_TIME - START_TIME))
    
    cd - > /dev/null
    
    # Evaluate results based on task type
    case "$TASK_TYPE" in
        "code-review")
            evaluate_code_review "$SANDBOX_TASK" "$EXECUTION_SUCCESS"
            ;;
        "test-generation")
            evaluate_test_generation "$SANDBOX_TASK" "$EXECUTION_SUCCESS"
            ;;
        "bug-finding")
            evaluate_bug_finding "$SANDBOX_TASK" "$EXECUTION_SUCCESS"
            ;;
        "optimization")
            evaluate_optimization "$SANDBOX_TASK" "$EXECUTION_SUCCESS"
            ;;
    esac
}

# Function to evaluate code review quality
evaluate_code_review() {
    local SANDBOX=$1
    local SUCCESS=$2
    
    if [ "$SUCCESS" != "true" ]; then
        echo "  ❌ Execution failed"
        echo "0" > "$SANDBOX/score.txt"
        return
    fi
    
    # Analyze output for security issues found
    REVIEW_OUTPUT=$(cat "$SANDBOX/output.log" 2>/dev/null || echo "")
    
    EVALUATION_PROMPT=$(cat <<EOF
Evaluate this code review output for the given diff:

Diff reviewed:
$(cat "$BENCHMARK_DIR/code-review-test.diff")

Review output:
$REVIEW_OUTPUT

Score the review (0-100) based on:
1. Did it identify the SQL injection vulnerability? (40 points)
2. Did it catch the password logging issue? (30 points)
3. Did it notice the weak token generation? (20 points)
4. Overall quality and actionability (10 points)

Return JSON:
{
  "score": 0-100,
  "found_sql_injection": true/false,
  "found_password_logging": true/false,
  "found_weak_token": true/false,
  "feedback": "Brief evaluation"
}
EOF
)
    
    EVALUATION=$(claude -p "$EVALUATION_PROMPT" \
        --output-format json \
        --max-turns 1 \
        2>/dev/null | jq -r '.result')
    
    SCORE=$(echo "$EVALUATION" | jq -r '.score // 0')
    echo "$SCORE" > "$SANDBOX/score.txt"
    echo "$EVALUATION" > "$SANDBOX/evaluation.json"
    
    if [ "$VERBOSE" = true ]; then
        echo "  Score: $SCORE/100"
        echo "  SQL Injection found: $(echo "$EVALUATION" | jq -r '.found_sql_injection')"
        echo "  Password logging found: $(echo "$EVALUATION" | jq -r '.found_password_logging')"
    else
        echo "  Score: $SCORE/100"
    fi
}

# Function to evaluate test generation quality
evaluate_test_generation() {
    local SANDBOX=$1
    local SUCCESS=$2
    
    if [ "$SUCCESS" != "true" ]; then
        echo "  ❌ Execution failed"
        echo "0" > "$SANDBOX/score.txt"
        return
    fi
    
    TEST_OUTPUT=$(cat "$SANDBOX/output.log" 2>/dev/null || echo "")
    
    EVALUATION_PROMPT=$(cat <<EOF
Evaluate these generated tests for the payment processing function:

Original function:
$(cat "$BENCHMARK_DIR/function-to-test.js")

Generated tests:
$TEST_OUTPUT

Score (0-100) based on:
1. Coverage of edge cases (invalid amount, unsupported currency) (30 points)
2. Testing the fee calculation logic (20 points)
3. Testing insufficient funds scenario (20 points)
4. Test quality and assertions (20 points)
5. Code organization and clarity (10 points)

Return JSON:
{
  "score": 0-100,
  "edge_cases_covered": ["list of covered cases"],
  "missing_cases": ["list of missing cases"],
  "test_count": number,
  "quality_assessment": "brief assessment"
}
EOF
)
    
    EVALUATION=$(claude -p "$EVALUATION_PROMPT" \
        --output-format json \
        --max-turns 1 \
        2>/dev/null | jq -r '.result')
    
    SCORE=$(echo "$EVALUATION" | jq -r '.score // 0')
    echo "$SCORE" > "$SANDBOX/score.txt"
    echo "$EVALUATION" > "$SANDBOX/evaluation.json"
    
    echo "  Score: $SCORE/100"
    if [ "$VERBOSE" = true ]; then
        echo "  Test count: $(echo "$EVALUATION" | jq -r '.test_count // 0')"
        echo "  Quality: $(echo "$EVALUATION" | jq -r '.quality_assessment // "Unknown"')"
    fi
}

# Function to evaluate bug finding capability
evaluate_bug_finding() {
    local SANDBOX=$1
    local SUCCESS=$2
    
    if [ "$SUCCESS" != "true" ]; then
        echo "  ❌ Execution failed"
        echo "0" > "$SANDBOX/score.txt"
        return
    fi
    
    BUG_OUTPUT=$(cat "$SANDBOX/output.log" 2>/dev/null || echo "")
    
    EVALUATION_PROMPT=$(cat <<EOF
Evaluate this bug finding output:

Code analyzed:
$(cat "$BENCHMARK_DIR/buggy-code.py")

Bugs found:
$BUG_OUTPUT

Score (0-100) based on:
1. Found missing elements bug in merge_lists (35 points)
2. Found division by zero in calculate_average (35 points)
3. Found duplicate duplicates in find_duplicates (20 points)
4. Quality of explanations and fixes (10 points)

Return JSON:
{
  "score": 0-100,
  "bugs_found": ["bug1", "bug2"],
  "bugs_missed": ["bug3"],
  "false_positives": number,
  "fix_quality": "high|medium|low"
}
EOF
)
    
    EVALUATION=$(claude -p "$EVALUATION_PROMPT" \
        --output-format json \
        --max-turns 1 \
        2>/dev/null | jq -r '.result')
    
    SCORE=$(echo "$EVALUATION" | jq -r '.score // 0')
    echo "$SCORE" > "$SANDBOX/score.txt"
    echo "$EVALUATION" > "$SANDBOX/evaluation.json"
    
    echo "  Score: $SCORE/100"
    if [ "$VERBOSE" = true ]; then
        echo "  Bugs found: $(echo "$EVALUATION" | jq -r '.bugs_found | length // 0')"
        echo "  Fix quality: $(echo "$EVALUATION" | jq -r '.fix_quality // "Unknown"')"
    fi
}

# Function to evaluate optimization capability
evaluate_optimization() {
    local SANDBOX=$1
    local SUCCESS=$2
    
    if [ "$SUCCESS" != "true" ]; then
        echo "  ❌ Execution failed"
        echo "0" > "$SANDBOX/score.txt"
        return
    fi
    
    OPT_OUTPUT=$(cat "$SANDBOX/output.log" 2>/dev/null || echo "")
    
    EVALUATION_PROMPT=$(cat <<EOF
Evaluate these optimization suggestions:

Original code:
$(cat "$BENCHMARK_DIR/slow-code.js")

Optimization output:
$OPT_OUTPUT

Score (0-100) based on:
1. Optimized O(n²) to O(n) in findCommonElements using Set (35 points)
2. Suggested memoization for fibonacci (30 points)
3. Suggested parallel processing for processItems (25 points)
4. Quality and correctness of optimizations (10 points)

Return JSON:
{
  "score": 0-100,
  "optimizations_found": ["opt1", "opt2"],
  "complexity_improvements": {"function": "before->after"},
  "correctness": "verified|likely|uncertain",
  "innovation": "high|medium|low"
}
EOF
)
    
    EVALUATION=$(claude -p "$EVALUATION_PROMPT" \
        --output-format json \
        --max-turns 1 \
        2>/dev/null | jq -r '.result')
    
    SCORE=$(echo "$EVALUATION" | jq -r '.score // 0')
    echo "$SCORE" > "$SANDBOX/score.txt"
    echo "$EVALUATION" > "$SANDBOX/evaluation.json"
    
    echo "  Score: $SCORE/100"
    if [ "$VERBOSE" = true ]; then
        echo "  Optimizations: $(echo "$EVALUATION" | jq -r '.optimizations_found | length // 0')"
        echo "  Innovation: $(echo "$EVALUATION" | jq -r '.innovation // "Unknown"')"
    fi
}

# Function to calculate multi-objective fitness
calculate_fitness() {
    local AGENT_ID=$1
    
    echo -e "\n${YELLOW}Calculating multi-objective fitness...${NC}"
    
    # Aggregate scores from all tasks
    TOTAL_SCORE=0
    TASK_COUNT=0
    
    for task_dir in "$SANDBOX_DIR/${AGENT_ID}-"*; do
        if [ -f "$task_dir/score.txt" ]; then
            SCORE=$(cat "$task_dir/score.txt")
            TOTAL_SCORE=$((TOTAL_SCORE + SCORE))
            TASK_COUNT=$((TASK_COUNT + 1))
        fi
    done
    
    # Calculate average performance
    if [ $TASK_COUNT -gt 0 ]; then
        AVG_PERFORMANCE=$((TOTAL_SCORE / TASK_COUNT))
    else
        AVG_PERFORMANCE=0
    fi
    
    # Calculate novelty score (simplified - would compare to population)
    NOVELTY_SCORE=$((RANDOM % 30 + 20))
    
    # Calculate efficiency (based on execution time)
    EFFICIENCY_SCORE=80  # Simplified
    
    # Calculate safety score (no errors, sandboxed properly)
    SAFETY_SCORE=90  # Simplified
    
    # Multi-objective fitness
    FITNESS_REPORT=$(cat <<EOF
{
  "agent_id": "$AGENT_ID",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "scores": {
    "performance": $AVG_PERFORMANCE,
    "novelty": $NOVELTY_SCORE,
    "efficiency": $EFFICIENCY_SCORE,
    "safety": $SAFETY_SCORE
  },
  "overall_fitness": $(( (AVG_PERFORMANCE * 40 + NOVELTY_SCORE * 30 + EFFICIENCY_SCORE * 20 + SAFETY_SCORE * 10) / 100 )),
  "task_results": {
    "code_review": $(cat "$SANDBOX_DIR/${AGENT_ID}-code-review/score.txt" 2>/dev/null || echo 0),
    "test_generation": $(cat "$SANDBOX_DIR/${AGENT_ID}-test-generation/score.txt" 2>/dev/null || echo 0),
    "bug_finding": $(cat "$SANDBOX_DIR/${AGENT_ID}-bug-finding/score.txt" 2>/dev/null || echo 0),
    "optimization": $(cat "$SANDBOX_DIR/${AGENT_ID}-optimization/score.txt" 2>/dev/null || echo 0)
  }
}
EOF
)
    
    # Save fitness report
    echo "$FITNESS_REPORT" > "$RESULTS_DIR/${AGENT_ID}-fitness.json"
    
    # Update agent metadata with fitness
    if [ -f "$ARCHIVE_DIR/${AGENT_ID}.meta.json" ]; then
        UPDATED_META=$(jq ".fitness_scores = $(echo "$FITNESS_REPORT" | jq '.scores')" "$ARCHIVE_DIR/${AGENT_ID}.meta.json")
        echo "$UPDATED_META" > "$ARCHIVE_DIR/${AGENT_ID}.meta.json"
    fi
    
    echo -e "\n${GREEN}Overall Fitness Score: $(echo "$FITNESS_REPORT" | jq -r '.overall_fitness')${NC}"
    
    # Display results
    echo -e "\n${CYAN}Fitness Breakdown:${NC}"
    echo "  Performance: $AVG_PERFORMANCE/100"
    echo "  Novelty: $NOVELTY_SCORE/100"
    echo "  Efficiency: $EFFICIENCY_SCORE/100"
    echo "  Safety: $SAFETY_SCORE/100"
}

# Main evaluation flow
main() {
    if [ -z "$AGENT_ID" ]; then
        echo "Usage: $0 <agent-id> [--verbose]"
        exit 1
    fi
    
    AGENT_SCRIPT="$ARCHIVE_DIR/${AGENT_ID}.sh"
    
    if [ ! -f "$AGENT_SCRIPT" ]; then
        echo "Error: Agent script not found: $AGENT_SCRIPT"
        exit 1
    fi
    
    echo "Evaluating agent: $AGENT_ID"
    
    # Create test scenarios
    create_test_scenarios
    
    # Run evaluations
    evaluate_task "$AGENT_SCRIPT" "code-review" "$BENCHMARK_DIR/code-review-test.diff"
    evaluate_task "$AGENT_SCRIPT" "test-generation" "$BENCHMARK_DIR/function-to-test.js"
    evaluate_task "$AGENT_SCRIPT" "bug-finding" "$BENCHMARK_DIR/buggy-code.py"
    evaluate_task "$AGENT_SCRIPT" "optimization" "$BENCHMARK_DIR/slow-code.js"
    
    # Calculate overall fitness
    calculate_fitness "$AGENT_ID"
    
    # Cleanup sandboxes (keep for debugging if verbose)
    if [ "$VERBOSE" != true ]; then
        rm -rf "$SANDBOX_DIR/${AGENT_ID}-"*
    fi
}

main