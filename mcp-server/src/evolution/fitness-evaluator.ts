import { spawn } from "child_process";
import path from "path";
import fs from "fs";

export interface FitnessResultSummary {
  outputPath: string;
  ok: boolean;
}

export class FitnessEvaluator {
  constructor(private readonly repoRoot: string) {}

  async runBenchmark(outputPath: string): Promise<FitnessResultSummary> {
    const script = path.join(this.repoRoot, "evolution", "fitness-evaluator.sh");
    await fs.promises.mkdir(path.dirname(outputPath), { recursive: true });
    const args = ["--benchmark-mode", "--output", outputPath];
    const ok = await this.exec(script, args);
    return { outputPath, ok };
  }

  private exec(script: string, args: string[]): Promise<boolean> {
    return new Promise((resolve) => {
      const child = spawn("bash", [script, ...args], { cwd: this.repoRoot, stdio: "inherit" });
      child.on("exit", (code) => resolve(code === 0));
      child.on("error", () => resolve(false));
    });
  }
}