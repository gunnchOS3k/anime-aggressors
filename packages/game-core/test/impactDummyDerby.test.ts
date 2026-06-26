import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  resetDerbyForRetry,
  replayDerby,
  derbyStateHash,
  DAMAGE_PHASE_FRAMES,
  DERBY_COUNTDOWN_FRAMES,
} from "../src/modes/impactDummyDerby.js";

describe("Impact Dummy Derby", () => {
  it("damage phase increases dummy percent", () => {
    let s = createInitialDerbyState(9);
    s.phase = "damage_phase";
    s.phaseFrame = 0;
    s.player.x = 1190 * 256;
    s.dummy.x = 1200 * 256;

    for (let i = 0; i < 30; i++) {
      s = simulateDerbyFrame(s, { attack: i % 8 === 0, right: true });
    }
    assert.ok(s.dummy.damage > 0);
    assert.ok(s.totalDamageDealt > 0);
  });

  it("final launch distance increases with damage", () => {
    let low = createInitialDerbyState(1);
    low.phase = "launch_window";
    low.phaseFrame = 0;
    low.kineticBatEquipped = true;
    low.player.x = 1150 * 256;
    low.dummy.x = 1200 * 256;
    low.dummy.damage = 20;
    low = simulateDerbyFrame(low, { attack: true });
    while (low.phase !== "landed" && low.phase !== "results" && low.frame < 600) {
      low = simulateDerbyFrame(low, {});
    }

    let high = createInitialDerbyState(1);
    high.phase = "launch_window";
    high.phaseFrame = 0;
    high.kineticBatEquipped = true;
    high.player.x = 1150 * 256;
    high.dummy.x = 1200 * 256;
    high.dummy.damage = 120;
    high = simulateDerbyFrame(high, { attack: true });
    while (high.phase !== "landed" && high.phase !== "results" && high.frame < 600) {
      high = simulateDerbyFrame(high, {});
    }

    assert.ok(high.distance >= low.distance);
  });

  it("kinetic bat final hit launches farther than normal attack only", () => {
    let bat = createInitialDerbyState(2);
    bat.phase = "launch_window";
    bat.kineticBatEquipped = true;
    bat.player.x = 1150 * 256;
    bat.dummy.x = 1200 * 256;
    bat.dummy.damage = 80;
    bat = simulateDerbyFrame(bat, { attack: true });
    while (bat.phase !== "landed" && bat.phase !== "results" && bat.frame < 800) {
      bat = simulateDerbyFrame(bat, {});
    }

    let normal = createInitialDerbyState(2);
    normal.phase = "damage_phase";
    normal.player.x = 1190 * 256;
    normal.dummy.x = 1200 * 256;
    normal.dummy.damage = 80;
    normal = simulateDerbyFrame(normal, { attack: true });
    const distAfterNormal = Math.abs(normal.dummy.x - 1200 * 256);

    assert.ok(bat.distance > distAfterNormal);
  });

  it("timer transitions states correctly", () => {
    let s = createInitialDerbyState(3);
    s = simulateDerbyFrame(s, {});
    assert.equal(s.phase, "countdown");

    for (let i = 0; i < DERBY_COUNTDOWN_FRAMES; i++) s = simulateDerbyFrame(s, {});
    assert.equal(s.phase, "damage_phase");

    for (let i = 0; i < DAMAGE_PHASE_FRAMES; i++) s = simulateDerbyFrame(s, {});
    assert.equal(s.phase, "launch_window");
    assert.equal(s.kineticBatEquipped, true);
  });

  it("same input log produces same hash", () => {
    const initial = createInitialDerbyState(42);
    const inputs = Array.from({ length: 200 }, (_, i) => ({
      right: i % 4 === 0,
      attack: i % 17 === 0,
      jump: i === 50,
    }));
    const a = replayDerby(initial, inputs);
    const b = replayDerby(initial, inputs);
    assert.equal(a.hash, b.hash);
    assert.equal(derbyStateHash(a.final), derbyStateHash(b.final));
  });

  it("retry resets state correctly", () => {
    let s = createInitialDerbyState(5);
    s.dummy.damage = 99;
    s.score = 500;
    s.bestScore = 500;
    s.phase = "results";
    const retry = resetDerbyForRetry(s);
    assert.equal(retry.phase, "countdown");
    assert.equal(retry.dummy.damage, 0);
    assert.equal(retry.bestScore, 500);
  });
});
