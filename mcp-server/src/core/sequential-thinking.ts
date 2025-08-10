export type ThoughtKind = "goal" | "plan" | "action" | "observation" | "reflection" | "decision";

export interface ThoughtData {
  id?: string;
  kind: ThoughtKind;
  content: string;
  timestamp?: number;
  metadata?: Record<string, unknown>;
}

export interface ValidatedThought extends ThoughtData {
  id: string;
  timestamp: number;
  content: string;
}

export interface ThoughtValidationResult {
  valid: boolean;
  errors: string[];
}

export function validateThought(thought: ThoughtData): ThoughtValidationResult {
  const errors: string[] = [];
  if (!thought.kind) errors.push("kind is required");
  if (!thought.content || thought.content.trim().length === 0) errors.push("content is required");
  if (thought.kind && !["goal", "plan", "action", "observation", "reflection", "decision"].includes(thought.kind)) {
    errors.push(`invalid kind: ${thought.kind}`);
  }
  return { valid: errors.length === 0, errors };
}

export function normalizeThought(thought: ThoughtData): ValidatedThought {
  const id = thought.id ?? cryptoRandomId();
  const timestamp = thought.timestamp ?? Date.now();
  const content = formatContent(thought.content);
  return { ...thought, id, timestamp, content } as ValidatedThought;
}

export function formatContent(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

export interface SequentialProcessingResult {
  steps: ValidatedThought[];
  summary: string;
}

export function processSequentialThoughts(steps: ThoughtData[]): SequentialProcessingResult {
  const normalized: ValidatedThought[] = [];
  for (const step of steps) {
    const { valid, errors } = validateThought(step);
    if (!valid) {
      throw new Error(`Invalid thought: ${errors.join(", ")}`);
    }
    normalized.push(normalizeThought(step));
  }
  const summary = buildSummary(normalized);
  return { steps: normalized, summary };
}

function buildSummary(steps: ValidatedThought[]): string {
  const counts = new Map<ThoughtKind, number>();
  for (const s of steps) counts.set(s.kind, (counts.get(s.kind) ?? 0) + 1);
  const ordered = ["goal", "plan", "action", "observation", "reflection", "decision"] as ThoughtKind[];
  const parts = ordered
    .filter(k => counts.get(k))
    .map(k => `${k}:${counts.get(k)}`);
  return parts.join(" | ");
}

function cryptoRandomId(): string {
  // Lightweight id without importing node:crypto to keep this module portable
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}