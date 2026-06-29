import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { hitEventToImpactVfx, ELEMENT_VFX_COLORS } from "../src/renderer-three/vfx/CombatImpactVfx.ts";
import { shouldFlashScreen } from "../src/renderer-three/vfx/ScreenImpactFlash.ts";
import type { HitEvent } from "@anime-aggressors/game-core";

const evt: HitEvent = {
  frame: 1,
  attackerPlayerId: 0,
  victimPlayerId: 1,
  moveId: "super",
  damage: 20,
  preHitVictimDamage: 0,
  postHitVictimDamage: 20,
  launchAngleDeg: -50,
  knockbackX: 3,
  knockbackY: -6,
  hitlagFrames: 14,
  hitstunFrames: 30,
  hitStrength: "super",
  element: "flame",
  cameraImpulseKind: "super",
};

describe("combat vfx hooks", () => {
  it("maps hit event to impact vfx handle", () => {
    const vfx = hitEventToImpactVfx(evt, 100, 200);
    assert.equal(vfx.element, "flame");
    assert.equal(vfx.strength, "super");
  });

  it("element colors defined for ROYGBIV elements", () => {
    assert.ok(ELEMENT_VFX_COLORS.flame);
    assert.ok(ELEMENT_VFX_COLORS.frost);
    assert.ok(ELEMENT_VFX_COLORS.void);
  });

  it("screen flash on heavy hits", () => {
    assert.equal(shouldFlashScreen(evt), true);
    assert.equal(shouldFlashScreen({ ...evt, hitStrength: "light" }), false);
  });
});
