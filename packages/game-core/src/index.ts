export type {
  InputFrame,
  GestureName,
  GameConfig,
  GameState,
  PlayerState,
  MatchPhase,
  PlayerActionState,
  ReplayResult,
  Hitbox,
  Hurtbox,
  StageBounds,
} from "./types.js";

export {
  SIM_HZ,
  FP_SCALE,
  STAGE_WIDTH,
  STAGE_HEIGHT,
  FLOOR_Y,
  DEFAULT_STOCKS,
  DEFAULT_MATCH_FRAMES,
  COUNTDOWN_FRAMES,
} from "./constants.js";

export { createInitialGameState, cloneGameState } from "./state.js";
export { simulateFrame, resetForRematch } from "./simulate.js";
export { getCharacter, listCharacters } from "./characters.js";
export type { CharacterDef } from "./characters.js";
export { getStage, listStages } from "./stages.js";
export type { StageDef } from "./stages.js";
export {
  getHurtbox,
  getHurtboxes,
  getActiveHitboxes,
  getActiveHitboxesForState,
  boxesOverlap,
} from "./collision.js";
export { hashState, serializeState, deserializeState, fpToDisplay } from "./hash.js";
export { replay } from "./replay.js";
export {
  createInitialDerbyState,
  simulateDerbyFrame,
  resetDerbyForRetry,
  replayDerby,
  derbyStateHash,
  DAMAGE_PHASE_FRAMES,
  DERBY_COUNTDOWN_FRAMES,
  LAUNCH_WINDOW_FRAMES,
} from "./modes/impactDummyDerby.js";
export type { ImpactDummyDerbyState, DerbyPhase, DerbyInput } from "./modes/impactDummyDerby.js";
export { createCombatEvent } from "./combatEvents.js";
export type { CombatEvent, CombatEventType } from "./combatEvents.js";
export { combatEventToSfx, createSfxEvent } from "./sfxEvents.js";
export type { SfxEvent, SfxEventType } from "./sfxEvents.js";
export {
  NEUTRAL_ATTACK,
  FORWARD_ATTACK,
  UP_ATTACK,
  DOWN_ATTACK,
  AERIAL_ATTACK,
  SIDE_SPECIAL,
  SPECIAL_ATTACK,
  DODGE_MOVE,
  isInStartup,
  isInActive,
  isInRecovery,
} from "./frameData.js";
export type { MoveFrameData } from "./frameData.js";
export { getMoveData, actionToMoveId, isMoveComplete } from "./moves.js";
export type { MoveId } from "./moves.js";
export {
  COYOTE_FRAMES,
  JUMP_BUFFER_FRAMES,
  scaleKnockback,
  isDodgeInvulnerable,
} from "./feel.js";
