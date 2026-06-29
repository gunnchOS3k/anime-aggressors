import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { computeFighterLimbPose } from "../src/renderer-three/fighters/FighterAnimationController.ts";
import { createDefaultAuraState } from "@anime-aggressors/game-core";
import type { PlayerState } from "@anime-aggressors/game-core";

describe("derby uses combat animation", () => {
  it("jump pose uses limb animation controller", () => {
    const player: PlayerState = {
      id: 0,
      characterId: "created:ember-vale",
      fighterName: "Ember",
      fighterSize: "medium",
      fighterColor: "red",
      elementEffect: "burn",
      burnFramesRemaining: 0,
      slowFramesRemaining: 0,
      slowMultiplierFp: 100,
      airDriftBonusFrames: 0,
      x: 0,
      y: 0,
      vx: 0,
      vy: -100,
      facing: 1,
      damage: 0,
      stocks: 3,
      staminaHp: 0,
      maxStaminaHp: 0,
      score: 0,
      teamId: 0,
      actionState: "jumping",
      actionFrame: 2,
      hitstunFrames: 0,
      shieldHealth: 100,
      jumpsRemaining: 1,
      jumpsUsed: 1,
      jumpHoldFrames: 0,
      wasJumpHeld: false,
      onGround: false,
      invulnFrames: 0,
      coyoteFrames: 0,
      jumpBufferFrames: 0,
      fastFalling: false,
      currentMoveId: "none",
      aura: createDefaultAuraState(),
    };
    const pose = computeFighterLimbPose(player, 10);
    assert.ok(pose.leftUpperArm?.rotationX !== undefined || pose.rightUpperArm?.rotationX !== undefined);
  });
});
