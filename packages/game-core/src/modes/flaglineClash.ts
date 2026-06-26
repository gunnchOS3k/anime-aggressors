import type { GameConfig, GameState, InputFrame } from "../types.js";
import { SIM_HZ, COUNTDOWN_FRAMES } from "../constants.js";
import { createInitialGameState, cloneGameState } from "../state.js";
import { simulateFrame } from "../simulate.js";
import { hashState } from "../hash.js";
import type { CreatedFighter } from "../createdFighter.js";
import { getDefaultCreatedFighter } from "../createdFighter.js";
import { DEFAULT_RULESET } from "../rulesets.js";
import {
  FLAGLINE_DEFAULTS,
  type FlaglineClashState,
  type FlaglineConfig,
  type FlaglineMetaState,
  type FlaglineRoomIndex,
  type TeamId,
  type TeamSlot,
} from "./flaglineTypes.js";
import { getFlaglineRoom } from "./flaglineMaps.js";
import { getNextRoomIndex } from "./flaglineProgression.js";
import {
  updateFlagCoreCapture,
  checkCaptureWin,
  resetCaptureMeters,
  countTeamsInCore,
} from "./flaglineObjective.js";
import { generateFlaglineBotInput } from "../bots/simpleFlaglineBot.js";

const INTRO_FRAMES = COUNTDOWN_FRAMES;
const TRANSITION_FRAMES = 2 * SIM_HZ;

export function createDefaultTeamSlots(fighters?: CreatedFighter[]): TeamSlot[] {
  const f0 = fighters?.[0] ?? getDefaultCreatedFighter(0);
  const f1 = fighters?.[1] ?? getDefaultCreatedFighter(1);
  const f2 = fighters?.[2] ?? getDefaultCreatedFighter(2);
  const f3 = fighters?.[3] ?? getDefaultCreatedFighter(3);
  return [
    { playerId: 0, teamId: "solar", fighter: f0, fighterId: f0.id, isBot: false },
    { playerId: 1, teamId: "lunar", fighter: f1, fighterId: f1.id, isBot: false },
    { playerId: 2, teamId: "solar", fighter: f2, fighterId: f2.id, isBot: true },
    { playerId: 3, teamId: "lunar", fighter: f3, fighterId: f3.id, isBot: true },
  ];
}

function createFlaglineMeta(startRoom: FlaglineRoomIndex = 0): FlaglineMetaState {
  return {
    mode: "flaglineClash",
    currentRoomIndex: startRoom,
    roomsWon: { solar: 0, lunar: 0 },
    roomHistory: [],
    capture: { solar: 0, lunar: 0, contested: false, controllingTeam: null },
    phase: "intro",
    winningTeam: null,
    roomWinner: null,
    roomWinReason: null,
    roomTimerFrames: FLAGLINE_DEFAULTS.roomTimerSeconds
      ? FLAGLINE_DEFAULTS.roomTimerSeconds * SIM_HZ
      : 99 * 60 * SIM_HZ,
    transitionFramesRemaining: 0,
    introFramesRemaining: INTRO_FRAMES,
  };
}

function buildGameConfig(
  roomIndex: FlaglineRoomIndex,
  teamSlots: TeamSlot[],
  config: FlaglineConfig,
  seed: number,
): GameConfig {
  const room = getFlaglineRoom(roomIndex);
  const fighters = teamSlots.map((s) => s.fighter ?? getDefaultCreatedFighter(s.playerId));
  return {
    playerCount: 4,
    stocks: config.stocks,
    matchDurationFrames: config.roomTimerSeconds ? config.roomTimerSeconds * SIM_HZ : 99 * 60 * SIM_HZ,
    stageId: room.stageId,
    characterIds: fighters.map((f) => `created:${f.id}`),
    fighterProfiles: fighters,
    ruleset: {
      ...DEFAULT_RULESET,
      matchType: "stock",
      teamMode: "2v2",
      playerCount: 4,
      stocks: config.stocks,
      stageId: room.stageId,
    },
    seed,
  };
}

