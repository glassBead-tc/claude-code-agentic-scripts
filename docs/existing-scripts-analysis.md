# Existing Scripts Analysis

This document summarizes key capabilities of the existing bash scripts and proposes an integration plan to adapt them as autonomous "drones" within the Hybrid Evolution MCP hive.

## Key Evolution Scripts

- evolution/adas-meta-agent.sh: ADAS-driven agent designer that generates new agents for a given domain and archives them in evolution-archive/discovered.
- evolution/evolution-engine.sh: Mutation and crossover engine for agent scripts with lineage and metadata tracking.
- evolution/fitness-evaluator.sh: Multi-objective evaluator supporting benchmark and directory modes, writing results under fitness-results/.
- evolution/emergent-capability-discovery.sh: Combines scripts to discover emergent capabilities; catalogs inputs/outputs and interaction potential.
- evolution/cross-script-learning-network.sh: Extracts reusable patterns across scripts and consolidates them into a knowledge base.
- evolution/continuous-reflection-engine.sh: Performs system-wide reflection, generating insights and strategic recommendations.
- evolution/meta-learner.sh: Meta-level optimizer that evolves the evolution strategy itself and updates meta-memory.

## Supporting Tools

- dev-tools/intelligent-debugger.sh: Real-time debugging with streaming analysis and optional auto-fixes.
- memory/memory-manager.sh: Project/user memory management, analysis, and synchronization.

## Integration Plan: Drone Roles

- Scout drones (exploration):
  - evolution/emergent-capability-discovery.sh: Explore combinations, record discoveries in hive-signals/discoveries/.
  - evolution/cross-script-learning-network.sh: Extract patterns; emit lightweight signals to hive-signals/metrics/.
  - memory/memory-manager.sh (analyze/search modes): Scout memory patterns; write summaries to hive-signals/discoveries/.
  - dev-tools/intelligent-debugger.sh (analysis-only): Anomaly scouting; write alerts to hive-signals/requests/.

- ADAS drones (directed design):
  - evolution/adas-meta-agent.sh: Design agents from domain prompts via MCP coordination.
  - evolution/fitness-evaluator.sh: Provide fitness scoring; persist metrics under hive-signals/metrics/ and agent archive.

- Hybrid controllers (coordination/meta):
  - evolution/evolution-engine.sh: Perform mutation/crossover actions triggered by MCP signals.
  - evolution/continuous-reflection-engine.sh and evolution/meta-learner.sh: Feed mode-selection heuristics and evolution parameters.

## Wrapping Strategy

- Preserve autonomy: Scripts remain runnable standalone; wrappers only add mode flags and signal emission.
- Minimal coupling: MCP writes/reads signals in hive-signals/; scripts react locally via wrappers.
- Safety: Only allow execution from evolution, dev-tools, memory, optimization directories with sanitized params.

## Initial MCP Interfaces

- Sequential thinking: Normalize and validate thought steps for deterministic processing.
- Script runner: Safe execution with bounded output and restricted directories.
- Hybrid evolution: Mode selection (scout/adas/hybrid) and action dispatch to appropriate scripts.