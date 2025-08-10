import { processSequentialThoughts } from "../core/sequential-thinking.js";
export class HybridEvolutionServer {
    runner;
    constructor(runner) {
        this.runner = runner;
    }
    async handle(thoughts) {
        const processed = processSequentialThoughts(thoughts);
        const mode = this.selectMode(thoughts);
        const last = thoughts[thoughts.length - 1];
        const output = await this.dispatchAction(mode, last);
        return { mode, output, processed };
    }
    selectMode(thoughts) {
        const tail = thoughts.slice(-3);
        const intents = new Set(tail.map(t => t.intent));
        if (intents.has("explore"))
            return "scout";
        if (intents.has("design"))
            return "adas";
        return "hybrid";
    }
    async dispatchAction(mode, thought) {
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
    pickScriptForAction(mode, thought) {
        if (thought?.targetScript)
            return thought.targetScript;
        if (mode === "scout")
            return "evolution/emergent-capability-discovery.sh";
        if (mode === "adas")
            return "evolution/adas-meta-agent.sh";
        return "evolution/evolution-engine.sh";
    }
    pickParamsForAction(thought) {
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
