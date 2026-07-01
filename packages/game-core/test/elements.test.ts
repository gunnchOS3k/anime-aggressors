import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { ELEMENTS, getElementForColor, applyElementOnHit } from "../src/elements.js";
import type { PlayerState } from "../src/types.js";
import { createDefaultAuraState } from "../src/aura/auraTypes.js";
import { NEUTRAL_ATTACK } from "../src/frameData.js";

const COLORS = ["red", "orange", "yellow", "green", "blue", "indigo", "violet"] as const;

function player(): PlayerState {
  return {
    id: 0,
    characterId: "t",
    fighterName: "A",
    fighterSize: "medium",
    fighterColor: "red",
    elementEffect: "burn",
    burnFramesRemaining: 0,
    slowFramesRemaining: 0,
    slowMultiplierFp: 100,
    airDriftBonusFrames: 0,
    x: 1000,
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
    actionState: "attacking",
    actionFrame: 5,
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
    movementState: "idle",
    dashFrames: 0,
    jumpSquatFrames: 0,
    jumpShortHop: false,
    landingLagFrames: 0,
    ledgeStateFrames: 0,
    grabbedLedgeId: "",
    ledgeCooldownFrames: 0,
    recoveryUsed: false,
    aura: createDefaultAuraState(),
  };
}

describe("elements", () => {
  it("maps every ROYGBIV color to a valid element", () => {
    for (const color of COLORS) {
      const el = getElementForColor(color);
      assert.ok(el.name);
      assert.ok(el.effect);
      assert.equal(ELEMENTS[color].effect, el.effect);
    }
  });

  it("burn effect is deterministic", () => {
    const atk = player();
    const def = player();
    def.id = 1;
    atk.elementEffect = "burn";
    applyElementOnHit(atk, def, NEUTRAL_ATTACK, atk.actionFrame);
    assert.equal(def.burnFramesRemaining > 0, true);
  });

  it("frost applies slow frames", () => {
    const atk = player();
    const def = player();
    def.id = 1;
    atk.elementEffect = "slow";
    applyElementOnHit(atk, def, NEUTRAL_ATTACK, atk.actionFrame);
    assert.ok(def.slowFramesRemaining > 0);
  });
});
