import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { SIZE_STATS, getSizeStats } from "../src/sizeClasses.js";
import { scaledRunSpeed, scaledHitDamage } from "../src/fighterCreation.js";
import type { PlayerState } from "../src/types.js";
import { createDefaultAuraState } from "../src/aura/auraTypes.js";

function basePlayer(size: PlayerState["fighterSize"]): PlayerState {
  return {
    id: 0,
    characterId: "test",
    fighterName: "Test",
    fighterSize: size,
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
    maxStaminaHp: 100,
    score: 0,
    teamId: 0,
    actionState: "idle",
    actionFrame: 0,
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
    currentMoveId: "none",
    aura: createDefaultAuraState(),
  };
}

describe("size classes", () => {
  it("small fighter is faster and weaker", () => {
    const small = getSizeStats("small");
    const large = getSizeStats("large");
    assert.ok(small.speedMultiplier > large.speedMultiplier);
    assert.ok(small.damageMultiplier < large.damageMultiplier);
  });

  it("large fighter is slower and stronger", () => {
    const large = getSizeStats("large");
    const medium = getSizeStats("medium");
    assert.ok(large.speedMultiplier < medium.speedMultiplier);
    assert.ok(large.damageMultiplier > medium.damageMultiplier);
  });

  it("medium fighter has neutral modifiers", () => {
    const m = SIZE_STATS.medium;
    assert.equal(m.speedMultiplier, 1);
    assert.equal(m.damageMultiplier, 1);
  });

  it("applies speed and damage in match helpers", () => {
    const small = basePlayer("small");
    const large = basePlayer("large");
    assert.ok(scaledRunSpeed(100, small) > scaledRunSpeed(100, large));
    assert.ok(scaledHitDamage(10, large) > scaledHitDamage(10, small));
  });
});
