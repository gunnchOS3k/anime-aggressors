import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { resetCareerDbForTests } from "../src/storage/careerDb.ts";
import { saveReplay, getReplay, listReplays, deleteReplay } from "../src/storage/replayStorage.ts";
import {
  createReplayRecord,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";

beforeEach(async () => {
  await resetCareerDbForTests();
});

describe("replayStorage", () => {
  it("save/load/delete replay", async () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 9);
    const initial = createInitialGameState(config);
    const record = createReplayRecord({
      matchId: "m1",
      gameVersion: "0.1.0",
      mode: "playMatch",
      ruleset: DEFAULT_RULESET,
      initialState: initial,
      inputLog: [],
      title: "Test",
    });

    await saveReplay(record);
    const loaded = await getReplay(record.id);
    assert.equal(loaded?.title, "Test");

    const list = await listReplays();
    assert.equal(list.length, 1);

    await deleteReplay(record.id);
    assert.equal((await listReplays()).length, 0);
  });
});
