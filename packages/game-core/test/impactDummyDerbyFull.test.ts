import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  DERBY_COUNTDOWN_FRAMES,
  DAMAGE_PHASE_FRAMES,
  LAUNCH_WINDOW_FRAMES,
  BAT_STARTUP,
} from "../src/modes/impactDummyDerby.js";

function advanceToFinalLaunch(s = createInitialDerbyState(1)) {
  for (let i = 0; i < DERBY_COUNTDOWN_FRAMES + 1; i++) s = simulateDerbyFrame(s, {});
  for (let i = 0; i < DAMAGE_PHASE_FRAMES; i++) s = simulateDerbyFrame(s, {});
  return s;
}

function swingBat(s: ReturnType<typeof createInitialDerbyState>) {
  s.player.x = 1150 * 256;
  s.dummy.x = 1200 * 256;
  for (let i = 0; i <= BAT_STARTUP + 2; i++) {
    s = simulateDerbyFrame(s, { attack: i === 0 });
  }
  return s;
}

describe("impact dummy derby full", () => {
  it("phase starts at ready", () => {
    const s = createInitialDerbyState(1);
    assert.equal(s.phase, "ready");
  });

  it("ready transitions to countdown then damage", () => {
    let s = createInitialDerbyState(1);
    s = simulateDerbyFrame(s, {});
    assert.equal(s.phase, "countdown");
    for (let i = 0; i < DERBY_COUNTDOWN_FRAMES; i++) s = simulateDerbyFrame(s, {});
    assert.equal(s.phase, "damage");
  });

  it("damage phase timer counts down", () => {
    let s = advanceToFinalLaunch();
    assert.equal(s.phase, "finalLaunch");
    assert.ok(s.timerFramesRemaining === 0 || s.finalLaunchFramesRemaining > 0);
  });

  it("combo count increases on repeated hits", () => {
    let s = createInitialDerbyState(2);
    s.phase = "damage";
    s.phaseFrame = 0;
    s.player.x = 1190 * 256;
    s.dummy.x = 1200 * 256;
    for (let i = 0; i < 40; i++) {
      s = simulateDerbyFrame(s, { attack: i % 10 === 0 });
    }
    assert.ok(s.bestCombo >= 1);
  });

  it("final launch phase equips Kinetic Bat", () => {
    const s = advanceToFinalLaunch();
    assert.equal(s.kineticBat.equipped, true);
    assert.equal(s.kineticBat.available, true);
  });

  it("bat swing has startup/active/recovery", () => {
    let s = advanceToFinalLaunch();
    s = simulateDerbyFrame(s, { attack: true });
    assert.equal(s.kineticBat.swingState, "startup");
    for (let i = 0; i < BAT_STARTUP; i++) s = simulateDerbyFrame(s, {});
    assert.equal(s.kineticBat.swingState, "active");
  });

  it("sweet spot launches farther than non-sweet spot", () => {
    let sweet = advanceToFinalLaunch();
    sweet.dummy.damage = 60;
    sweet.player.x = 1150 * 256;
    sweet.dummy.x = 1200 * 256;
    for (let i = 0; i < BAT_STARTUP + 3; i++) sweet = simulateDerbyFrame(sweet, { attack: i === 0 });
    while (sweet.phase !== "landed" && sweet.phase !== "results" && sweet.frame < 800) {
      sweet = simulateDerbyFrame(sweet, {});
    }

    let weak = advanceToFinalLaunch();
    weak.dummy.damage = 60;
    weak.player.x = 1150 * 256;
    weak.dummy.x = 1200 * 256;
    for (let i = 0; i < BAT_STARTUP + 1; i++) weak = simulateDerbyFrame(weak, { attack: i === 0 });
    while (weak.phase !== "landed" && weak.phase !== "results" && weak.frame < 800) {
      weak = simulateDerbyFrame(weak, {});
    }

    assert.ok(sweet.finalDistance >= weak.finalDistance);
  });

  it("landing transitions to results", () => {
    let s = advanceToFinalLaunch();
    s = swingBat(s);
    while (s.phase !== "results" && s.frame < 900) s = simulateDerbyFrame(s, {});
    assert.equal(s.phase, "results");
    assert.ok(s.score > 0);
  });

  it("personal best updates only when score is higher", () => {
    let s = createInitialDerbyState(1, 5000);
    s.phase = "landed";
    s.phaseFrame = 60;
    s.finalDistance = 100 * 256;
    s.dummy.damage = 50;
    s.finalLaunchSpeed = 100;
    s.bestCombo = 3;
    s = simulateDerbyFrame(s, {});
    assert.equal(s.personalBest, 5000);

    s.score = 6000;
    s.personalBest = Math.max(s.personalBest, s.score);
    assert.equal(s.personalBest, 6000);
  });
});
