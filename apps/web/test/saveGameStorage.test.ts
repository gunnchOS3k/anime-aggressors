import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { resetCareerDbForTests } from "../src/storage/careerDb.ts";
import {
  saveGame,
  getSavedGame,
  listSavedGames,
  deleteSavedGame,
} from "../src/storage/saveGameStorage.ts";
import {
  createSaveGameRecord,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";

beforeEach(async () => {
  await resetCareerDbForTests();
});

describe("saveGameStorage", () => {
  it("save/load/delete saved game", async () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 4);
    const state = createInitialGameState(config);
    const record = createSaveGameRecord({
      gameVersion: "0.1.0",
      mode: "playMatch",
      title: "Snapshot",
      state,
      ruleset: DEFAULT_RULESET,
    });

    await saveGame(record);
    const loaded = await getSavedGame(record.id);
    assert.equal(loaded?.title, "Snapshot");
    assert.equal((await listSavedGames()).length, 1);

    await deleteSavedGame(record.id);
    assert.equal((await listSavedGames()).length, 0);
  });
});
