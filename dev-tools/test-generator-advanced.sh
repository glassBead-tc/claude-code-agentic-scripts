#!/bin/bash

# Collective Intelligence Telemetry Integration
# Auto-generated on 2025-06-18 01:11:42 UTC

# Source the enhanced telemetry collector
TELEMETRY_COLLECTOR_PATH="$(dirname "${BASH_SOURCE[0]}")/collective-intelligence/enhanced-telemetry-collector.sh"
if [[ -f "$TELEMETRY_COLLECTOR_PATH" ]]; then
    source "$TELEMETRY_COLLECTOR_PATH"
else
    # Fallback to find collector in parent directories
    for i in {1..5}; do
        TELEMETRY_COLLECTOR_PATH="$(dirname "${BASH_SOURCE[0]}")$(printf '/..'%.0s {1..$i})/collective-intelligence/enhanced-telemetry-collector.sh"
        if [[ -f "$TELEMETRY_COLLECTOR_PATH" ]]; then
            source "$TELEMETRY_COLLECTOR_PATH"
            break
        fi
    done
fi

# Set script name for telemetry
export COLLECTIVE_SCRIPT_NAME="test-generator-advanced.sh"

# Original script content below
# ============================================


# Advanced Test Generator with Coverage Analysis
# Usage: ./test-generator-advanced.sh <file-path> [--framework jest|pytest|mocha] [--style tdd|bdd]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
FILE_PATH=$1
FRAMEWORK=""
STYLE="tdd"
COVERAGE_THRESHOLD=80

# Parse optional arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --framework)
            FRAMEWORK="$2"
            shift 2
            ;;
        --style)
            STYLE="$2"
            shift 2
            ;;
        --coverage)
            COVERAGE_THRESHOLD="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

echo -e "${BLUE}🧪 Advanced Test Generation with Claude Code SDK${NC}"
echo "File: $FILE_PATH"

# Detect language and framework if not specified
FILE_EXT="${FILE_PATH##*.}"
FILE_CONTENT=$(cat "$FILE_PATH")

# Auto-detect framework
if [ -z "$FRAMEWORK" ]; then
    DETECT_PROMPT="Detect the most appropriate testing framework for this file based on the language and any existing test files in the project. Return only the framework name (jest, pytest, mocha, junit, rspec, etc.)"
    
    FRAMEWORK=$(claude -p "$DETECT_PROMPT" \
        --output-format text \
        --max-turns 1 <<< "$FILE_CONTENT")
    
    echo -e "${CYAN}Detected framework: $FRAMEWORK${NC}"
fi

# Analyze code complexity first
echo -e "\n${YELLOW}Analyzing code complexity...${NC}"

