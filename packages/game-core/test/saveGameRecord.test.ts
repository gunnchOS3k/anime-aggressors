import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createSaveGameRecord,
  loadSaveGameState,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  hashState,
  simulateFrame,
} from "../src/index.js";

describe("save game record", () => {
  it("stores serialized state", () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 11);
    const state = createInitialGameState(config);

    const save = createSaveGameRecord({
      gameVersion: "0.1.0",
      mode: "playMatch",
      title: "Mid Match",
      state,
      ruleset: DEFAULT_RULESET,
    });

    assert.ok(save.stateSerialized.length > 0);
    assert.equal(save.currentFrame, state.frame);
    assert.equal(save.title, "Mid Match");
  });

  it("saved game can be loaded", () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 22);
    let state = createInitialGameState(config);
    for (let i = 0; i < 10; i++) {
      state = simulateFrame(state, [
        {
          frame: i,
          playerId: 0,
          left: false,
          right: true,
          up: false,
          down: false,
          jump: false,
          attack: false,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        },
        {
          frame: i,
          playerId: 1,
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
      ]);
    }

    const hashBefore = hashState(state);
    const save = createSaveGameRecord({
      gameVersion: "0.1.0",
      mode: "playMatch",
      title: "Saved",
      state,
      ruleset: DEFAULT_RULESET,
    });

    const loaded = loadSaveGameState(save);
    assert.equal(hashState(loaded), hashBefore);
    assert.equal(loaded.frame, state.frame);
  });
});
