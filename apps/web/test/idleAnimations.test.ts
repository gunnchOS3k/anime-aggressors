import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { DEFAULT_FIGHTERS } from "@anime-aggressors/game-core";
import {
  listFightersWithIdleAnimation,
  idleFlavorForFighter,
  applyIdleFlavor,
} from "../src/renderer-three/fighters/idleAnimations.ts";
import type { AnimPose } from "../src/renderer-three/fighters/FighterAnimator.ts";

describe("idle animations", () => {
  it("each default fighter has idle animation config", () => {
    const ids = listFightersWithIdleAnimation();
    assert.equal(ids.length, DEFAULT_FIGHTERS.length);
    for (const f of DEFAULT_FIGHTERS) {
      assert.ok(ids.includes(f.id as (typeof ids)[number]), f.id);
    }
  });

  it("idle flavors differ between fighters", () => {
    const ember = idleFlavorForFighter("ember-vale");
    const nix = idleFlavorForFighter("nix-calder");
    assert.notEqual(ember.bobSpeed, nix.bobSpeed);
  });

  it("applyIdleFlavor animates bob over frames", () => {
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
    applyIdleFlavor(pose, "kaia-windrow", 5);
    const bob1 = pose.bob;
    applyIdleFlavor(pose, "kaia-windrow", 20);
    assert.notEqual(bob1, pose.bob);
  });
});
