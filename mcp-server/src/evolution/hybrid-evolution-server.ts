import { processSequentialThoughts, type ThoughtData } from "../core/sequential-thinking.js";
import type { ScriptRunner } from "../interfaces/script-runner.js";

export type EvolutionMode = "scout" | "adas" | "hybrid";

export interface EvolutionThoughtData extends ThoughtData {
  intent?: "explore" | "design" | "balance";
  action?: "scan" | "mutate" | "crossover" | "evaluate" | "archive";
  targetScript?: string;
}

export interface EvolutionResponse {
  mode: EvolutionMode;
  output: string;
  processed: ReturnType<typeof processSequentialThoughts>;
}

export class HybridEvolutionServer {
  constructor(private readonly runner: ScriptRunner) {}

  async handle(thoughts: EvolutionThoughtData[]): Promise<EvolutionResponse> {
    const processed = processSequentialThoughts(thoughts);
    const mode = this.selectMode(thoughts);

    const last = thoughts[thoughts.length - 1];
    const output = await this.dispatchAction(mode, last);

    return { mode, output, processed };
  }

  private selectMode(thoughts: EvolutionThoughtData[]): EvolutionMode {
    const tail = thoughts.slice(-3);
    const intents = new Set(tail.map(t => t.intent));
    if (intents.has("explore")) return "scout";
    if (intents.has("design")) return "adas";
    return "hybrid";
  }

  private async dispatchAction(mode: EvolutionMode, thought: EvolutionThoughtData): Promise<string> {
    const script = this.pickScriptForAction(mode, thought);
    const params = this.pickParamsForAction(thought);

    switch (mode) {
      case "scout":
        return this.runner.executeScout(script, params);
      case "adas":
        return this.runner.executeADAS(script, params);
      case "hybrid":
      default:
        return this.runner.executeHybrid(script, params);
    }
  }

  private pickScriptForAction(mode: EvolutionMode, thought: EvolutionThoughtData): string {
    if (thought?.targetScript) return thought.targetScript;

    if (mode === "scout") return "evolution/emergent-capability-discovery.sh";
    if (mode === "adas") return "evolution/adas-meta-agent.sh";
    return "evolution/evolution-engine.sh";
  }

  private pickParamsForAction(thought: EvolutionThoughtData): Record<string, unknown> {
    switch (thought.action) {
      case "scan":
        return { max: 50 };
      case "mutate":
        return { rate: 0.3 };
      case "crossover":
        return { prob: 0.5 };
      case "evaluate":
        return { benchmark: true };
      case "archive":
        return { persist: true };
      default:
        return {};
    }
  }
}