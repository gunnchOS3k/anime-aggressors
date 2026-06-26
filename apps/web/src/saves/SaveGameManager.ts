import type { GameState } from "@anime-aggressors/game-core";
import { createSaveGameRecord } from "@anime-aggressors/game-core";
import { autoSaveLatest, saveGame } from "../storage/saveGameStorage.ts";

const GAME_VERSION = "0.1.0";

export type SaveGameOptions = {
  mode: string;
  title: string;
  ruleset: unknown;
  screenshotDataUrl?: string;
  auto?: boolean;
};

export async function saveCurrentGame(state: GameState, options: SaveGameOptions) {
  const record = createSaveGameRecord({
    gameVersion: GAME_VERSION,
    mode: options.mode,
    title: options.title,
    state,
    ruleset: options.ruleset,
    screenshotDataUrl: options.screenshotDataUrl,
  });

  if (options.auto) {
    await autoSaveLatest(record);
  } else {
    await saveGame(record);
  }
  return record;
}
