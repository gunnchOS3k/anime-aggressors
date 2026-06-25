import type { GameState } from "./types.js";
import { FP_SCALE } from "./constants.js";
import { getStage } from "./stages.js";

/** FNV-1a 32-bit hash over serialized state bytes — deterministic across platforms. */
export function hashState(state: GameState): string {
  const json = serializeState(state);
  const bytes = typeof json === "string" ? new TextEncoder().encode(json) : json;
  let hash = 2166136261;
  for (let i = 0; i < bytes.length; i++) {
    hash ^= bytes[i];
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0");
}

export function serializeState(state: GameState): string {
  return JSON.stringify(state);
}

export function deserializeState(serialized: string | Uint8Array): GameState {
  const text =
    typeof serialized === "string"
      ? serialized
      : new TextDecoder().decode(serialized);
  return JSON.parse(text) as GameState;
}

/** Convert fixed-point to display units for rendering (non-authoritative). */
export function fpToDisplay(value: number): number {
  return value / FP_SCALE;
}
