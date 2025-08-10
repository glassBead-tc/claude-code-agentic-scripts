import fs from "fs";
import path from "path";

export interface PheromoneSignal {
  id: string;
  kind: "discovery" | "request" | "metric";
  content: string;
  strength: number; // 0..1
  createdAt: number;
}

export class PheromoneTrails {
  constructor(private readonly rootDir: string, private readonly halfLifeSeconds = 3600) {}

  private dirFor(kind: PheromoneSignal["kind"]): string {
    return path.join(this.rootDir, "hive-signals", kind === "discovery" ? "discoveries" : kind === "request" ? "requests" : "metrics");
  }

  async emit(kind: PheromoneSignal["kind"], content: string, strength = 1): Promise<PheromoneSignal> {
    const signal: PheromoneSignal = {
      id: Math.random().toString(36).slice(2),
      kind,
      content,
      strength: Math.max(0, Math.min(1, strength)),
      createdAt: Date.now(),
    };
    const dir = this.dirFor(kind);
    await fs.promises.mkdir(dir, { recursive: true });
    const file = path.join(dir, `${signal.createdAt}_${signal.id}.json`);
    await fs.promises.writeFile(file, JSON.stringify(signal, null, 2), "utf8");
    return signal;
  }

  async sense(kind: PheromoneSignal["kind"], limit = 20): Promise<PheromoneSignal[]> {
    const dir = this.dirFor(kind);
    let files: string[] = [];
    try {
      files = (await fs.promises.readdir(dir)).filter(f => f.endsWith(".json"));
    } catch {
      return [];
    }
    const entries = await Promise.all(
      files.map(async f => {
        const raw = await fs.promises.readFile(path.join(dir, f), "utf8");
        const obj = JSON.parse(raw) as PheromoneSignal;
        return this.applyDecay(obj);
      })
    );
    return entries
      .filter(e => e.strength > 0.05)
      .sort((a, b) => b.strength - a.strength)
      .slice(0, limit);
  }

  private applyDecay(signal: PheromoneSignal): PheromoneSignal {
    const ageSec = (Date.now() - signal.createdAt) / 1000;
    const lambda = Math.log(2) / this.halfLifeSeconds;
    const decayedStrength = signal.strength * Math.exp(-lambda * ageSec);
    return { ...signal, strength: decayedStrength };
  }
}