COMPLEXITY_PROMPT=$(cat <<EOF
Analyze this code and provide a JSON report:
{
  "complexity": {
    "cyclomatic": number,
    "cognitive": number,
    "lines_of_code": number,
    "number_of_functions": number
  },
  "functions": [
    {
      "name": "function_name",
      "complexity": number,
      "parameters": ["param1", "param2"],
      "return_type": "type",
      "edge_cases": ["case1", "case2"],
      "dependencies": ["dep1", "dep2"]
    }
  ],
  "test_recommendations": {
    "unit_tests_needed": number,
    "integration_tests_needed": number,
    "edge_cases_to_cover": ["case1", "case2"]
  }
}

Code to analyze:
\`\`\`
$FILE_CONTENT
\`\`\`
EOF
)

COMPLEXITY_REPORT=$(claude -p "$COMPLEXITY_PROMPT" \
    --output-format json \
    --system-prompt "You are a code analysis expert. Provide accurate metrics." \
    --max-turns 1 \
    2>/dev/null | jq -r '.result' | jq '.')

# Save session for incremental test generation
SESSION_ID=$(claude -p "Starting test generation session for $FILE_PATH" \
    --output-format json \
    2>/dev/null | jq -r '.session_id')

# Display complexity report
echo -e "${CYAN}Code Complexity Report:${NC}"
echo "$COMPLEXITY_REPORT" | jq -r '
    "  Cyclomatic Complexity: \(.complexity.cyclomatic)",
    "  Functions to test: \(.functions | length)",
    "  Recommended unit tests: \(.test_recommendations.unit_tests_needed)",
    "  Edge cases identified: \(.test_recommendations.edge_cases_to_cover | length)"'

# Generate tests for each function
echo -e "\n${GREEN}Generating comprehensive tests...${NC}\n"

# Create test file name
TEST_FILE="${FILE_PATH%.*}.test.${FILE_EXT}"
if [[ "$FRAMEWORK" == "pytest" ]]; then
    TEST_FILE="test_${FILE_PATH##*/}"
fi

# Generate test structure
TEST_GENERATION_PROMPT=$(cat <<EOF
Generate comprehensive $FRAMEWORK tests in $STYLE style for this code.

Requirements:
1. Test each function with:
   - Happy path tests
   - Edge cases: $(echo "$COMPLEXITY_REPORT" | jq -r '.test_recommendations.edge_cases_to_cover | join(", ")')
   - Error handling
   - Boundary conditions
   - Type validation (if applicable)

2. Include:
   - Setup and teardown methods
   - Mocking for external dependencies
   - Parameterized tests for multiple scenarios
   - Performance tests for critical functions
   - Integration tests if applicable

3. Achieve at least $COVERAGE_THRESHOLD% code coverage

4. Follow $FRAMEWORK best practices and conventions

Code to test:
\`\`\`
$FILE_CONTENT
\`\`\`

Complexity analysis:
$COMPLEXITY_REPORT
EOF
)

# Generate initial tests
TESTS=$(claude -p "$TEST_GENERATION_PROMPT" \
    --resume "$SESSION_ID" \
    --output-format text \
    --system-prompt "You are an expert test engineer. Generate production-quality tests that catch real bugs." \
    --max-turns 3)

# Write tests to file
echo "$TESTS" > "$TEST_FILE"
echo -e "${GREEN}✅ Tests written to: $TEST_FILE${NC}"

# Generate test data fixtures
echo -e "\n${YELLOW}Generating test fixtures...${NC}"

FIXTURE_PROMPT="Based on the tests generated, create comprehensive test data fixtures including edge cases, invalid inputs, and performance test data. Format as $FRAMEWORK fixtures."

FIXTURES=$(claude -p "$FIXTURE_PROMPT" \
    --resume "$SESSION_ID" \
    --output-format text \
    --max-turns 1)

# Write fixtures
FIXTURE_FILE="${FILE_PATH%.*}.fixtures.${FILE_EXT}"
echo "$FIXTURES" > "$FIXTURE_FILE"
echo -e "${GREEN}✅ Fixtures written to: $FIXTURE_FILE${NC}"

# Generate mutation tests
echo -e "\n${CYAN}Generating mutation tests...${NC}"

MUTATION_PROMPT="Generate mutation testing scenarios to verify test quality. List mutations that should be caught by the tests."

MUTATIONS=$(claude -p "$MUTATION_PROMPT" \
    --resume "$SESSION_ID" \
    --output-format json \
    --max-turns 1 \
    2>/dev/null | jq -r '.result')

# Create test runner script
echo -e "\n${BLUE}Creating test runner script...${NC}"

RUNNER_SCRIPT=$(cat <<'EOF'
#!/bin/bash
# Auto-generated test runner

set -e

echo "Running tests for: $1"

# Detect and run appropriate test framework
if command -v jest &> /dev/null && [[ "$2" == "jest" ]]; then
    jest "$1" --coverage --coverageThreshold='{"global":{"lines":80}}'
elif command -v pytest &> /dev/null && [[ "$2" == "pytest" ]]; then
    pytest "$1" -v --cov --cov-report=term-missing --cov-fail-under=80
elif command -v mocha &> /dev/null && [[ "$2" == "mocha" ]]; then
    nyc --reporter=text --check-coverage --lines 80 mocha "$1"
else
    echo "No test runner found for framework: $2"
    exit 1
fi

# Run mutation testing if available
if command -v stryker &> /dev/null; then
    echo "Running mutation tests..."
    stryker run
fi
EOF
)

echo "$RUNNER_SCRIPT" > run-tests.sh
chmod +x run-tests.sh

# Generate coverage report
echo -e "\n${GREEN}📊 Test Generation Summary:${NC}"
echo -e "  Test file: $TEST_FILE"
echo -e "  Fixture file: $FIXTURE_FILE"
echo -e "  Test runner: run-tests.sh"
echo -e "  Framework: $FRAMEWORK"
echo -e "  Style: $STYLE"
echo -e "  Functions tested: $(echo "$COMPLEXITY_REPORT" | jq -r '.functions | length')"
echo -e "  Total test cases: $(grep -c "test\|it(" "$TEST_FILE" 2>/dev/null || echo "N/A")"

# Provide test execution command
echo -e "\n${CYAN}To run tests:${NC}"
echo "  ./run-tests.sh $TEST_FILE $FRAMEWORK"

# Create GitHub Actions workflow if requested
if [ -n "$GITHUB_ACTIONS" ]; then
    WORKFLOW=$(claude -p "Generate GitHub Actions workflow for running these $FRAMEWORK tests with coverage reporting" \
        --resume "$SESSION_ID" \
        --output-format text)
    
    mkdir -p .github/workflows
    echo "$WORKFLOW" > .github/workflows/test-generated.yml
    echo -e "\n${GREEN}✅ GitHub Actions workflow created${NC}"
fi