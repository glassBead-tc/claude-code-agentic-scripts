import { spawn } from "child_process";
import path from "path";
import fs from "fs";
const ALLOWED_DIRS = ["evolution", "dev-tools", "memory", "optimization"];
export class LocalScriptRunner {
    repoRoot;
    maxOutputBytes;
    constructor(repoRoot, maxOutputBytes = 200_000) {
        this.repoRoot = repoRoot;
        this.maxOutputBytes = maxOutputBytes;
    }
    async executeScout(scriptPath, params) {
        return this.execute("scout", scriptPath, params);
    }
    async executeADAS(scriptPath, params) {
        return this.execute("adas", scriptPath, params);
    }
    async executeHybrid(scriptPath, params) {
        return this.execute("hybrid", scriptPath, params);
    }
    async execute(mode, scriptPath, params) {
        const resolved = this.resolveSafeScriptPath(scriptPath);
        await this.ensureExecutable(resolved);
        const args = this.buildArgs(mode, params);
        return this.spawnAndCapture(resolved, args);
    }
    resolveSafeScriptPath(scriptPath) {
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
    async ensureExecutable(absolutePath) {
        await fs.promises.access(absolutePath, fs.constants.R_OK);
        try {
            await fs.promises.access(absolutePath, fs.constants.X_OK);
        }
        catch {
            await fs.promises.chmod(absolutePath, 0o755);
        }
    }
    buildArgs(mode, params) {
        // Pass only primitive string/number/boolean params as CLI args: --key value
        const args = [];
        args.push("--mode", mode);
        for (const [key, value] of Object.entries(params ?? {})) {
            if (value == null)
                continue;
            if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
                args.push(`--${key}`);
                args.push(String(value));
            }
        }
        return args;
    }
    spawnAndCapture(script, args) {
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
            const append = (chunk) => {
                out = Buffer.concat([out, chunk]);
                if (out.length > this.maxOutputBytes) {
                    child.kill("SIGTERM");
                }
            };
            child.stdout.on("data", (c) => append(c));
            child.stderr.on("data", (c) => append(c));
            child.on("error", reject);
            child.on("exit", (code) => {
                if (code === 0)
                    resolve(out.toString("utf8"));
                else
                    reject(new Error(`Script exited with code ${code}`));
            });
        });
    }
}
