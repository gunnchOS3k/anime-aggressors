import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { computeHitlag } from "../src/combat/hitlag.js";
import { HITLAG_DEFAULTS } from "../src/combat/combatTuning.js";

describe("hitlag", () => {
  it("light/medium/heavy/super values differ", () => {
    assert.equal(computeHitlag("light"), HITLAG_DEFAULTS.light);
    assert.equal(computeHitlag("medium"), HITLAG_DEFAULTS.medium);
    assert.equal(computeHitlag("heavy"), HITLAG_DEFAULTS.heavy);
    assert.equal(computeHitlag("super"), HITLAG_DEFAULTS.super);
    assert.ok(HITLAG_DEFAULTS.light < HITLAG_DEFAULTS.medium);
    assert.ok(HITLAG_DEFAULTS.medium < HITLAG_DEFAULTS.heavy);
    assert.ok(HITLAG_DEFAULTS.heavy < HITLAG_DEFAULTS.super);
  });
});
