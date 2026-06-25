import type { GameState, InputFrame } from "@anime-aggressors/game-core";

export type InputConfirmation = {
  frame: number;
  playerId: number;
  confirmed: boolean;
};

export type RollbackStats = {
  rollbackCount: number;
  lastRollbackFrame: number;
  desyncDetected: boolean;
  expectedHash: string | null;
  actualHash: string | null;
};

export type RollbackSessionConfig = {
  snapshotInterval: number;
  maxRollbackFrames: number;
  playerCount: number;
};

export type RollbackEvent =
  | { type: "rollback"; fromFrame: number; toFrame: number; count: number }
  | { type: "desync"; frame: number; expected: string; actual: string };
