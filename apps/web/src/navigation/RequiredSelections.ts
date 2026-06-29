import type { ModeIntent } from "./ModeIntent.ts";

export type RequiredSelection =
  | "rules"
  | "stage"
  | "fighters"
  | "controls"
  | "ready"
  | "derbyFighter";

export const REQUIRED_SELECTIONS: Record<ModeIntent, RequiredSelection[]> = {
  startMatch: ["rules", "stage", "fighters", "controls", "ready"],
  customGame: ["rules", "stage", "fighters", "controls", "ready"],
  flaglineClash: ["rules", "fighters", "controls", "ready"],
  impactDummyDerby: ["derbyFighter", "ready"],
  training: ["fighters", "ready"],
};

export function nextRequiredSelection(
  mode: ModeIntent,
  completed: RequiredSelection[],
): RequiredSelection | null {
  const required = REQUIRED_SELECTIONS[mode];
  for (const step of required) {
    if (!completed.includes(step)) return step;
  }
  return null;
}
