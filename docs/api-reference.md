# API Reference

## POST /sequential-thoughts

Body:
- thoughts: Array<{ kind: "goal"|"plan"|"action"|"observation"|"reflection"|"decision", content: string, metadata?: object }>

Response:
- steps: normalized thoughts with id and timestamp
- summary: counts per kind

## POST /run-script

Body:
- mode: "scout" | "adas" | "hybrid"
- scriptPath: string (must be within `evolution/`, `dev-tools/`, `memory/`, or `optimization/`)
- params: object (primitive values become `--key value` CLI args)

Response:
- output: combined stdout/stderr (bounded)

Notes: scripts are executed via `bash` with safe defaults; output size limited.