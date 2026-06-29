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

describe("impact dummy derby loop", () => {
  it("damage phase transitions to final launch phase", () => {
    const s = advanceToFinalLaunch();
    assert.equal(s.phase, "finalLaunch");
    assert.equal(s.kineticBat.equipped, true);
  });

  it("final launch can transition to flight after bat hit", () => {
    let s = advanceToFinalLaunch();
    s.dummy.damage = 50;
    s.player.x = 1150 * 256;
    s.dummy.x = 1200 * 256;
    for (let i = 0; i < 80; i++) {
      s = simulateDerbyFrame(s, { attack: i === 0 });
      if (s.phase === "flight") break;
    }
    assert.ok(s.phase === "flight" || s.dummy.launched);
  });

  it("flight transitions to results after landing", () => {
    let s = advanceToFinalLaunch();
    s.dummy.damage = 80;
    s.player.x = 1150 * 256;
    s.dummy.x = 1200 * 256;
    for (let i = 0; i < 120; i++) {
      s = simulateDerbyFrame(s, { attack: i === 0 });
    }
    let guard = 0;
    while (s.phase !== "results" && guard < 900) {
      s = simulateDerbyFrame(s, {});
      guard += 1;
    }
    assert.equal(s.phase, "results");
    assert.ok(s.totalHits > 0 || s.dummy.launched);
  });
});
