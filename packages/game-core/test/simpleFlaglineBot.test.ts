import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialFlaglineState,
  generateFlaglineBotInput,
  simulateFlaglineFrame,
} from "../src/index.js";

describe("simpleFlaglineBot", () => {
  it("generates inputs for bot slots", () => {
    const state = createInitialFlaglineState(5);
    const input = generateFlaglineBotInput(state, 2, 1);
    assert.equal(input.playerId, 2);
    assert.equal(typeof input.left, "boolean");
  });

  it("bot inputs are deterministic across frames", () => {
    const state = createInitialFlaglineState(11);
    let s = state;
    const hashes: string[] = [];
    for (let f = 0; f < 20; f++) {
      s = simulateFlaglineFrame(s, []);
      hashes.push(JSON.stringify(generateFlaglineBotInput(s, 2, f)));
    }
    const again = createInitialFlaglineState(11);
    let s2 = again;
    for (let f = 0; f < 20; f++) {
      s2 = simulateFlaglineFrame(s2, []);
      assert.equal(JSON.stringify(generateFlaglineBotInput(s2, 2, f)), hashes[f]);
    }
  });
});
