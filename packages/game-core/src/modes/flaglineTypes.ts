import type { GameState } from "../types.js";
import type { CreatedFighter } from "../createdFighter.js";

export type TeamId = "solar" | "lunar";

export type FlaglineRoomIndex = -2 | -1 | 0 | 1 | 2;

export const TEAM_PUSH_DIRECTION = {
  solar: -1,
  lunar: 1,
} as const;

export type FlaglineRoom = {
  index: FlaglineRoomIndex;
  id: string;
  name: string;
  stageId: string;
  flagCore: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
  solarSpawn: { x: number; y: number }[];
  lunarSpawn: { x: number; y: number }[];
};

export type FlaglineRoomResult = {
  roomIndex: FlaglineRoomIndex;
  winner: TeamId;
  reason: "flagCapture" | "teamWipe" | "overtime";
  frame: number;
};

export type FlaglinePhase =
  | "intro"
  | "roomFight"
  | "roomWon"
  | "transition"
  | "gameWon";

export type FlaglineMetaState = {
  mode: "flaglineClash";
  currentRoomIndex: FlaglineRoomIndex;
  roomsWon: { solar: number; lunar: number };
  roomHistory: FlaglineRoomResult[];
  capture: {
    solar: number;
    lunar: number;
    contested: boolean;
    controllingTeam: TeamId | null;
  };
  phase: FlaglinePhase;
  winningTeam: TeamId | null;
  roomWinner: TeamId | null;
  roomWinReason: FlaglineRoomResult["reason"] | null;
  roomTimerFrames: number;
  transitionFramesRemaining: number;
  introFramesRemaining: number;
};

export type TeamSlot = {
  playerId: number;
  teamId: TeamId;
  fighterId?: string;
  fighter?: CreatedFighter;
  isBot: boolean;
};

export type FlaglineConfig = {
  captureToWin: number;
  captureRatePerSecond: number;
  decayRatePerSecond: number;
  contestedPause: boolean;
  overtimeEnabled: boolean;
  teamWipeWinsRoom: boolean;
  botsEnabled: boolean;
  stocks: number;
  roomTimerSeconds: number | null;
};

export const FLAGLINE_DEFAULTS: FlaglineConfig = {
  captureToWin: 100,
  captureRatePerSecond: 12,
  decayRatePerSecond: 4,
  contestedPause: true,
  overtimeEnabled: true,
  teamWipeWinsRoom: false,
  botsEnabled: true,
  stocks: 3,
  roomTimerSeconds: 180,
};

export type FlaglineClashState = {
  frame: number;
  seed: number;
  flagline: FlaglineMetaState;
  game: GameState;
  teamSlots: TeamSlot[];
  config: FlaglineConfig;
};

export type FlaglineProgressionResult =
  | FlaglineRoomIndex
  | "solarWinsGame"
  | "lunarWinsGame";
