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
  NEUTRAL_ATTACK,
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
