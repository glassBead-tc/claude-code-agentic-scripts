# MCP Server

This folder provides a minimal HTTP server that exposes the ADAS Meta Agent via a REST endpoint. It is implemented in TypeScript using Express.

## Setup

```bash
cd mcp-server
npm install
```

## Running

```bash
npx ts-node src/server.ts
```

### Endpoints

- `POST /design-agent`
  - JSON body: `{ "domain": "<domain>", "iterations": <number>, "sessionId": "<optional>" }`
  - Runs `./evolution/adas-meta-agent.sh` from the repository root.
  - Stores the resulting script in memory and responds with `{ sessionId, name, script, metadata }`.

- `GET /design-agent/:sessionId`
  - Retrieve a previously generated result using the `sessionId` returned by the POST call.

The in-memory store lasts for the lifetime of the server process, enabling clients to fetch
their generated agent multiple times during a session.

This follows the plan described in the repository discussions for serving agentic scripts via an MCP-compatible API.
