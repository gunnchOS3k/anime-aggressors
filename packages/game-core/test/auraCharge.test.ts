import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  processPlayer,
  auraLevelFromCurrent,
  isSuperReady,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";
import type { InputFrame } from "@anime-aggressors/game-core";

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

describe("aura charge", () => {
  it("starts at zero", () => {
    const state = createInitialGameState(
      gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1),
    );
    assert.equal(state.players[0]!.aura.current, 0);
    assert.equal(state.players[0]!.aura.level, 0);
  });

  it("holding shield+special increases meter", () => {
    const state = createInitialGameState(
      gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 2),
    );
    const p = state.players[0]!;
    processPlayer(state, p, input(0, 0, { shield: true, special: true }));
    assert.equal(p.actionState, "auraCharging");
    for (let f = 1; f <= 15; f++) {
      processPlayer(state, p, input(f, 0, { shield: true, special: true }));
    }
    assert.ok(p.aura.current > 0);
  });

  it("holding auraCharge input increases meter", () => {
    const state = createInitialGameState(
      gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 2),
    );
    const p = state.players[0]!;
    processPlayer(state, p, input(0, 0, { auraCharge: true }));
    assert.equal(p.actionState, "auraCharging");
    for (let f = 1; f <= 20; f++) {
      processPlayer(state, p, input(f, 0, { auraCharge: true }));
    }
    assert.ok(p.aura.current >= 25);
    assert.ok(p.aura.level >= 1);
  });

  it("level changes at thresholds", () => {
    assert.equal(auraLevelFromCurrent(0), 0);
    assert.equal(auraLevelFromCurrent(25), 1);
    assert.equal(auraLevelFromCurrent(50), 2);
    assert.equal(auraLevelFromCurrent(85), 3);
    assert.equal(auraLevelFromCurrent(100), 3);
  });

  it("super ready at level 3", () => {
    const state = createInitialGameState(
      gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 3),
    );
    state.players[0]!.aura.current = 90;
    state.players[0]!.aura.level = 3;
    assert.equal(isSuperReady(state.players[0]!.aura), true);
  });
});
