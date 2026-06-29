import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { CombatEventAdapter } from "../src/combat/CombatEventAdapter.ts";
import { CameraImpulseSystem } from "../src/renderer-three/camera/CameraImpulseSystem.ts";
import type { HitEvent } from "@anime-aggressors/game-core";

const sampleHit: HitEvent = {
  frame: 10,
  attackerPlayerId: 0,
  victimPlayerId: 1,
  moveId: "neutral-attack",
  damage: 12,
  preHitVictimDamage: 20,
  postHitVictimDamage: 32,
  launchAngleDeg: -35,
  knockbackX: 2,
  knockbackY: -4,
  hitlagFrames: 5,
  hitstunFrames: 12,
  hitStrength: "medium",
  element: "flame",
  cameraImpulseKind: "heavyHit",
};

describe("combat event adapter", () => {
  it("maps HitEvent to camera impulse", () => {
    const impulses = new CameraImpulseSystem();
    let flashed = false;
    const adapter = new CombatEventAdapter(impulses, {
      onScreenFlash: () => {
        flashed = true;
      },
    });
    adapter.processHitEvents([sampleHit], 10);
    const pulse = impulses.tick();
    assert.equal(pulse.active, true);
    assert.equal(flashed, false);
  });

  it("flashes screen on heavy strength", () => {
    const impulses = new CameraImpulseSystem();
    let flashed = false;
    const adapter = new CombatEventAdapter(impulses, {
      onScreenFlash: () => {
        flashed = true;
      },
    });
    adapter.processHitEvents([{ ...sampleHit, hitStrength: "heavy" }], 11);
    assert.equal(flashed, true);
  });
});
