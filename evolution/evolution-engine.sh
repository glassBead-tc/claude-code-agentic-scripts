#!/bin/bash

# Evolution Engine - Evolutionary system for agentic scripts
# Inspired by Darwin Gödel Machine principles
# Usage: ./evolution-engine.sh [command] [options]

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
LINEAGE_FILE="lineage.json"
GENERATION_FILE="current-generation.json"
MAX_POPULATION=50
MUTATION_RATE=0.3
CROSSOVER_RATE=0.5

# Initialize directories
mkdir -p "$ARCHIVE_DIR" "$SANDBOX_DIR"

echo -e "${MAGENTA}🧬 Claude Code Evolution Engine${NC}"

# Initialize evolution tracking
init_evolution() {
    echo -e "${BLUE}Initializing evolution system...${NC}"
    
    # Create initial lineage file
    if [ ! -f "$LINEAGE_FILE" ]; then
        cat > "$LINEAGE_FILE" << EOF
{
  "generation": 0,
  "total_agents": 0,
  "best_fitness": 0,
  "lineage_tree": {},
  "discoveries": []
}
EOF
    fi
    
    # Seed initial population with existing scripts
    echo -e "${YELLOW}Seeding initial population...${NC}"
    
    INITIAL_SCRIPTS=$(find . -name "*.sh" -type f | grep -E "(code-review|test-generator|bug-finder|doc-generator)" | head -10)
    
    GENERATION=0
    for script in $INITIAL_SCRIPTS; do
        if [ -f "$script" ]; then
            AGENT_ID="agent-gen${GENERATION}-$(uuidgen | cut -d'-' -f1)"
            
            # Create agent metadata
            AGENT_META=$(cat <<EOF
{
  "id": "$AGENT_ID",
  "generation": $GENERATION,
  "parent_ids": [],
  "script_path": "$script",
  "creation_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "mutations": [],
  "fitness_scores": {},
  "capabilities": []
}
EOF
)
            
            # Archive agent
            cp "$script" "$ARCHIVE_DIR/${AGENT_ID}.sh"
            echo "$AGENT_META" > "$ARCHIVE_DIR/${AGENT_ID}.meta.json"
            
            echo "  Archived: $(basename "$script") as $AGENT_ID"
        fi
    done
    
    echo -e "${GREEN}✅ Evolution system initialized${NC}"
}

