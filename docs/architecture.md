# Architecture

The Hybrid Evolution MCP Server coordinates autonomous bash agents via minimal signals, enabling emergent behavior through scout exploration and ADAS-directed design.

- MCP server: `mcp-server/src/server.ts` exposes HTTP endpoints for thoughts and safe script execution.
- Sequential thinking: `src/core/sequential-thinking.ts` validates and normalizes thought steps.
- Evolution control:
  - `src/evolution/hybrid-evolution-server.ts`: basic mode dispatch (scout/adas/hybrid)
  - `src/evolution/hybrid-controller.ts`: adaptive mode switching using `pheromone-trails`
  - `src/evolution/mode-selector.ts`: heuristic mode selection utility
- Interfacing scripts: `src/interfaces/script-runner.ts` executes scripts with safety checks.
- Colony signaling: `src/evolution/pheromone-trails.ts` stores discoveries/requests/metrics in `hive-signals/` with time decay.
- Evaluation/storage:
  - `src/evolution/fitness-evaluator.ts` TS wrapper around bash evaluator
  - `src/evolution/agent-archive.ts` for metadata and fitness persistence
- Monitoring: `src/monitoring/colony-metrics.ts` summarizes hive signal counts.
- Shell wrappers: `mcp-server/scripts/scout-bee-wrapper.sh`, `mcp-server/scripts/adas-wrapper.sh`, `mcp-server/scripts/cross-pollinator.sh`.
- Orchestration: `orchestrate-evolution.sh` and examples under `examples/`.

Design principles: scripts remain autonomous; MCP coordinates via signals; asynchronous, resilient to failures; emergent behavior over prescriptive control.