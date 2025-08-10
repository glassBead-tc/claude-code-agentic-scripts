import type { EvolutionThoughtData, EvolutionResponse, EvolutionMode } from "./hybrid-evolution-server.js";
import { HybridEvolutionServer } from "./hybrid-evolution-server.js";
import type { ScriptRunner } from "../interfaces/script-runner.js";
import { PheromoneTrails } from "./pheromone-trails.js";

export class HybridController {
  private trails: PheromoneTrails;

  constructor(private readonly runner: ScriptRunner, private readonly repoRoot: string) {
    this.trails = new PheromoneTrails(repoRoot);
  }

  async run(thoughts: EvolutionThoughtData[]): Promise<EvolutionResponse> {
    const mode = await this.selectModeWithSignals(thoughts);
    // Inject inferred intent into the last thought to bias mode selection downstream
    const biased = thoughts.slice();
    const last = { ...(biased[biased.length - 1] ?? {}), intent: this.intentFor(mode) } as EvolutionThoughtData;
    biased[biased.length - 1] = last;

    const server = new HybridEvolutionServer(this.runner);
    const res = await server.handle(biased);

    // Emit a metric pheromone for feedback
    await this.trails.emit("metric", JSON.stringify({ mode_chosen: mode, summary: res.processed.summary }), 0.8);
    return res;
  }

  private async selectModeWithSignals(thoughts: EvolutionThoughtData[]): Promise<EvolutionMode> {
    const discoveries = await this.trails.sense("discovery", 5);
    const metrics = await this.trails.sense("metric", 5);

    const recentDiscoveryStrength = discoveries.reduce((s, d) => s + d.strength, 0);
    const recentMetricStrength = metrics.reduce((s, m) => s + m.strength, 0);

    // Simple heuristic: if exploration signals are weak and metrics suggest stalling, use ADAS; if discoveries are flowing, stay scout; else hybrid
    const lastIntent = thoughts[thoughts.length - 1]?.intent;
    if (recentDiscoveryStrength < 0.2 && recentMetricStrength > 0.3) return "adas";
    if (recentDiscoveryStrength > 0.6) return "scout";
    if (lastIntent === "design") return "adas";
    if (lastIntent === "explore") return "scout";
    return "hybrid";
  }

  private intentFor(mode: EvolutionMode): EvolutionThoughtData["intent"] {
    return mode === "adas" ? "design" : mode === "scout" ? "explore" : "balance";
  }
}