import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  DERBY_COUNTDOWN_FRAMES,
  DAMAGE_PHASE_FRAMES,
} from "../src/modes/impactDummyDerby.js";

function advanceToFinalLaunch(s = createInitialDerbyState(1)) {
  for (let i = 0; i < DERBY_COUNTDOWN_FRAMES + 1; i++) s = simulateDerbyFrame(s, {});
  for (let i = 0; i < DAMAGE_PHASE_FRAMES; i++) s = simulateDerbyFrame(s, {});
  return s;
}

describe("impact dummy derby full loop", () => {
  it("reaches results only after launch and landing", () => {
    let s = advanceToFinalLaunch();
    s.dummy.damage = 70;
    s.player.x = 1150 * 256;
    s.dummy.x = 1200 * 256;
    for (let i = 0; i < 120; i++) s = simulateDerbyFrame(s, { attack: i === 0 });
    let guard = 0;
    while (s.phase !== "results" && guard < 900) {
      s = simulateDerbyFrame(s, {});
      guard += 1;
    }
    assert.equal(s.phase, "results");
    assert.ok(s.totalHits > 0 || s.dummy.launched);
  });
});
