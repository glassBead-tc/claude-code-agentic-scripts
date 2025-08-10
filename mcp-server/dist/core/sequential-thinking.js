export function validateThought(thought) {
    const errors = [];
    if (!thought.kind)
        errors.push("kind is required");
    if (!thought.content || thought.content.trim().length === 0)
        errors.push("content is required");
    if (thought.kind && !["goal", "plan", "action", "observation", "reflection", "decision"].includes(thought.kind)) {
        errors.push(`invalid kind: ${thought.kind}`);
    }
    return { valid: errors.length === 0, errors };
}
export function normalizeThought(thought) {
    const id = thought.id ?? cryptoRandomId();
    const timestamp = thought.timestamp ?? Date.now();
    const content = formatContent(thought.content);
    return { ...thought, id, timestamp, content };
}
export function formatContent(text) {
    return text.replace(/\s+/g, " ").trim();
}
export function processSequentialThoughts(steps) {
    const normalized = [];
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
function buildSummary(steps) {
    const counts = new Map();
    for (const s of steps)
        counts.set(s.kind, (counts.get(s.kind) ?? 0) + 1);
    const ordered = ["goal", "plan", "action", "observation", "reflection", "decision"];
    const parts = ordered
        .filter(k => counts.get(k))
        .map(k => `${k}:${counts.get(k)}`);
    return parts.join(" | ");
}
function cryptoRandomId() {
    // Lightweight id without importing node:crypto to keep this module portable
    return Math.random().toString(36).slice(2) + Date.now().toString(36);
}
