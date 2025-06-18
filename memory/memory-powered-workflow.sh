#!/bin/bash

# Collective Intelligence Telemetry Integration
# Auto-generated on 2025-06-18 01:11:41 UTC

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
export COLLECTIVE_SCRIPT_NAME="memory-powered-workflow.sh"

# Original script content below
# ============================================


# Memory-Powered Workflow - Demonstrates advanced memory usage
# Usage: ./memory-powered-workflow.sh [task]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Memory locations
PROJECT_MEMORY="./CLAUDE.md"
USER_MEMORY="$HOME/.claude/CLAUDE.md"
CONTEXT_FILE=".claude-context"

echo -e "${MAGENTA}🧠 Memory-Powered Workflow Automation${NC}"

# Function to create contextual memory
create_contextual_memory() {
    local TASK="$1"
    local CONTEXT_MEMORY=".claude-context-$(date +%s).md"
    
    echo -e "${BLUE}Creating contextual memory for task: $TASK${NC}"
    
    # Gather relevant context
    CONTEXT=$(cat <<EOF
# Temporary Context for: $TASK
_Generated: $(date)_

## Current Task
$TASK

## Relevant Files
$(find . -name "*.js" -o -name "*.ts" -newer .git/FETCH_HEAD 2>/dev/null | head -10 || echo "No recent files")

## Recent Changes
$(git log --oneline -n 5 2>/dev/null || echo "No git history")

## Active Branch
$(git branch --show-current 2>/dev/null || echo "No git repo")

## Environment
- Working Directory: $(pwd)
- Node Version: $(node --version 2>/dev/null || echo "N/A")
- Python Version: $(python --version 2>/dev/null || echo "N/A")

## Task-Specific Instructions
EOF
)
    
    # Add task-specific memory based on task type
    case "$TASK" in
        *test*)
            CONTEXT+="\n- Run tests after changes\n- Ensure coverage > 80%\n- Follow existing test patterns"
            ;;
        *debug*)
            CONTEXT+="\n- Check logs first\n- Use debugger statements\n- Validate assumptions"
            ;;
        *refactor*)
            CONTEXT+="\n- Maintain functionality\n- Improve readability\n- Add comments for complex logic"
            ;;
        *feature*)
            CONTEXT+="\n- Write tests first (TDD)\n- Update documentation\n- Follow project conventions"
            ;;
    esac
    
    echo -e "$CONTEXT" > "$CONTEXT_MEMORY"
    echo "$CONTEXT_MEMORY"
}

# Function to demonstrate memory inheritance
demonstrate_memory_hierarchy() {
    echo -e "\n${CYAN}📚 Memory Hierarchy Demonstration${NC}"
    
    # Create nested project structure
    mkdir -p demo/frontend demo/backend demo/shared
    
    # Create hierarchical memories
    cat > demo/CLAUDE.md << 'EOF'
# Demo Project Memory

## Project Structure
- frontend/ - React application
- backend/ - Node.js API
- shared/ - Common utilities

## General Rules
- Use TypeScript everywhere
- Follow ESLint configuration
- Write tests for all new code
EOF

    cat > demo/frontend/CLAUDE.md << 'EOF'
# Frontend Memory

@../CLAUDE.md

## Frontend Specific
- Use React hooks
- Follow Material-UI patterns
- Component files: *.tsx
- Test files: *.test.tsx
EOF

    cat > demo/backend/CLAUDE.md << 'EOF'
# Backend Memory

@../CLAUDE.md

## Backend Specific
- Use Express.js patterns
- Implement proper error handling
- Use dependency injection
- Follow RESTful conventions
EOF

    # Demonstrate memory lookup
    echo -e "\n${YELLOW}Memory lookup from frontend/:${NC}"
    cd demo/frontend
    
    MEMORY_TEST=$(claude -p "What are the testing requirements for this project?" \
        --output-format text \
        --max-turns 1 2>/dev/null)
    
    echo "$MEMORY_TEST"
    cd ../..
    
    # Cleanup
    rm -rf demo
}

# Function to use memory for automated workflows
memory_powered_task() {
    local TASK="$1"
    
    echo -e "\n${BLUE}🤖 Executing memory-powered task: $TASK${NC}"
    
    # Create contextual memory
    CONTEXT_MEMORY=$(create_contextual_memory "$TASK")
    
    # Build memory-aware prompt
    MEMORY_PROMPT=$(cat <<EOF
# Task Execution with Full Memory Context

## Task
$TASK

## Memory Context
### Project Memory
$(cat "$PROJECT_MEMORY" 2>/dev/null || echo "No project memory")

### User Memory  
$(cat "$USER_MEMORY" 2>/dev/null || echo "No user memory")

### Task Context
$(cat "$CONTEXT_MEMORY")

## Instructions
Execute this task following all memory guidelines and best practices.
Explain each step taken and why (based on memory).
EOF
)
    
    # Execute task with memory context
    RESULT=$(echo "$MEMORY_PROMPT" | claude -p \
        --output-format json \
        --system-prompt "You are an expert developer who strictly follows project memory and conventions." \
        --max-turns 5 \
        2>/dev/null | jq -r '.result')
    
    echo -e "\n${GREEN}Task completed with memory context${NC}"
    
    # Cleanup context
    rm -f "$CONTEXT_MEMORY"
}

