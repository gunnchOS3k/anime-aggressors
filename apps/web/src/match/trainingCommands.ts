import { resetTrainingDamage, resetTrainingPositions, type GameState } from "@anime-aggressors/game-core";
import { TRAINING_RESET_KEYS } from "../input/controlReference.ts";

/** Explicit practice commands only. Movement keys must never reset combat. */
export function applyTrainingResetKey(state: GameState, key: string, repeat = false): boolean {
  if (!state.config.training) return false;
  if (key === TRAINING_RESET_KEYS.damage) {
    if (!repeat) resetTrainingDamage(state);
    return true;
  }
  if (key === TRAINING_RESET_KEYS.positions) {
    if (!repeat) resetTrainingPositions(state);
    return true;
  }
  return false;
}