function spawnPlayersForRoom(game: GameState, roomIndex: FlaglineRoomIndex, teamSlots: TeamSlot[]): GameState {
  const next = cloneGameState(game);
  const room = getFlaglineRoom(roomIndex);
  for (const slot of teamSlots) {
    const p = next.players[slot.playerId];
    if (!p) continue;
    const spawns = slot.teamId === "solar" ? room.solarSpawn : room.lunarSpawn;
    const spawnIdx = slot.teamId === "solar" ? (slot.playerId === 0 ? 0 : 1) : slot.playerId === 1 ? 0 : 1;
    const spawn = spawns[spawnIdx] ?? spawns[0];
    p.x = spawn.x;
    p.y = spawn.y;
    p.vx = 0;
    p.vy = 0;
    p.damage = 0;
    p.stocks = next.config.stocks;
    p.actionState = "idle";
    p.actionFrame = 0;
    p.hitstunFrames = 0;
    p.onGround = true;
    p.teamId = slot.teamId === "solar" ? 0 : 1;
    p.facing = slot.teamId === "solar" ? 1 : -1;
  }
  return next;
}

export function createInitialFlaglineState(
  seed = 1,
  config: FlaglineConfig = FLAGLINE_DEFAULTS,
  teamSlots: TeamSlot[] = createDefaultTeamSlots(),
  startRoom: FlaglineRoomIndex = 0,
): FlaglineClashState {
  const game = createInitialGameState(buildGameConfig(startRoom, teamSlots, config, seed));
  return {
    frame: 0,
    seed,
    flagline: createFlaglineMeta(startRoom),
    game: spawnPlayersForRoom(game, startRoom, teamSlots),
    teamSlots: teamSlots.map((s) => ({ ...s })),
    config: { ...config },
  };
}

function cloneFlaglineState(s: FlaglineClashState): FlaglineClashState {
  return {
    ...s,
    flagline: {
      ...s.flagline,
      roomsWon: { ...s.flagline.roomsWon },
      roomHistory: [...s.flagline.roomHistory],
      capture: { ...s.flagline.capture },
    },
    game: cloneGameState(s.game),
    teamSlots: s.teamSlots.map((t) => ({ ...t })),
    config: { ...s.config },
  };
}

function teamAlive(players: GameState["players"], teamSlots: TeamSlot[], team: TeamId): boolean {
  return teamSlots
    .filter((s) => s.teamId === team)
    .some((s) => {
      const p = players[s.playerId];
      return p && p.actionState !== "defeated" && p.stocks > 0;
    });
}

function resolveRoomWin(
  state: FlaglineClashState,
  winner: TeamId,
  reason: "flagCapture" | "teamWipe" | "overtime",
): FlaglineClashState {
  const next = cloneFlaglineState(state);
  next.flagline.roomWinner = winner;
  next.flagline.roomWinReason = reason;
  next.flagline.phase = "roomWon";
  next.flagline.roomsWon[winner] += 1;
  next.flagline.roomHistory.push({
    roomIndex: next.flagline.currentRoomIndex,
    winner,
    reason,
    frame: next.frame,
  });

  const progression = getNextRoomIndex(next.flagline.currentRoomIndex, winner);
  if (progression === "solarWinsGame" || progression === "lunarWinsGame") {
    next.flagline.phase = "gameWon";
    next.flagline.winningTeam = progression === "solarWinsGame" ? "solar" : "lunar";
    return next;
  }
  return startTransition(next, progression);
}

function startTransition(state: FlaglineClashState, nextRoom: FlaglineRoomIndex): FlaglineClashState {
  const next = cloneFlaglineState(state);
  next.flagline.currentRoomIndex = nextRoom;
  next.flagline = resetCaptureMeters(next.flagline);
  next.flagline.phase = "transition";
  next.flagline.transitionFramesRemaining = TRANSITION_FRAMES;
  const cfg = buildGameConfig(nextRoom, next.teamSlots, next.config, next.seed);
  next.game = spawnPlayersForRoom(createInitialGameState(cfg), nextRoom, next.teamSlots);
  return next;
}

