import fs from "fs";
import path from "path";

export interface ColonySummaryMetrics {
  discoveries: number;
  requests: number;
  metrics: number;
  lastUpdated: number;
}

export class ColonyMetrics {
  constructor(private readonly repoRoot: string) {}

  async summarize(): Promise<ColonySummaryMetrics> {
    const base = path.join(this.repoRoot, "hive-signals");
    const count = async (sub: string) => {
      try {
        const dir = path.join(base, sub);
        const files = await fs.promises.readdir(dir);
        return files.length;
      } catch {
        return 0;
      }
    };
    return {
      discoveries: await count("discoveries"),
      requests: await count("requests"),
      metrics: await count("metrics"),
      lastUpdated: Date.now(),
    };
  }
}