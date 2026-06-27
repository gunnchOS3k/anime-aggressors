import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  PLATFORM_LEFT,
  PLATFORM_RIGHT,
} from "../src/modes/impactDummyDerby.js";

describe("impact dummy derby physics", () => {
  it("dummy cannot leave early during barrier phase", () => {
    let s = createInitialDerbyState(3);
    s.phase = "damage";
    s.dummy.x = PLATFORM_RIGHT - 64;
    s.dummy.vx = 500;
    s = simulateDerbyFrame(s, {});
    assert.ok(s.dummy.x <= PLATFORM_RIGHT);
  });

  it("attacking dummy increases damage", () => {
    let s = createInitialDerbyState(4);
    s.phase = "damage";
    s.player.x = 1190 * 256;
    s.dummy.x = 1200 * 256;
    const before = s.dummy.damage;
    for (let i = 0; i < 20; i++) {
      s = simulateDerbyFrame(s, { attack: i % 9 === 0 });
    }
    assert.ok(s.dummy.damage > before);
  });

  it("flight phase measures distance", () => {
    let s = createInitialDerbyState(5);
    s.phase = "flight";
    s.dummy.launched = true;
    s.launchOriginX = 1200 * 256;
    s.dummy.x = 1200 * 256;
    s.dummy.vx = 80;
    s.dummy.vy = -40;
    for (let i = 0; i < 30; i++) s = simulateDerbyFrame(s, {});
    assert.ok(s.flightDistance > 0);
  });
});
