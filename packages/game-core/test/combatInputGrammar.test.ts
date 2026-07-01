import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { resolveMoveSlotFromInput } from "../src/moves/moveDefinitions.js";
import type { InputFrame, PlayerState } from "../src/types.js";
import { createDefaultAuraState } from "../src/aura/auraTypes.js";

function stubPlayer(): PlayerState {
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
    hitVictimsThisMove: [],
    currentPlatformId: "",
    dropThroughFrames: 0,
    ignoredPlatformId: "",
    aura: createDefaultAuraState(),
  };
}

describe("combat input grammar", () => {
  it("side attack slot from directional input", () => {
    const p = stubPlayer();
    const slot = resolveMoveSlotFromInput(p, {
      left: false,
      right: true,
      up: false,
      down: false,
      attack: true,
      special: false,
    });
    assert.equal(slot, "sideAttack");
  });
});
