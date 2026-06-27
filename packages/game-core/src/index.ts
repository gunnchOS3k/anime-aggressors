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
  BAT_STARTUP,
} from "./modes/impactDummyDerby.js";
export type {
  ImpactDummyDerbyState,
  DerbyPhase,
  DerbyInput,
  ImpactDummyDerbyPhase,
  DerbyPlayerState,
  ImpactDummyState,
  KineticBatState,
  DerbyGrade,
} from "./modes/impactDummyDerby.js";
export type { ImpactDummyDerbyEvent } from "./modes/impactDummyDerbyEvents.js";
export { computeDerbyScore, gradeFromScore, distanceDisplayUnits } from "./modes/impactDummyDerbyScoring.js";
export type {
  TeamId,
  FlaglineRoomIndex,
  FlaglineRoom,
  FlaglineMetaState,
  FlaglineRoomResult,
  FlaglineConfig,
  FlaglineClashState,
  TeamSlot,
  FlaglineProgressionResult,
} from "./modes/flaglineTypes.js";
export { FLAGLINE_DEFAULTS, TEAM_PUSH_DIRECTION } from "./modes/flaglineTypes.js";
export { FLAGLINE_ROOMS, FLAGLINE_ROOM_ORDER, getFlaglineRoom, getRoomLabel } from "./modes/flaglineMaps.js";
export { getNextRoomIndex, roomIndexToStripPosition } from "./modes/flaglineProgression.js";
export {
  updateFlagCoreCapture,
  checkCaptureWin,
  resetCaptureMeters,
  countTeamsInCore,
} from "./modes/flaglineObjective.js";
export {
  createInitialFlaglineState,
  createDefaultTeamSlots,
  simulateFlaglineFrame,
  mergeFlaglineInputs,
  flaglineStateHash,
  serializeFlaglineState,
  deserializeFlaglineState,
} from "./modes/flaglineClash.js";
export { generateFlaglineBotInput, generateAllBotInputs } from "./bots/simpleFlaglineBot.js";
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
export type { FighterSize } from "./sizeClasses.js";
export { SIZE_STATS, getSizeStats } from "./sizeClasses.js";
export type { FighterColor, ElementEffect, ElementDef } from "./elements.js";
export { ELEMENTS, getElementForColor, getElementColorHex } from "./elements.js";
export type { CreatedFighter } from "./createdFighter.js";
export {
  buildCreatedFighter,
  serializeCreatedFighter,
  deserializeCreatedFighter,
  getDefaultCreatedFighter,
  createCreatedFighterId,
  DEFAULT_FIGHTER_NAME,
} from "./createdFighter.js";
export {
  getFighterProfile,
  applyCreatedFighterToPlayer,
  previewFighterStats,
  getDisplayColor,
  getVisualScale,
} from "./fighterCreation.js";
export type { FighterPreviewStats } from "./fighterCreation.js";
export {
  COYOTE_FRAMES,
  JUMP_BUFFER_FRAMES,
  scaleKnockback,
  isDodgeInvulnerable,
} from "./feel.js";
export type {
  MatchType,
  ItemFrequency,
  ElementMode,
  TeamMode,
  GameRuleset,
} from "./rulesets.js";
export {
  DEFAULT_RULESET,
  RULESET_PRESETS,
  cloneRuleset,
  validateRuleset,
  rulesetToMatchDurationFrames,
  effectivePlayerCount,
  gameConfigFromRuleset,
  elementGameplayEnabled,
  elementVisualsEnabled,
} from "./rulesets.js";
export type {
  CareerProfile,
  FighterCareerStats,
  MatchRecord,
  MatchPlayerRecord,
  MatchMode,
  ReplayRecord,
  ReplayInputFrame,
  SaveGameRecord,
  ScoreboardRow,
} from "./career/types.js";
export {
  createDefaultCareerProfile,
  createDefaultFighterStats,
  computeWinRate,
  computeHitAccuracy,
} from "./career/stats.js";
export type { StatEvent } from "./career/statEvents.js";
export { collectStatEventsForFrame } from "./career/statEvents.js";
export { buildScoreboard } from "./career/scoreboard.js";
export type { MilestoneId, MilestoneDef } from "./career/milestones.js";
export { MILESTONE_DEFS, evaluateMilestones } from "./career/milestones.js";
export {
  buildMatchRecordFromEvents,
  applyMatchRecordToCareer,
} from "./career/aggregateCareer.js";
export type { PlayerMeta } from "./career/aggregateCareer.js";
export {
  createReplayRecord,
  verifyReplayRecord,
  inputsToReplayFrames,
} from "./career/replay.js";
export { createSaveGameRecord, loadSaveGameState } from "./career/saveGame.js";
