import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { listLimbPartNames } from "../src/renderer-three/fighters/FighterRigParts.ts";
import { clipUsesLimbs, FIGHTING_ANIMATION_CLIPS } from "../src/renderer-three/fighters/fightingAnimationClips.ts";

describe("fighter rig parts", () => {
  it("lists required limb part names", () => {
    const parts = listLimbPartNames();
    assert.ok(parts.includes("leftUpperArm"));
    assert.ok(parts.includes("rightFoot"));
    assert.ok(parts.includes("torso"));
  });
});

describe("limb animation clips", () => {
  it("neutral attack moves arm parts", () => {
    assert.equal(clipUsesLimbs("neutralAttack"), true);
    const clip = FIGHTING_ANIMATION_CLIPS.neutralAttack;
    assert.ok(clip.keyframes.some((kf) => kf.pose.rightUpperArm));
  });

  it("side attack moves arm and leg parts", () => {
    assert.equal(clipUsesLimbs("sideAttack"), true);
    const clip = FIGHTING_ANIMATION_CLIPS.sideAttack;
    assert.ok(clip.keyframes.some((kf) => kf.pose.rightUpperLeg));
  });
});
