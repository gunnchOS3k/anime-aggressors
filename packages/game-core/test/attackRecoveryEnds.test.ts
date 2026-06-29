import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { isMoveComplete } from "../src/moves.js";
import { NEUTRAL_ATTACK } from "../src/frameData.js";

describe("attack recovery ends", () => {
  it("neutral attack completes after total frames", () => {
    const total = NEUTRAL_ATTACK.startup + NEUTRAL_ATTACK.active + NEUTRAL_ATTACK.recovery;
    assert.equal(isMoveComplete(NEUTRAL_ATTACK, total + 1), true);
    assert.equal(isMoveComplete(NEUTRAL_ATTACK, total), false);
  });
});
