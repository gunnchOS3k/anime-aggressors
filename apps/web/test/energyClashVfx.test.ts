import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  getHitColorForStyle,
  getTrailColorForStyle,
  getVfxColorsForStyle,
  MOVE_VFX_STYLES,
} from "../src/renderer-three/vfx/moveVfxMap.ts";
import { renderEnergyClashPrompt } from "../src/ui/EnergyClashPrompt.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("energy clash vfx", () => {
  it("maps vfx styles to trail and hit colors", () => {
    for (const style of MOVE_VFX_STYLES) {
      const colors = getVfxColorsForStyle(style);
      assert.ok(colors.trail > 0);
      assert.ok(colors.hit > 0);
      assert.ok(colors.hitHeavy > 0);
      assert.equal(getTrailColorForStyle(style), colors.trail);
      assert.equal(getHitColorForStyle(style), colors.hit);
    }
  });

  it("renders energy clash prompt HTML", () => {
    const html = renderEnergyClashPrompt({
      clash: {
        id: "ec-1",
        attackAId: "a",
        attackBId: "b",
        playerAId: 0,
        playerBId: 1,
        x: 100,
        y: 200,
        balance: 0,
        intensity: 60,
        durationFrames: 5,
        maxDurationFrames: 120,
        phase: "struggling",
      },
    });
    assert.match(html, /ENERGY CLASH!/);
    assert.match(html, /Hold Special to push/);
    assert.match(html, /energy-clash-meter/);
  });

  it("training mode shows clash prompt in App", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/game/App.ts"), "utf8");
    assert.match(src, /renderEnergyClashPrompt/);
    assert.match(src, /trainingMode/);
    assert.match(src, /updateTrainingOverlays/);
  });
});
