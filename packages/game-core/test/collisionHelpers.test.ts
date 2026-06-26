import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  getActiveHitboxesForState,
  getHurtboxes,
  getHurtbox,
  type GameConfig,
} from "../src/index.js";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 1,
};

describe("collision helpers", () => {
  it("getHurtboxes skips defeated players", () => {
    const state = createInitialGameState(config);
    state.players[1].actionState = "defeated";
    const boxes = getHurtboxes(state.players);
    assert.equal(boxes.length, 1);
    assert.equal(boxes[0].ownerId, 0);
  });

  it("getActiveHitboxesForState is empty outside attack active frames", () => {
    const state = createInitialGameState(config);
    state.players[0].actionState = "attacking";
    state.players[0].actionFrame = 0;
    assert.equal(getActiveHitboxesForState(state.players).length, 0);
  });

  it("hurtbox matches player position", () => {
    const state = createInitialGameState(config);
    const p = state.players[0];
    const hb = getHurtbox(p);
    assert.equal(hb.ownerId, p.id);
    assert.ok(hb.w > 0 && hb.h > 0);
  });
});
