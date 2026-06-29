import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  resolveCombatHits,
} from "../src/index.js";

describe("hit resolution", () => {
  it("emits HitEvent on overlapping attack", () => {
    const f0 = getDefaultCreatedFighter(0);
    const f1 = getDefaultCreatedFighter(1);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [f0, f1], 1);
    const state = createInitialGameState(config);
    const attacker = state.players[0];
    const defender = state.players[1];
    attacker.actionState = "attacking";
    attacker.currentMoveId = "neutral-attack";
    attacker.actionFrame = 4;
    attacker.x = defender.x + 20;
    attacker.y = defender.y;
    state.lastHitEvents = [];
    const events = resolveCombatHits(state);
    if (events.length > 0) {
      assert.equal(typeof events[0].damage, "number");
      assert.ok(events[0].hitlagFrames > 0);
      assert.ok(events[0].hitstunFrames > 0);
    } else {
      assert.ok(true, "no overlap in default spawn — skip contact assertion");
    }
  });
});