export function mergeFlaglineInputs(
  state: FlaglineClashState,
  humanInputs: InputFrame[],
  frame: number,
): InputFrame[] {
  const inputs: InputFrame[] = [];
  for (let i = 0; i < 4; i++) {
    const slot = state.teamSlots.find((s) => s.playerId === i);
    if (slot?.isBot) {
      inputs.push(generateFlaglineBotInput(state, i, frame));
    } else {
      inputs.push(
        humanInputs.find((inp) => inp.playerId === i) ?? {
          frame,
          playerId: i,
          left: false,
          right: false,
          up: false,
          down: false,
          jump: false,
          attack: false,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        },
      );
    }
  }
  return inputs;
}

export function simulateFlaglineFrame(
  state: FlaglineClashState,
  humanInputs: InputFrame[],
): FlaglineClashState {
  const next = cloneFlaglineState(state);
  next.frame += 1;

  if (next.flagline.phase === "intro") {
    next.flagline.introFramesRemaining -= 1;
    if (next.flagline.introFramesRemaining <= 0) {
      next.flagline.phase = "roomFight";
      next.game.phase = "countdown";
      next.game.countdownFrames = COUNTDOWN_FRAMES;
    }
    return next;
  }

  if (next.flagline.phase === "roomWon") {
    return next;
  }

  if (next.flagline.phase === "transition") {
    next.flagline.transitionFramesRemaining -= 1;
    if (next.flagline.transitionFramesRemaining <= 0) {
      next.flagline.phase = "roomFight";
      next.game.phase = "countdown";
      next.game.countdownFrames = COUNTDOWN_FRAMES;
    }
    return next;
  }

  if (next.flagline.phase === "gameWon") return next;

  const inputs = mergeFlaglineInputs(next, humanInputs, next.frame);
  next.game = simulateFrame(next.game, inputs);

  const room = getFlaglineRoom(next.flagline.currentRoomIndex);
  next.flagline = updateFlagCoreCapture(
    next.flagline,
    next.game.players,
    next.teamSlots,
    room,
    next.config,
    1,
  );

  const captureWinner = checkCaptureWin(next.flagline, next.config);
  if (captureWinner) {
    return resolveRoomWin(next, captureWinner, "flagCapture");
  }

  if (next.config.teamWipeWinsRoom) {
    const solarAlive = teamAlive(next.game.players, next.teamSlots, "solar");
    const lunarAlive = teamAlive(next.game.players, next.teamSlots, "lunar");
    if (solarAlive && !lunarAlive) return resolveRoomWin(next, "solar", "teamWipe");
    if (lunarAlive && !solarAlive) return resolveRoomWin(next, "lunar", "teamWipe");
  }

  if (next.flagline.roomTimerFrames > 0) {
    next.flagline.roomTimerFrames -= 1;
    if (next.flagline.roomTimerFrames <= 0 && next.config.overtimeEnabled) {
      const counts = countTeamsInCore(next.game.players, next.teamSlots, room);
      if (counts.solar > counts.lunar) return resolveRoomWin(next, "solar", "overtime");
      if (counts.lunar > counts.solar) return resolveRoomWin(next, "lunar", "overtime");
    }
  }

  return next;
}

export function flaglineStateHash(state: FlaglineClashState): string {
  return `${hashState(state.game)}-${state.flagline.currentRoomIndex}-${state.flagline.capture.solar}-${state.flagline.capture.lunar}-${state.flagline.phase}`;
}

export function serializeFlaglineState(state: FlaglineClashState): string {
  return JSON.stringify(state);
}

export function deserializeFlaglineState(json: string): FlaglineClashState | null {
  try {
    return JSON.parse(json) as FlaglineClashState;
  } catch {
    return null;
  }
}
