import express from 'express';
import { execFile } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';
import crypto from 'crypto';

const app = express();
app.use(express.json());

const ROOT_DIR = path.resolve(__dirname, '..', '..');
const ADAS_SCRIPT = path.join(ROOT_DIR, 'evolution', 'adas-meta-agent.sh');
const DISCOVERED_DIR = path.join(ROOT_DIR, 'evolution-archive', 'discovered');

// In-memory store of generated agents for the lifetime of the server
const sessionStore = new Map<string, { name: string; script: string; metadata: any }>();

function runAdas(domain: string, iterations: number): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = execFile(ADAS_SCRIPT, [domain, String(iterations)], { cwd: ROOT_DIR }, (error) => {
      if (error) reject(error);
      else resolve();
    });
    child.stdout?.pipe(process.stdout);
    child.stderr?.pipe(process.stderr);
  });
}

async function getLatestResult() {
  const files = await fs.readdir(DISCOVERED_DIR);
  const scripts = files.filter(f => f.endsWith('.sh'));
  if (scripts.length === 0) {
    throw new Error('No scripts found in archive');
  }
  const scriptPaths = scripts.map(f => path.join(DISCOVERED_DIR, f));
  const stats = await Promise.all(scriptPaths.map(p => fs.stat(p)));
  const latestIndex = stats.reduce((idx, s, i, arr) => s.mtimeMs > arr[idx].mtimeMs ? i : idx, 0);
  const scriptPath = scriptPaths[latestIndex];
  const metaPath = scriptPath.replace(/\.sh$/, '.meta.json');
  const scriptContent = await fs.readFile(scriptPath, 'utf8');
  let metadata: any = {};
  try {
    const metaContent = await fs.readFile(metaPath, 'utf8');
    metadata = JSON.parse(metaContent);
  } catch {
    // ignore
  }
  return { name: path.basename(scriptPath), script: scriptContent, metadata };
}

// Launch ADAS meta agent and store result under a session id
app.post('/design-agent', async (req, res) => {
  const { domain, iterations, sessionId } = req.body;
  if (!domain || !iterations) {
    return res.status(400).json({ error: 'domain and iterations required' });
  }
  const id = typeof sessionId === 'string' ? sessionId : crypto.randomUUID();
  try {
    await runAdas(domain, Number(iterations));
    const result = await getLatestResult();
    sessionStore.set(id, result);
    res.json({ sessionId: id, ...result });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Retrieve a previously generated agent by session id
app.get('/design-agent/:id', (req, res) => {
  const id = req.params.id;
  const result = sessionStore.get(id);
  if (!result) {
    return res.status(404).json({ error: 'session id not found' });
  }
  res.json({ sessionId: id, ...result });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`MCP server listening on port ${port}`);
});
