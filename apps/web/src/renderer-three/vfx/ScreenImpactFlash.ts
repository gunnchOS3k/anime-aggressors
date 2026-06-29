import type { HitEvent } from "@anime-aggressors/game-core";

export function shouldFlashScreen(event: HitEvent): boolean {
  return event.hitStrength === "heavy" || event.hitStrength === "super" || event.hitStrength === "launch";
}

export function screenFlashOpacity(event: HitEvent): number {
  if (event.hitStrength === "super") return 0.35;
  if (event.hitStrength === "heavy" || event.hitStrength === "launch") return 0.22;
  return 0.1;
}