# Function to mutate a script
mutate_script() {
    local PARENT_ID=$1
    local PARENT_SCRIPT="$ARCHIVE_DIR/${PARENT_ID}.sh"
    local PARENT_META="$ARCHIVE_DIR/${PARENT_ID}.meta.json"
    
    if [ ! -f "$PARENT_SCRIPT" ]; then
        echo "Parent script not found: $PARENT_ID"
        return 1
    fi
    
    echo -e "${CYAN}🧪 Mutating agent: $PARENT_ID${NC}"
    
    # Read parent metadata
    PARENT_GENERATION=$(jq -r '.generation' "$PARENT_META")
    NEW_GENERATION=$((PARENT_GENERATION + 1))
    
    # Generate mutation prompt
    MUTATION_PROMPT=$(cat <<EOF
Analyze this script and propose an evolutionary improvement:

Current Script:
$(cat "$PARENT_SCRIPT")

Parent Metadata:
$(cat "$PARENT_META")

Propose ONE specific mutation that could:
1. Improve performance or efficiency
2. Add a new capability
3. Better integrate with Claude Code SDK
4. Enhance error handling or robustness
5. Discover a novel approach

The mutation should be:
- Meaningful (not just cosmetic)
- Safe (no destructive operations)
- Testable (measurable improvement)
- Building on parent's strengths

Output the complete mutated script.
EOF
)
    
    # Generate mutation using Claude
    MUTATED_SCRIPT=$(claude -p "$MUTATION_PROMPT" \
        --output-format text \
        --system-prompt "You are an expert at evolutionary programming. Make meaningful improvements while maintaining core functionality." \
        --max-turns 2)
    
    # Create new agent
    NEW_AGENT_ID="agent-gen${NEW_GENERATION}-$(uuidgen | cut -d'-' -f1)"
    
    # Detect what changed
    MUTATION_ANALYSIS=$(cat <<EOF | claude -p --output-format json --max-turns 1
Compare these scripts and identify the key mutation:

Original:
$(cat "$PARENT_SCRIPT")

Mutated:
$MUTATED_SCRIPT

Return JSON:
{
  "mutation_type": "feature_addition|optimization|refactoring|novel_approach",
  "description": "Brief description of the change",
  "expected_improvement": "What this mutation should improve",
  "risk_level": "low|medium|high"
}
EOF
)
    
    # Create agent metadata
    AGENT_META=$(cat <<EOF
{
  "id": "$NEW_AGENT_ID",
  "generation": $NEW_GENERATION,
  "parent_ids": ["$PARENT_ID"],
  "script_path": "$ARCHIVE_DIR/${NEW_AGENT_ID}.sh",
  "creation_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "mutations": [$(echo "$MUTATION_ANALYSIS" | jq -r '.result')],
  "fitness_scores": {},
  "capabilities": []
}
EOF
)
    
    # Save mutated agent
    echo "$MUTATED_SCRIPT" > "$ARCHIVE_DIR/${NEW_AGENT_ID}.sh"
    chmod +x "$ARCHIVE_DIR/${NEW_AGENT_ID}.sh"
    echo "$AGENT_META" > "$ARCHIVE_DIR/${NEW_AGENT_ID}.meta.json"
    
    echo -e "${GREEN}✅ Created mutant: $NEW_AGENT_ID${NC}"
    echo "Mutation: $(echo "$MUTATION_ANALYSIS" | jq -r '.result.description' 2>/dev/null || echo "Unknown")"
    
    echo "$NEW_AGENT_ID"
}

# Function to crossover two scripts
crossover_scripts() {
    local PARENT1_ID=$1
    local PARENT2_ID=$2
    
    echo -e "${CYAN}🔀 Crossover: $PARENT1_ID × $PARENT2_ID${NC}"
    
    # Read parent scripts and metadata
    PARENT1_SCRIPT=$(cat "$ARCHIVE_DIR/${PARENT1_ID}.sh")
    PARENT2_SCRIPT=$(cat "$ARCHIVE_DIR/${PARENT2_ID}.sh")
    PARENT1_META=$(cat "$ARCHIVE_DIR/${PARENT1_ID}.meta.json")
    PARENT2_META=$(cat "$ARCHIVE_DIR/${PARENT2_ID}.meta.json")
    
    # Determine generation
    GEN1=$(jq -r '.generation' "$ARCHIVE_DIR/${PARENT1_ID}.meta.json")
    GEN2=$(jq -r '.generation' "$ARCHIVE_DIR/${PARENT2_ID}.meta.json")
    NEW_GENERATION=$(( (GEN1 > GEN2 ? GEN1 : GEN2) + 1 ))
    
    # Generate crossover
    CROSSOVER_PROMPT=$(cat <<EOF
Perform genetic crossover between these two scripts, combining their best features:

Parent 1 (${PARENT1_ID}):
$PARENT1_SCRIPT

Parent 1 Capabilities:
$(echo "$PARENT1_META" | jq -r '.capabilities | join(", ")' 2>/dev/null || echo "Unknown")

Parent 2 (${PARENT2_ID}):
$PARENT2_SCRIPT

Parent 2 Capabilities:
$(echo "$PARENT2_META" | jq -r '.capabilities | join(", ")' 2>/dev/null || echo "Unknown")

Create a child script that:
1. Inherits strengths from both parents
2. Combines complementary features
3. Resolves any conflicts intelligently
4. Maintains coherent functionality

Output the complete child script.
EOF
)
    
    CHILD_SCRIPT=$(claude -p "$CROSSOVER_PROMPT" \
        --output-format text \
        --system-prompt "You are an expert at genetic programming. Combine the best features while ensuring the result is functional and improved." \
        --max-turns 2)
    
    # Create child agent
    CHILD_ID="agent-gen${NEW_GENERATION}-$(uuidgen | cut -d'-' -f1)"
    
    # Analyze inheritance
    INHERITANCE_ANALYSIS=$(cat <<EOF | claude -p --output-format json --max-turns 1
Analyze what features were inherited from each parent:

Child Script:
$CHILD_SCRIPT

Return JSON:
{
  "from_parent1": ["feature1", "feature2"],
  "from_parent2": ["feature3", "feature4"],
  "novel_combinations": ["new emergent feature"],
  "crossover_type": "uniform|feature_based|semantic"
}
EOF
)
    
    # Create child metadata
    CHILD_META=$(cat <<EOF
{
  "id": "$CHILD_ID",
  "generation": $NEW_GENERATION,
  "parent_ids": ["$PARENT1_ID", "$PARENT2_ID"],
  "script_path": "$ARCHIVE_DIR/${CHILD_ID}.sh",
  "creation_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "mutations": [],
  "crossover": $(echo "$INHERITANCE_ANALYSIS" | jq -r '.result'),
  "fitness_scores": {},
  "capabilities": []
}
EOF
)
    
    # Save child agent
    echo "$CHILD_SCRIPT" > "$ARCHIVE_DIR/${CHILD_ID}.sh"
    chmod +x "$ARCHIVE_DIR/${CHILD_ID}.sh"
    echo "$CHILD_META" > "$ARCHIVE_DIR/${CHILD_ID}.meta.json"
    
    echo -e "${GREEN}✅ Created offspring: $CHILD_ID${NC}"
    echo "$CHILD_ID"
}

