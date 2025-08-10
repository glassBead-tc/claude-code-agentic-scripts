import { spawn } from "child_process";
import path from "path";
import fs from "fs";

export interface ScriptRunner {
  executeScout(scriptPath: string, params: Record<string, unknown>): Promise<string>;
  executeADAS(scriptPath: string, params: Record<string, unknown>): Promise<string>;
  executeHybrid(scriptPath: string, params: Record<string, unknown>): Promise<string>;
}

export type AllowedMode = "scout" | "adas" | "hybrid";

const ALLOWED_DIRS = ["evolution", "dev-tools", "memory", "optimization"];

export class LocalScriptRunner implements ScriptRunner {
  constructor(private readonly repoRoot: string, private readonly maxOutputBytes = 200_000) {}

  async executeScout(scriptPath: string, params: Record<string, unknown>): Promise<string> {
    return this.execute("scout", scriptPath, params);
  }

  async executeADAS(scriptPath: string, params: Record<string, unknown>): Promise<string> {
    return this.execute("adas", scriptPath, params);
  }

  async executeHybrid(scriptPath: string, params: Record<string, unknown>): Promise<string> {
    return this.execute("hybrid", scriptPath, params);
  }

  private async execute(mode: AllowedMode, scriptPath: string, params: Record<string, unknown>): Promise<string> {
    const resolved = this.resolveSafeScriptPath(scriptPath);
    await this.ensureExecutable(resolved);

    const args = this.buildArgs(mode, params);
    return this.spawnAndCapture(resolved, args);
  }

  private resolveSafeScriptPath(scriptPath: string): string {
    const absolute = path.isAbsolute(scriptPath) ? scriptPath : path.join(this.repoRoot, scriptPath);
    const rel = path.relative(this.repoRoot, absolute);
    const top = rel.split(path.sep)[0];
    if (!ALLOWED_DIRS.includes(top)) {
      throw new Error(`Script path not allowed: ${rel}`);
    }
    if (!absolute.endsWith(".sh")) {
      throw new Error("Only .sh scripts are allowed");
    }
    return absolute;
  }

  private async ensureExecutable(absolutePath: string): Promise<void> {
    await fs.promises.access(absolutePath, fs.constants.R_OK);
    try {
      await fs.promises.access(absolutePath, fs.constants.X_OK);
    } catch {
      await fs.promises.chmod(absolutePath, 0o755);
    }
  }

  private buildArgs(mode: AllowedMode, params: Record<string, unknown>): string[] {
    // Pass only primitive string/number/boolean params as CLI args: --key value
    const args: string[] = [];
    args.push("--mode", mode);
    for (const [key, value] of Object.entries(params ?? {})) {
      if (value == null) continue;
      if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
        args.push(`--${key}`);
        args.push(String(value));
      }
    }
    return args;
  }

  private spawnAndCapture(script: string, args: string[]): Promise<string> {
    return new Promise((resolve, reject) => {
      const child = spawn("bash", [script, ...args], {
        cwd: this.repoRoot,
        env: {
          ...process.env,
          // Reduce risk; do not inherit dangerous env overrides
          NODE_OPTIONS: "",
        },
        stdio: ["ignore", "pipe", "pipe"],
      });

      let out = Buffer.alloc(0);
      const append = (chunk: Buffer) => {
        out = Buffer.concat([out, chunk]);
        if (out.length > this.maxOutputBytes) {
          child.kill("SIGTERM");
        }
      };

      child.stdout.on("data", (c: Buffer) => append(c));
      child.stderr.on("data", (c: Buffer) => append(c));

      child.on("error", reject);
      child.on("exit", (code) => {
        if (code === 0) resolve(out.toString("utf8"));
        else reject(new Error(`Script exited with code ${code}`));
      });
    });
  }
}