import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  processPlayer,
} from "../src/index.js";
import type { InputFrame } from "../src/types.js";

function input(frame: number, playerId: number, partial: Partial<InputFrame>): InputFrame {
  return {
    frame,
    playerId,
    left: false,
    right: false,
    up: false,
    down: false,
    jump: false,
    attack: false,
    special: false,
    shield: false,
    dodge: false,
    grab: false,
    ...partial,
  };
}

describe("aura charge does not block jump", () => {
  it("jump works while aura charge held", () => {
    const state = createInitialGameState(
      gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1),
    );
    state.phase = "fighting";
    const p = state.players[0]!;
    processPlayer(state, p, input(0, 0, { auraCharge: true }));
    assert.equal(p.actionState, "auraCharging");
    processPlayer(state, p, input(1, 0, { jump: true, auraCharge: true }));
    assert.equal(p.actionState, "jumping");
    assert.ok(p.vy < 0);
  });
});