# Function to run evolution cycle
evolve_population() {
    local GENERATIONS=${1:-10}
    
    echo -e "${MAGENTA}🌟 Starting evolution for $GENERATIONS generations${NC}"
    
    for gen in $(seq 1 $GENERATIONS); do
        echo -e "\n${CYAN}Generation $gen${NC}"
        
        # Get current population
        CURRENT_AGENTS=$(find "$ARCHIVE_DIR" -name "*.meta.json" -type f | \
            xargs -I {} jq -r '.id' {} | sort -R | head -$MAX_POPULATION)
        
        # Selection pressure - prefer higher fitness
        SELECTED_AGENTS=$(echo "$CURRENT_AGENTS" | head -$((MAX_POPULATION / 2)))
        
        # Mutation phase
        echo -e "${YELLOW}Mutation phase...${NC}"
        for agent in $(echo "$SELECTED_AGENTS" | head -5); do
            if (( $(echo "scale=2; $RANDOM/32768 < $MUTATION_RATE" | bc -l) )); then
                mutate_script "$agent" &
            fi
        done
        wait
        
        # Crossover phase
        echo -e "${YELLOW}Crossover phase...${NC}"
        AGENTS_ARRAY=($SELECTED_AGENTS)
        for i in $(seq 0 2 $((${#AGENTS_ARRAY[@]} - 2))); do
            if (( $(echo "scale=2; $RANDOM/32768 < $CROSSOVER_RATE" | bc -l) )); then
                if [ "${AGENTS_ARRAY[$i]}" ] && [ "${AGENTS_ARRAY[$((i+1))]}" ]; then
                    crossover_scripts "${AGENTS_ARRAY[$i]}" "${AGENTS_ARRAY[$((i+1))]}" &
                fi
            fi
        done
        wait
        
        # Update generation stats
        TOTAL_AGENTS=$(find "$ARCHIVE_DIR" -name "*.meta.json" | wc -l)
        echo -e "${GREEN}Generation $gen complete. Total agents: $TOTAL_AGENTS${NC}"
        
        # Periodic cleanup of low-fitness agents
        if [ $((gen % 5)) -eq 0 ]; then
            cleanup_population
        fi
    done
}

# Function to discover novel patterns
discover_patterns() {
    echo -e "${BLUE}🔍 Discovering emergent patterns...${NC}"
    
    # Analyze all agents for common successful mutations
    ALL_MUTATIONS=$(find "$ARCHIVE_DIR" -name "*.meta.json" -type f | \
        xargs -I {} jq -r '.mutations[]?.description // empty' {} | \
        sort | uniq -c | sort -rn)
    
    # Analyze capability emergence
    CAPABILITY_ANALYSIS=$(cat <<EOF | claude -p --output-format json --max-turns 1
Analyze these mutations and identify emergent patterns:

Mutations found:
$ALL_MUTATIONS

Identify:
1. Recurring successful patterns
2. Novel capabilities that emerged
3. Unexpected combinations
4. Potential future directions

Return JSON:
{
  "patterns": ["pattern1", "pattern2"],
  "novel_capabilities": ["capability1"],
  "insights": ["insight1"],
  "recommendations": ["next steps"]
}
EOF
)
    
    echo "$CAPABILITY_ANALYSIS" | jq -r '.result' > "$ARCHIVE_DIR/discovered-patterns.json"
    
    echo -e "${GREEN}✅ Pattern analysis saved${NC}"
}

# Function to cleanup low-fitness agents
cleanup_population() {
    echo -e "${YELLOW}🧹 Cleaning population...${NC}"
    
    # Keep only top performers and diverse agents
    # This is simplified - in reality would use fitness scores
    KEEP_COUNT=$((MAX_POPULATION * 2))
    
    ALL_AGENTS=$(find "$ARCHIVE_DIR" -name "*.meta.json" -type f | \
        xargs -I {} jq -r '.id' {} | sort -R)
    
    KEEP_AGENTS=$(echo "$ALL_AGENTS" | head -$KEEP_COUNT)
    REMOVE_AGENTS=$(echo "$ALL_AGENTS" | tail -n +$((KEEP_COUNT + 1)))
    
    for agent in $REMOVE_AGENTS; do
        rm -f "$ARCHIVE_DIR/${agent}.sh" "$ARCHIVE_DIR/${agent}.meta.json"
    done
    
    echo "Removed $(echo "$REMOVE_AGENTS" | wc -w) low-fitness agents"
}

# Function to visualize lineage
visualize_lineage() {
    echo -e "${CYAN}🌳 Generating lineage visualization...${NC}"
    
    # Create simple text-based tree
    echo "Evolution Lineage Tree:" > "$ARCHIVE_DIR/lineage-tree.txt"
    echo "======================" >> "$ARCHIVE_DIR/lineage-tree.txt"
    
    # Group by generation
    for gen in $(seq 0 10); do
        AGENTS=$(find "$ARCHIVE_DIR" -name "*.meta.json" | \
            xargs grep -l "\"generation\": $gen" | \
            xargs -I {} basename {} .meta.json)
        
        if [ -n "$AGENTS" ]; then
            echo -e "\nGeneration $gen:" >> "$ARCHIVE_DIR/lineage-tree.txt"
            for agent in $AGENTS; do
                PARENTS=$(jq -r '.parent_ids | join(" × ")' "$ARCHIVE_DIR/${agent}.meta.json" 2>/dev/null || echo "seed")
                echo "  └─ $agent (from: $PARENTS)" >> "$ARCHIVE_DIR/lineage-tree.txt"
            done
        fi
    done
    
    cat "$ARCHIVE_DIR/lineage-tree.txt"
}

# Main command handler
case "$1" in
    init)
        init_evolution
        ;;
    evolve)
        shift
        evolve_population "$@"
        ;;
    mutate)
        shift
        mutate_script "$@"
        ;;
    crossover)
        shift
        crossover_scripts "$@"
        ;;
    discover)
        discover_patterns
        ;;
    lineage)
        visualize_lineage
        ;;
    cleanup)
        cleanup_population
        ;;
    *)
        echo "Usage: $0 {init|evolve|mutate|crossover|discover|lineage|cleanup}"
        echo ""
        echo "Commands:"
        echo "  init      - Initialize evolution system"
        echo "  evolve N  - Run N generations of evolution"
        echo "  mutate ID - Mutate a specific agent"
        echo "  crossover ID1 ID2 - Crossover two agents"
        echo "  discover  - Analyze emergent patterns"
        echo "  lineage   - Visualize evolution tree"
        echo "  cleanup   - Remove low-fitness agents"
        exit 1
        ;;
esac