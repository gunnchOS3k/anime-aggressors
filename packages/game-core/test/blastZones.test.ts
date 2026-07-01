import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { BLAST_LEFT, BLAST_RIGHT, isOutsideBlastZone } from "../src/combat/blastZones.js";
import { createDefaultAuraState } from "../src/aura/auraTypes.js";
import type { PlayerState } from "../src/types.js";

function playerAt(x: number, y: number): PlayerState {
  return {
    id: 0,
    characterId: "ember",
    fighterName: "Test",
    fighterSize: "medium",
    fighterColor: "red",
    elementEffect: "burn",
    burnFramesRemaining: 0,
    slowFramesRemaining: 0,
    slowMultiplierFp: 100,
    airDriftBonusFrames: 0,
    x,
    y,
    vx: 0,
    vy: 0,
    facing: 1,
    damage: 0,
    stocks: 3,
    staminaHp: 100,
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
    hitVictimsThisMove: [],
    aura: createDefaultAuraState(),
  };
}

describe("blast zones", () => {
  it("detects outside left and right blast zones", () => {
    assert.equal(isOutsideBlastZone(playerAt(BLAST_LEFT - 1, 50000)), true);
    assert.equal(isOutsideBlastZone(playerAt(BLAST_RIGHT + 1, 50000)), true);
    assert.equal(isOutsideBlastZone(playerAt((BLAST_LEFT + BLAST_RIGHT) / 2, 50000)), false);
  });
});
