import type { EvolutionMode } from "./hybrid-evolution-server.js";

export interface ModeContextFeatures {
  problemSize?: number;
  timeBudgetSec?: number;
  noveltyRequired?: boolean;
  reliabilityRequired?: boolean;
}

export function selectMode(features: ModeContextFeatures): EvolutionMode {
  if (features.reliabilityRequired && !features.noveltyRequired) return "adas";
  if (features.noveltyRequired && !features.reliabilityRequired) return "scout";
  if ((features.problemSize ?? 0) > 1000 && (features.timeBudgetSec ?? 0) < 60) return "adas";
  return "hybrid";
}