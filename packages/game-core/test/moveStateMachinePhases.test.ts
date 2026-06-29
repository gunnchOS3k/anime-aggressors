import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getMovePhase, fightingTimingFromFrameData } from "../src/combat/movePhases.js";

describe("move state machine phases", () => {
  it("progresses startup active recovery", () => {
    const timing = fightingTimingFromFrameData({ startup: 4, active: 3, recovery: 10 });
    assert.equal(getMovePhase(0, timing), "startup");
    assert.equal(getMovePhase(4, timing), "active");
    assert.equal(getMovePhase(7, timing), "cancelWindow");
  });
});
