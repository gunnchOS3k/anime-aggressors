import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { HITLAG_FRAMES } from "@anime-aggressors/game-core";
import { audioEventForHitStrength } from "../src/audio/CombatAudioEvents.ts";

describe("combat impact feedback hooks", () => {
  it("hitlag tiers differ by strength", () => {
    assert.ok(HITLAG_FRAMES.heavy > HITLAG_FRAMES.light);
    assert.ok(HITLAG_FRAMES.super > HITLAG_FRAMES.heavy);
  });

  it("audio maps heavy and light hits differently", () => {
    assert.notEqual(audioEventForHitStrength("light"), audioEventForHitStrength("heavy"));
    assert.equal(audioEventForHitStrength("super"), "superHit");
  });
});
