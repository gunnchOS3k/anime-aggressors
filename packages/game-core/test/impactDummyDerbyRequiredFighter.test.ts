import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createInitialDerbyState, getDefaultCreatedFighter } from "../src/index.js";

describe("impact dummy derby required fighter", () => {
  it("derby state stores selected fighter", () => {
    const fighter = getDefaultCreatedFighter(0);
    const state = createInitialDerbyState(42, 0, fighter);
    assert.equal(state.fighter.id, fighter.id);
    assert.ok(state.fighter.name.length > 0);
  });

  it("derby sim uses fighter for combo window", () => {
    const fighter = getDefaultCreatedFighter(1);
    const state = createInitialDerbyState(7, 0, fighter);
    assert.ok(state.comboWindowFrames > 0);
  });
});
