import type { SaveGameRecord } from "./types.js";
import type { GameState } from "../types.js";
import { serializeState, deserializeState } from "../hash.js";

export function createSaveGameRecord(args: {
  gameVersion: string;
  mode: string;
  title: string;
  state: GameState;
  ruleset: unknown;
  screenshotDataUrl?: string;
}): SaveGameRecord {
  const now = new Date().toISOString();
  return {
    id: `save-${Date.now()}`,
    createdAt: now,
    updatedAt: now,
    gameVersion: args.gameVersion,
    mode: args.mode,
    title: args.title,
    stateSerialized: serializeState(args.state),
    currentFrame: args.state.frame,
    ruleset: args.ruleset,
    playerNames: args.state.players.map((p) => `P${p.id + 1}`),
    fighterNames: args.state.players.map((p) => p.fighterName),
    screenshotDataUrl: args.screenshotDataUrl,
  };
}

export function loadSaveGameState(record: SaveGameRecord): GameState {
  return deserializeState(record.stateSerialized) as GameState;
}
