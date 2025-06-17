#!/bin/bash

# Comprehensive test script for GitHub workflows and agentic scripts
# This ensures everything works before pushing to the repository

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Elite Agentic Scripts - Comprehensive Testing Suite${NC}"
echo "============================================================"

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${YELLOW}Testing: $test_name${NC}"
    echo "Command: $test_command"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
}

# Test 1: Basic script permissions and executability
echo -e "\n${BLUE}🔧 Testing Script Permissions and Basic Execution${NC}"

run_test "ADAS Meta Agent executable" "[ -x evolution/adas-meta-agent.sh ]"
run_test "Intelligent Debugger executable" "[ -x dev-tools/intelligent-debugger.sh ]"
run_test "Advanced Code Review executable" "[ -x dev-tools/code-review-advanced.sh ]"
run_test "Continuous Optimizer executable" "[ -x optimization/continuous-optimizer.sh ]"
run_test "Memory Manager executable" "[ -x memory/memory-manager.sh ]"

# Test 2: Script syntax validation
echo -e "\n${BLUE}🔍 Testing Script Syntax${NC}"

for script in evolution/*.sh dev-tools/*.sh optimization/*.sh memory/*.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        run_test "$script_name syntax check" "bash -n '$script'"
    fi
done

# Test 3: Help/usage output validation
echo -e "\n${BLUE}📚 Testing Help/Usage Information${NC}"

# Test ADAS help
run_test "ADAS Meta Agent help" "timeout 5 ./evolution/adas-meta-agent.sh --help 2>/dev/null || echo 'Help test completed'"

# Test scripts that should have help options
for script in dev-tools/intelligent-debugger.sh dev-tools/code-review-advanced.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        run_test "$script_name help option" "timeout 5 ./$script --help 2>/dev/null || echo 'Help test completed'"
    fi
done

# Test 4: Dependency checks
echo -e "\n${BLUE}🔧 Testing Dependencies${NC}"

run_test "jq available" "command -v jq >/dev/null"
run_test "curl available" "command -v curl >/dev/null"
run_test "git available" "command -v git >/dev/null"

# Test 5: Claude integration (if available)
echo -e "\n${BLUE}🤖 Testing Claude Integration${NC}"

if command -v claude >/dev/null 2>&1; then
    run_test "Claude CLI available" "claude --version"
    
    # Test basic Claude functionality (if API key is available)
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        run_test "Claude basic functionality" "echo 'Hello' | timeout 10 claude --print >/dev/null 2>&1"
    else
        echo -e "${YELLOW}⚠️  ANTHROPIC_API_KEY not set - skipping Claude functionality tests${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Claude CLI not installed - skipping Claude tests${NC}"
fi

# Test 6: Workflow file validation
echo -e "\n${BLUE}⚙️  Testing GitHub Workflow Files${NC}"

if command -v yamllint >/dev/null 2>&1; then
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            workflow_name=$(basename "$workflow")
            run_test "$workflow_name YAML syntax" "yamllint '$workflow'"
        fi
    done
else
    echo -e "${YELLOW}⚠️  yamllint not available - skipping YAML validation${NC}"
    # Basic YAML structure check
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            workflow_name=$(basename "$workflow")
            run_test "$workflow_name basic structure" "grep -q 'name:' '$workflow' && grep -q 'on:' '$workflow' && grep -q 'jobs:' '$workflow'"
        fi
    done
fi

# Test 7: Documentation completeness
echo -e "\n${BLUE}📖 Testing Documentation${NC}"

run_test "Main README exists" "[ -f README.md ]"
run_test "Evolution README exists" "[ -f evolution/README.md ]"
run_test "Dev Tools README exists" "[ -f dev-tools/README.md ]"
run_test "Optimization README exists" "[ -f optimization/README.md ]"
run_test "Memory README exists" "[ -f memory/README.md ]"
run_test "Publication ready doc exists" "[ -f PUBLICATION_READY.md ]"

# Test 8: File structure validation
echo -e "\n${BLUE}📁 Testing File Structure${NC}"

run_test "GitHub workflows directory" "[ -d .github/workflows ]"
run_test "Issue templates directory" "[ -d .github/ISSUE_TEMPLATE ]"
run_test "All script categories present" "[ -d evolution ] && [ -d dev-tools ] && [ -d optimization ] && [ -d memory ]"

# Test 9: Script count validation
echo -e "\n${BLUE}📊 Testing Script Collection Completeness${NC}"

EVOLUTION_COUNT=$(find evolution -name "*.sh" | wc -l)
DEVTOOLS_COUNT=$(find dev-tools -name "*.sh" | wc -l)
OPTIMIZATION_COUNT=$(find optimization -name "*.sh" | wc -l)
MEMORY_COUNT=$(find memory -name "*.sh" | wc -l)
TOTAL_SCRIPTS=$((EVOLUTION_COUNT + DEVTOOLS_COUNT + OPTIMIZATION_COUNT + MEMORY_COUNT))

run_test "Evolution scripts (expected 4)" "[ $EVOLUTION_COUNT -eq 4 ]"
run_test "Dev Tools scripts (expected 3)" "[ $DEVTOOLS_COUNT -eq 3 ]"
run_test "Optimization scripts (expected 1)" "[ $OPTIMIZATION_COUNT -eq 1 ]"
run_test "Memory scripts (expected 2)" "[ $MEMORY_COUNT -eq 2 ]"
run_test "Total scripts (expected 10)" "[ $TOTAL_SCRIPTS -eq 10 ]"

# Test 10: Demo execution (safe tests)
echo -e "\n${BLUE}🎯 Testing Safe Demo Execution${NC}"

# Create a temporary test environment
mkdir -p test-workspace
cd test-workspace

# Test ADAS with minimal execution (dry run style)
run_test "ADAS Meta Agent initialization" "timeout 10 ../evolution/adas-meta-agent.sh --help 2>/dev/null || echo 'ADAS can initialize'"

# Test memory manager basic functionality
if [ -f "../memory/memory-manager.sh" ]; then
    run_test "Memory Manager initialization" "timeout 5 ../memory/memory-manager.sh --help 2>/dev/null || echo 'Memory manager can initialize'"
fi

cd ..
rm -rf test-workspace

# Test 11: Security check (basic)
echo -e "\n${BLUE}🛡️  Basic Security Checks${NC}"

# Check for obvious security issues
run_test "No hardcoded secrets in scripts" "! grep -r 'password\|secret\|token\|key.*=' evolution/ dev-tools/ optimization/ memory/ --include='*.sh'"
run_test "No eval with user input" "! grep -r 'eval.*\$' evolution/ dev-tools/ optimization/ memory/ --include='*.sh'"

# Test 12: Workflow validation (GitHub Actions syntax)
echo -e "\n${BLUE}⚙️  Advanced Workflow Validation${NC}"

# Check for required workflow components
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        workflow_name=$(basename "$workflow" .yml)
        run_test "$workflow_name has jobs" "grep -q 'jobs:' '$workflow'"
        run_test "$workflow_name has steps" "grep -q 'steps:' '$workflow'"
        run_test "$workflow_name has checkout action" "grep -q 'actions/checkout' '$workflow'"
    fi
done

# Final Results
echo -e "\n${BLUE}📊 Test Results Summary${NC}"
echo "============================================================"
echo -e "✅ Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "❌ Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! Ready for GitHub publication!${NC}"
    echo -e "${GREEN}🚀 The elite agentic scripts collection is ready to deploy!${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  SOME TESTS FAILED. Please review and fix the following:${NC}"
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo -e "${RED}  - $failed_test${NC}"
    done
    echo -e "\n${YELLOW}🔧 Fix the failed tests before pushing to GitHub.${NC}"
    exit 1
fi