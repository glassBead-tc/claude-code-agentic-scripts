#!/bin/bash

# Advanced Code Review Script - Uses Claude Code SDK features
# Usage: ./code-review-advanced.sh [branch-name] [options]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
BASE_BRANCH=${1:-main}
OUTPUT_FORMAT=${2:-json}
SESSION_FILE=".claude-review-session"

echo -e "${GREEN}🔍 Advanced Code Review with Claude Code SDK${NC}"

# Get the diff
DIFF=$(git diff $BASE_BRANCH...HEAD)
if [ -z "$DIFF" ]; then
    echo "No changes detected"
    exit 0
fi

# Get list of changed files
CHANGED_FILES=$(git diff --name-only $BASE_BRANCH...HEAD)

# Create comprehensive review prompt
REVIEW_PROMPT=$(cat <<EOF
Perform a comprehensive code review with the following analysis:

Changed files:
$CHANGED_FILES

Please analyze:
1. **Security Issues** - Check for vulnerabilities, hardcoded secrets, injection risks
2. **Performance** - Identify bottlenecks, N+1 queries, inefficient algorithms
3. **Code Quality** - Design patterns, SOLID principles, maintainability
4. **Testing** - Missing tests, edge cases not covered
5. **Breaking Changes** - API compatibility, database migrations needed

For each issue found, provide:
- Severity: Critical/High/Medium/Low
- File and line number
- Specific fix recommendation
- Example code if applicable

Format as JSON with structure:
{
  "summary": "overall assessment",
  "metrics": {
    "security_score": 0-100,
    "quality_score": 0-100,
    "test_coverage_impact": "estimated %"
  },
  "issues": [
    {
      "severity": "...",
      "type": "...",
      "file": "...",
      "line": "...",
      "description": "...",
      "fix": "...",
      "example": "..."
    }
  ],
  "suggestions": ["..."],
  "approved": true/false
}

Diff to review:
\`\`\`diff
$DIFF
\`\`\`
EOF
)

# Run review with advanced SDK features
echo -e "\n${BLUE}Running advanced analysis...${NC}\n"

# First run: Security-focused review
SECURITY_REVIEW=$(claude -p "$REVIEW_PROMPT" \
    --output-format json \
    --system-prompt "You are a security expert. Focus primarily on security vulnerabilities and risks." \
    --max-turns 3 \
    2>/dev/null | jq -r '.result' | jq '.')

# Save session ID for follow-up
SESSION_ID=$(echo "$SECURITY_REVIEW" | jq -r '.session_id // empty')

# Second run: Performance analysis (continuing conversation)
if [ -n "$SESSION_ID" ]; then
    PERFORMANCE_REVIEW=$(claude -p "Now focus on performance implications of these changes" \
        --resume "$SESSION_ID" \
        --output-format json \
        2>/dev/null | jq -r '.result')
fi

# Parse and display results
echo -e "${YELLOW}📊 Review Results:${NC}\n"

# Security Score
SECURITY_SCORE=$(echo "$SECURITY_REVIEW" | jq -r '.metrics.security_score // 0')
QUALITY_SCORE=$(echo "$SECURITY_REVIEW" | jq -r '.metrics.quality_score // 0')

# Color code scores
if [ "$SECURITY_SCORE" -lt 70 ]; then
    SECURITY_COLOR=$RED
elif [ "$SECURITY_SCORE" -lt 85 ]; then
    SECURITY_COLOR=$YELLOW
else
    SECURITY_COLOR=$GREEN
fi

echo -e "Security Score: ${SECURITY_COLOR}${SECURITY_SCORE}/100${NC}"
echo -e "Quality Score: ${BLUE}${QUALITY_SCORE}/100${NC}"
echo

# Critical issues
CRITICAL_COUNT=$(echo "$SECURITY_REVIEW" | jq '[.issues[] | select(.severity == "Critical")] | length')
if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  Found $CRITICAL_COUNT CRITICAL issues:${NC}"
    echo "$SECURITY_REVIEW" | jq -r '.issues[] | select(.severity == "Critical") | "  - \(.file):\(.line) - \(.description)"'
    echo
fi

# Generate fix script if issues found
TOTAL_ISSUES=$(echo "$SECURITY_REVIEW" | jq '.issues | length')
if [ "$TOTAL_ISSUES" -gt 0 ]; then
    echo -e "${YELLOW}🔧 Generating automated fixes...${NC}"
    
    FIX_PROMPT="Based on the review, generate a bash script that automatically fixes the issues where possible. Include git commands to create atomic commits for each fix type."
    
    FIX_SCRIPT=$(claude -p "$FIX_PROMPT" \
        --resume "$SESSION_ID" \
        --output-format text \
        --max-turns 1)
    
    echo "$FIX_SCRIPT" > code-review-fixes.sh
    chmod +x code-review-fixes.sh
    echo -e "${GREEN}✅ Fix script saved to: code-review-fixes.sh${NC}"
fi

# Create detailed report
REPORT_FILE="code-review-$(date +%Y%m%d-%H%M%S).json"
echo "$SECURITY_REVIEW" > "$REPORT_FILE"
echo -e "\n${GREEN}📄 Detailed report saved to: $REPORT_FILE${NC}"

# GitHub PR comment format if running in CI
if [ -n "$GITHUB_ACTIONS" ]; then
    COMMENT=$(claude -p "Convert this review to a GitHub PR comment in Markdown" \
        --resume "$SESSION_ID" \
        --output-format text)
    echo "$COMMENT" > pr-comment.md
fi

# Approval status
APPROVED=$(echo "$SECURITY_REVIEW" | jq -r '.approved // false')
if [ "$APPROVED" = "true" ]; then
    echo -e "\n${GREEN}✅ Code review PASSED${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Code review FAILED - Issues must be addressed${NC}"
    exit 1
fi