import fs from "fs";
import path from "path";

export interface AgentMetadata {
  id: string;
  name?: string;
  generation?: number;
  parent_ids?: string[];
  fitness_scores?: Record<string, number>;
  created_at?: number;
  lineage?: string[];
}

export class AgentArchive {
  private readonly archiveDir: string;

  constructor(private readonly repoRoot: string, dir = "evolution-archive") {
    this.archiveDir = path.join(this.repoRoot, dir);
  }

  async listAgents(): Promise<AgentMetadata[]> {
    let files: string[] = [];
    try {
      files = (await fs.promises.readdir(this.archiveDir)).filter(f => f.endsWith(".meta.json"));
    } catch {
      return [];
    }
    const metas = await Promise.all(
      files.map(async f => {
        const raw = await fs.promises.readFile(path.join(this.archiveDir, f), "utf8");
        return JSON.parse(raw) as AgentMetadata;
      })
    );
    return metas;
  }

  async persistFitness(agentId: string, scores: Record<string, number>): Promise<void> {
    const metaPath = path.join(this.archiveDir, `${agentId}.meta.json`);
    let meta: AgentMetadata = { id: agentId };
    try {
      meta = JSON.parse(await fs.promises.readFile(metaPath, "utf8"));
    } catch {}
    meta.fitness_scores = { ...(meta.fitness_scores ?? {}), ...scores };
    await fs.promises.writeFile(metaPath, JSON.stringify(meta, null, 2), "utf8");
  }

  async bestAgents(topN = 5): Promise<AgentMetadata[]> {
    const agents = await this.listAgents();
    const scored = agents
      .map(a => ({ a, score: average(Object.values(a.fitness_scores ?? {})) }))
      .sort((x, y) => (y.score ?? 0) - (x.score ?? 0));
    return scored.slice(0, topN).map(s => s.a);
  }
}

function average(nums: number[]): number {
  if (nums.length === 0) return 0;
  return nums.reduce((s, n) => s + n, 0) / nums.length;
}