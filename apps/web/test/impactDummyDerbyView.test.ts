import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { derbyHudHtml } from "../src/modes/impactDummyDerbyHud.ts";
import { createInitialDerbyState } from "@anime-aggressors/game-core";

describe("impactDummyDerbyView helpers", () => {
  it("hud shows damage phase prompt", () => {
    const s = createInitialDerbyState(1);
    s.phase = "damage";
    const html = derbyHudHtml(s);
    assert.match(html, /Damage the dummy/i);
  });

  it("hud shows kinetic bat prompt in final launch", () => {
    const s = createInitialDerbyState(1);
    s.phase = "finalLaunch";
    s.kineticBat.equipped = true;
    const html = derbyHudHtml(s);
    assert.match(html, /Kinetic Bat/i);
  });
});
