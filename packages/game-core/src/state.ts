import type { GameConfig, GameState, PlayerState, StageBounds } from "./types.js";
import {
  BLAST_BOTTOM,
  BLAST_LEFT,
  BLAST_RIGHT,
  BLAST_TOP,
  COUNTDOWN_FRAMES,
  DEFAULT_MATCH_FRAMES,
  DEFAULT_STOCKS,
  FLOOR_Y,
  FP_SCALE,
  SHIELD_MAX,
  STAGE_HEIGHT,
  STAGE_WIDTH,
} from "./constants.js";
import { getCharacter, getCharacterForPlayer } from "./characters.js";
import { getStage } from "./stages.js";
import { getFighterProfile, applyCreatedFighterToPlayer } from "./fighterCreation.js";
import { createDefaultAuraState } from "./aura/auraTypes.js";
import { DEFAULT_RULESET } from "./rulesets.js";

export function createInitialGameState(config: GameConfig): GameState {
  const ruleset = config.ruleset ?? DEFAULT_RULESET;
  const stage = getStage(config.stageId);
  const players: PlayerState[] = [];
  const maxStamina = ruleset.staminaHp;

  for (let i = 0; i < config.playerCount; i++) {
    const charId = config.characterIds[i] ?? "ember";
    const spawn = stage.spawnPoints[i] ?? { x: STAGE_WIDTH / 2, y: FLOOR_Y };
    const fighter = getFighterProfile(config, i);
    const character = getCharacterForPlayer({ characterId: charId, fighterSize: fighter.size });

    const player: PlayerState = {
      id: i,
      characterId: charId,
      fighterName: fighter.name,
      fighterSize: fighter.size,
      fighterColor: fighter.color,
      elementEffect: fighter.element,
      burnFramesRemaining: 0,
      slowFramesRemaining: 0,
      slowMultiplierFp: 100,
      airDriftBonusFrames: 0,
      x: spawn.x,
      y: spawn.y,
      vx: 0,
      vy: 0,
      facing: i === 0 ? 1 : -1,
      damage: 0,
      stocks: config.stocks ?? DEFAULT_STOCKS,
      staminaHp: ruleset.matchType === "stamina" ? maxStamina : 0,
      maxStaminaHp: maxStamina,
      score: 0,
      teamId: ruleset.teamMode === "2v2" ? (i < 2 ? 0 : 1) : i,
      actionState: "idle",
      actionFrame: 0,
      hitstunFrames: 0,
      shieldHealth: SHIELD_MAX,
      jumpsRemaining: character.maxJumps,
      jumpsUsed: 0,
      jumpHoldFrames: 0,
      wasJumpHeld: false,
      onGround: true,
      invulnFrames: 0,
      coyoteFrames: 0,
      jumpBufferFrames: 0,
      fastFalling: false,
      currentMoveId: "none",
      hitVictimsThisMove: [],
      aura: createDefaultAuraState(),
    };
    applyCreatedFighterToPlayer(player, fighter);
    players.push(player);
  }

  return {
    frame: 0,
    phase: "countdown",
    config: { ...config, ruleset },
    players,
    stage: stage.bounds,
    countdownFrames: COUNTDOWN_FRAMES,
    matchTimerFrames: config.matchDurationFrames ?? DEFAULT_MATCH_FRAMES,
    winnerId: null,
    hitstopFrames: 0,
    lastHitEvents: [],
    energyAttacks: [],
    energyClashes: [],
  };
}

export function cloneGameState(state: GameState): GameState {
  return {
    ...state,
    config: {
      ...state.config,
      characterIds: [...state.config.characterIds],
      fighterProfiles: state.config.fighterProfiles
        ? state.config.fighterProfiles.map((f) => ({ ...f }))
        : undefined,
      ruleset: state.config.ruleset ? { ...state.config.ruleset } : undefined,
    },
    players: state.players.map((p) => ({ ...p })),
    stage: { ...state.stage },
    energyAttacks: state.energyAttacks?.map((a) => ({ ...a })),
    energyClashes: state.energyClashes?.map((c) => ({ ...c })),
    lastHitEvents: state.lastHitEvents?.map((e) => ({ ...e })) ?? [],
  };
}

export type { StageBounds };
