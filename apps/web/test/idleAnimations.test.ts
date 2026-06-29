import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { DEFAULT_FIGHTERS } from "@anime-aggressors/game-core";
import {
  listFightersWithIdleAnimation,
  idleFlavorForFighter,
  applyIdleFlavor,
} from "../src/renderer-three/fighters/idleAnimations.ts";
import { emptyPose } from "../src/renderer-three/fighters/FighterPose.ts";

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
    const pose1 = applyIdleFlavor(emptyPose(), "kaia-windrow", 5);
    const bob1 = pose1.root?.y ?? 0;
    const pose2 = applyIdleFlavor(emptyPose(), "kaia-windrow", 20);
    assert.notEqual(bob1, pose2.root?.y ?? 0);
  });
});
