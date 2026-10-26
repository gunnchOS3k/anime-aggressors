import { resetTrainingDamage, resetTrainingPositions, simulateFrame, type GameState, type InputFrame,
  type TrainingDummyBehavior } from "@anime-aggressors/game-core";
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

/** Local practice owns the same state it edits. Competitive rollback is separate. */
export function advanceTrainingFrame(state: GameState, inputs: InputFrame[]): GameState {
  if (!state.config.training) throw new Error("Local practice requires training configuration");
  return simulateFrame(state, inputs);
}

export function setTrainingDummy(state: GameState, behavior: TrainingDummyBehavior): boolean {
  if (!state.config.training || !["idle", "shield", "jump", "cpu1"].includes(behavior)) return false;
  state.config.training = { ...state.config.training, dummyBehavior: behavior };
  const id = state.config.training.dummyPlayerId;
  const otherCpu = state.config.cpuOpponents?.filter(cpu => cpu.playerId !== id) ?? [];
  state.config.cpuOpponents = behavior === "cpu1"
    ? [...otherCpu, { playerId: id, difficulty: 1, seed: state.config.seed }]
    : otherCpu.length ? otherCpu : undefined;
  return true;
}
