import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { computeDerbyScore, gradeFromScore } from "../src/modes/impactDummyDerbyScoring.js";
import { createInitialDerbyState } from "../src/modes/impactDummyDerby.js";
import { FP_SCALE } from "../src/constants.js";

describe("impact dummy derby scoring", () => {
  it("score increases with distance", () => {
    const low = createInitialDerbyState(1);
    low.finalDistance = 50 * FP_SCALE;
    low.dummy.damage = 20;
    low.finalLaunchSpeed = 50;
    low.bestCombo = 2;

    const high = createInitialDerbyState(1);
    high.finalDistance = 200 * FP_SCALE;
    high.dummy.damage = 20;
    high.finalLaunchSpeed = 50;
    high.bestCombo = 2;

    assert.ok(computeDerbyScore(high) > computeDerbyScore(low));
  });

  it("grade thresholds", () => {
    assert.equal(gradeFromScore(100), "D");
    assert.equal(gradeFromScore(750), "C");
    assert.equal(gradeFromScore(1500), "B");
    assert.equal(gradeFromScore(2500), "A");
    assert.equal(gradeFromScore(4000), "S");
    assert.equal(gradeFromScore(7000), "SS");
  });
});
