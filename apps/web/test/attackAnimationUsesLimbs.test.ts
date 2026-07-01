import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { attackAnimationUsesLimbs } from "../src/renderer-three/fighters/FighterAnimator.ts";
import type { PlayerState } from "@anime-aggressors/game-core";

function stubPlayer(partial: Partial<PlayerState>): PlayerState {
  return {
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
    vy: 0,
    facing: 1,
    damage: 0,
    stocks: 3,
    staminaHp: 0,
    maxStaminaHp: 0,
    score: 0,
    teamId: 0,
    actionState: "attacking",
    actionFrame: 6,
    hitstunFrames: 0,
    shieldHealth: 100,
    jumpsRemaining: 2,
    jumpsUsed: 0,
    jumpHoldFrames: 0,
    wasJumpHeld: false,
    onGround: true,
    invulnFrames: 0,
    coyoteFrames: 0,
    jumpBufferFrames: 0,
    fastFalling: false,
    currentMoveId: "neutral_attack",
    hitVictimsThisMove: [],
    currentPlatformId: "",
    dropThroughFrames: 0,
    ignoredPlatformId: "",
    aura: { current: 0, max: 100, level: 0, charging: false, superReady: false, cooldownFrames: 0, overcharged: false },
    ...partial,
  };
}

describe("attack animation uses limbs", () => {
  it("neutral attack uses limb-driven clip", () => {
    assert.equal(attackAnimationUsesLimbs(stubPlayer({})), true);
  });

  it("double jump uses limb clip", () => {
    assert.equal(
      attackAnimationUsesLimbs(stubPlayer({ actionState: "jumping", jumpsUsed: 2, onGround: false })),
      true,
    );
  });
});
