export type ModeIntent =
  | "startMatch"
  | "customGame"
  | "flaglineClash"
  | "impactDummyDerby"
  | "training";

export const MODE_INTENT_LABELS: Record<ModeIntent, string> = {
  startMatch: "Start Match",
  customGame: "Custom Game",
  flaglineClash: "Flagline Clash",
  impactDummyDerby: "Impact Dummy Derby",
  training: "Training Mode",
};
