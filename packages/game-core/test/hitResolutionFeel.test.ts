import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { HITLAG_DEFAULTS, HITLAG_FRAMES } from "../src/combat/combatTuning.js";
import { computeHitlag } from "../src/combat/hitlag.js";
import { resolveCombatHits } from "../src/combat/hitResolution.js";
import { createInitialGameState, gameConfigFromRuleset, DEFAULT_RULESET, getDefaultCreatedFighter } from "../src/index.js";

describe("hit resolution feel", () => {
  it("heavy hit has more hitlag than light hit", () => {
    const heavy = computeHitlag("heavy");
    const light = computeHitlag("light");
    assert.ok(heavy > light);
  });

  it("HITLAG_FRAMES matches defaults", () => {
    assert.equal(HITLAG_FRAMES.light, HITLAG_DEFAULTS.light);
    assert.equal(HITLAG_FRAMES.super, HITLAG_DEFAULTS.super);
  });

  it("resolveCombatHits returns HitEvent array type", () => {
    const state = createInitialGameState(
      gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1),
    );
    const events = resolveCombatHits(state);
    assert.ok(Array.isArray(events));
  });
});
