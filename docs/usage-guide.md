# Usage Guide

## Start the server

- From `mcp-server/`: `npm run start`
- Endpoints:
  - POST `/sequential-thoughts` { thoughts: ThoughtData[] }
  - POST `/run-script` { mode: "scout"|"adas"|"hybrid", scriptPath, params }

## Orchestration scripts

- `./examples/scout-exploration.sh`
- `./examples/adas-optimization.sh [domain] [iterations]`
- `./examples/hybrid-balanced.sh [domain] [iterations]`

## Signals and artifacts

- Hive signals: `hive-signals/{discoveries,requests,metrics}`
- Agent archive: `evolution-archive/`
- Cross-pollinated hybrids: `colony-patterns/`

## Philosophy

- Scripts remain autonomous; MCP mainly emits/reads signals.
- Allow concurrent runs; failures should not cascade.