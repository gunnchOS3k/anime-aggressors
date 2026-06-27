import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  buildCreatedFighter,
} from "../src/index.js";
import { BAT_STARTUP } from "../src/modes/impactDummyDerbyPhysics.js";

describe("impact dummy derby elements", () => {
  it("red burn increases dummy damage over time", () => {
    const red = buildCreatedFighter({ name: "Red", size: "medium", color: "red", id: "red-1" });
    let s = createInitialDerbyState(1, 0, red);
    s.phase = "damage";
    s.player.x = 1190 * 256;
    s.dummy.x = 1200 * 256;
    s = simulateDerbyFrame(s, { attack: true });
    const afterHit = s.dummy.damage;
    for (let i = 0; i < 60; i++) s = simulateDerbyFrame(s, {});
    assert.ok(s.dummy.damage > afterHit);
  });

  it("blue frost slows dummy during damage phase", () => {
    const blue = buildCreatedFighter({ name: "Blue", size: "medium", color: "blue", id: "blue-1" });
    let s = createInitialDerbyState(2, 0, blue);
    s.phase = "damage";
    s.player.x = 1190 * 256;
    s.dummy.x = 1200 * 256;
    for (let i = 0; i < 30; i++) {
      s = simulateDerbyFrame(s, { attack: i % 10 === 0 });
      if (s.dummy.slowFramesRemaining > 0) break;
    }
    assert.ok(s.dummy.slowFramesRemaining > 0);
  });

  it("large fighter launches farther than small fighter", () => {
    const small = buildCreatedFighter({ name: "S", size: "small", color: "orange", id: "s-1" });
    const large = buildCreatedFighter({ name: "L", size: "large", color: "orange", id: "l-1" });

    let sSmall = createInitialDerbyState(10, 0, small);
    sSmall.phase = "finalLaunch";
    sSmall.kineticBat.equipped = true;
    sSmall.dummy.damage = 80;
    sSmall.player.x = 1150 * 256;
    sSmall.dummy.x = 1200 * 256;
    for (let i = 0; i <= BAT_STARTUP + 3; i++) {
      sSmall = simulateDerbyFrame(sSmall, { attack: i === 0 });
    }
    while (sSmall.phase !== "landed" && sSmall.phase !== "results" && sSmall.frame < 900) {
      sSmall = simulateDerbyFrame(sSmall, {});
    }

    let sLarge = createInitialDerbyState(10, 0, large);
    sLarge.phase = "finalLaunch";
    sLarge.kineticBat.equipped = true;
    sLarge.dummy.damage = 80;
    sLarge.player.x = 1150 * 256;
    sLarge.dummy.x = 1200 * 256;
    for (let i = 0; i <= BAT_STARTUP + 3; i++) {
      sLarge = simulateDerbyFrame(sLarge, { attack: i === 0 });
    }
    while (sLarge.phase !== "landed" && sLarge.phase !== "results" && sLarge.frame < 900) {
      sLarge = simulateDerbyFrame(sLarge, {});
    }

    assert.ok(sLarge.finalDistance >= sSmall.finalDistance);
  });

  it("small fighter builds combo window faster than large", () => {
    const small = buildCreatedFighter({ name: "S", size: "small", color: "yellow", id: "s-2" });
    const large = buildCreatedFighter({ name: "L", size: "large", color: "yellow", id: "l-2" });
    assert.ok(small.size === "small" && large.size === "large");
    const sSmall = createInitialDerbyState(1, 0, small);
    const sLarge = createInitialDerbyState(1, 0, large);
    assert.ok(sSmall.comboWindowFrames > sLarge.comboWindowFrames);
  });
});
