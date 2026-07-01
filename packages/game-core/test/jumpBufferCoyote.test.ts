import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { bufferJumpInput, consumeJumpBuffer } from "../src/movement/jumpSystem.js";
import type { PlayerState } from "../src/types.js";
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
    aura: createDefaultAuraState(),
  };
}

describe("jump buffer and coyote", () => {
  it("jump buffer triggers when landing within buffer window", () => {
    const p = stubPlayer();
    bufferJumpInput(p, true);
    assert.ok(consumeJumpBuffer(p));
  });

  it("buffer decays when jump not pressed", () => {
    const p = stubPlayer();
    bufferJumpInput(p, true);
    bufferJumpInput(p, false);
    assert.ok(p.jumpBufferFrames > 0);
  });
});
