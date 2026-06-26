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
import { getCharacter } from "./characters.js";
import { getStage } from "./stages.js";
import { getFighterProfile, applyCreatedFighterToPlayer } from "./fighterCreation.js";

export function createInitialGameState(config: GameConfig): GameState {
  const stage = getStage(config.stageId);
  const players: PlayerState[] = [];

  for (let i = 0; i < config.playerCount; i++) {
    const charId = config.characterIds[i] ?? "ember";
    const spawn = stage.spawnPoints[i] ?? { x: STAGE_WIDTH / 2, y: FLOOR_Y - 64 * FP_SCALE };
    const character = getCharacter(charId);

    const fighter = getFighterProfile(config, i);

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
      actionState: "idle",
      actionFrame: 0,
      hitstunFrames: 0,
      shieldHealth: SHIELD_MAX,
      jumpsRemaining: character.maxJumps,
      onGround: true,
      invulnFrames: 0,
      coyoteFrames: 0,
      jumpBufferFrames: 0,
      fastFalling: false,
      currentMoveId: "none",
    };
    applyCreatedFighterToPlayer(player, fighter);
    players.push(player);
  }

  return {
    frame: 0,
    phase: "countdown",
    config,
    players,
    stage: stage.bounds,
    countdownFrames: COUNTDOWN_FRAMES,
    matchTimerFrames: config.matchDurationFrames ?? DEFAULT_MATCH_FRAMES,
    winnerId: null,
    hitstopFrames: 0,
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
    },
    players: state.players.map((p) => ({ ...p })),
    stage: { ...state.stage },
  };
}

export type { StageBounds };
