import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { DEFAULT_FIGHTERS } from "@anime-aggressors/game-core";
import {
  listFightersWithVictoryAnimation,
  victoryFlavorForFighter,
  applyVictoryPose,
} from "../src/renderer-three/fighters/victoryAnimations.ts";
import { emptyPose } from "../src/renderer-three/fighters/FighterPose.ts";

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
    const posed = applyVictoryPose(emptyPose(), "juno-spark", 10);
    assert.ok(Math.abs(posed.rightUpperArm?.rotationX ?? 0) > 0.1);
  });
});
