import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { DEFAULT_FIGHTERS } from "@anime-aggressors/game-core";
import {
  listFightersWithVictoryAnimation,
  victoryFlavorForFighter,
  applyVictoryPose,
} from "../src/renderer-three/fighters/victoryAnimations.ts";
import type { AnimPose } from "../src/renderer-three/fighters/FighterAnimator.ts";

describe("victory animations", () => {
  it("each default fighter has a unique win animation", () => {
    const ids = listFightersWithVictoryAnimation();
    assert.equal(ids.length, DEFAULT_FIGHTERS.length);
    for (const f of DEFAULT_FIGHTERS) {
      assert.ok(ids.includes(f.id), f.id);
    }
  });

  it("victory flavors differ between fighters", () => {
    const ember = victoryFlavorForFighter("ember-vale", 30);
    const rook = victoryFlavorForFighter("rook-ironside", 30);
    assert.notEqual(ember.armR, rook.armR);
  });

  it("applyVictoryPose mutates pose", () => {
    const pose: AnimPose = {
      torsoRotZ: 0,
      torsoScaleY: 1,
      headTilt: 0,
      armSwingL: 0,
      armSwingR: 0,
      legSpread: 0,
      bob: 0,
      auraOpacity: 0,
    };
    applyVictoryPose(pose, "juno-spark", 10);
    assert.ok(Math.abs(pose.armSwingR) > 0.1);
  });
});