# Function to demonstrate memory imports
demonstrate_memory_imports() {
    echo -e "\n${CYAN}🔗 Memory Import Chain Demo${NC}"
    
    # Create import chain
    mkdir -p memory-demo/level1/level2/level3
    
    cat > memory-demo/base.md << 'EOF'
# Base Configuration
- Language: TypeScript
- Testing: Jest
- Linting: ESLint
EOF

    cat > memory-demo/security.md << 'EOF'
# Security Rules
- No hardcoded credentials
- Use environment variables
- Implement rate limiting
EOF

    cat > memory-demo/level1/CLAUDE.md << 'EOF'
# Level 1 Memory

@../base.md
@../security.md

## Additional L1 Rules
- All code must be typed
EOF

    cat > memory-demo/level1/level2/CLAUDE.md << 'EOF'
# Level 2 Memory

@../CLAUDE.md

## Additional L2 Rules
- Use async/await over promises
EOF

    cat > memory-demo/level1/level2/level3/CLAUDE.md << 'EOF'
# Level 3 Memory

@../CLAUDE.md

## Additional L3 Rules
- Maximum function length: 20 lines
- Maximum file length: 200 lines

Note: We inherit all rules from parent levels through imports
EOF

    # Test import chain
    echo -e "\n${YELLOW}Testing 5-hop import chain:${NC}"
    cd memory-demo/level1/level2/level3
    
    IMPORT_TEST=$(claude -p "List all the coding rules I should follow" \
        --output-format text \
        --max-turns 1 2>/dev/null)
    
    echo "$IMPORT_TEST"
    cd ../../../..
    
    # Cleanup
    rm -rf memory-demo
}

# Function to demonstrate memory-based code generation
memory_based_generation() {
    echo -e "\n${CYAN}🏗️  Memory-Based Code Generation${NC}"
    
    # Create a comprehensive memory file
    cat > CLAUDE.md << 'EOF'
# Project Memory for Code Generation

## Architecture
- Pattern: MVC
- Database: PostgreSQL
- ORM: Prisma
- API: RESTful

## Naming Conventions
- Files: kebab-case
- Classes: PascalCase
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE

## Code Style
- Max line length: 100
- Indent: 2 spaces
- Quotes: Single quotes
- Semicolons: Yes

## Testing
- Framework: Jest
- Coverage: Minimum 80%
- Pattern: AAA (Arrange, Act, Assert)

## Error Handling
```typescript
try {
  // operation
} catch (error) {
  logger.error('Context', error);
  throw new AppError('User message', 500);
}
```

## API Response Format
```json
{
  "success": true,
  "data": {},
  "error": null,
  "timestamp": "ISO-8601"
}
```
EOF

    # Generate code following memory
    echo -e "\n${YELLOW}Generating user service following memory...${NC}"
    
    GENERATION_RESULT=$(claude -p "Generate a complete UserService class with CRUD operations" \
        --output-format text \
        --system-prompt "Generate code that strictly follows the project memory guidelines" \
        --max-turns 1)
    
    echo "$GENERATION_RESULT" > generated-user-service.ts
    echo -e "${GREEN}✅ Code generated following memory guidelines${NC}"
    
    # Validate generated code against memory
    VALIDATION=$(claude -p "Validate this generated code against the project memory rules" \
        --output-format json \
        --max-turns 1 <<< "$GENERATION_RESULT" 2>/dev/null | jq -r '.result')
    
    echo -e "\n${BLUE}Validation results:${NC}"
    echo "$VALIDATION" | jq '.'
}

# Main menu
show_menu() {
    echo -e "\n${CYAN}Select a demonstration:${NC}"
    echo "1. Memory Manager (init, add, search)"
    echo "2. Memory Hierarchy Demo"
    echo "3. Memory Import Chain Demo"
    echo "4. Memory-Powered Task Execution"
    echo "5. Memory-Based Code Generation"
    echo "6. Auto-Learning Demo"
    echo "7. Full Workflow Demo"
    echo "8. Exit"
}

# Main execution
if [ -n "$1" ]; then
    # Direct task execution
    memory_powered_task "$1"
else
    # Interactive demo mode
    while true; do
        show_menu
        read -p "Choice: " choice
        
        case $choice in
            1)
                echo -e "\n${GREEN}Initializing memory...${NC}"
                ./memory-manager.sh init
                ./memory-manager.sh add "Always use async/await"
                ./memory-manager.sh search "async"
                ;;
            2)
                demonstrate_memory_hierarchy
                ;;
            3)
                demonstrate_memory_imports
                ;;
            4)
                read -p "Enter task: " task
                memory_powered_task "$task"
                ;;
            5)
                memory_based_generation
                ;;
            6)
                echo -e "\n${GREEN}Running auto-learner...${NC}"
                ./auto-memory-learner.sh
                ;;
            7)
                echo -e "\n${MAGENTA}Full Workflow Demo${NC}"
                ./memory-manager.sh init
                ./auto-memory-learner.sh --learn-from-commits
                memory_powered_task "refactor the main function for better error handling"
                ./memory-manager.sh backup
                ;;
            8)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
    done
fi