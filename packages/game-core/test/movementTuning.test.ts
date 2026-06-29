import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { MOVEMENT_BASE, MOVEMENT_TUNING } from "../src/movement/movementTuning.js";
import { computeRunSpeed, computeDashSpeed } from "../src/movement/applyMovement.js";
import { createInitialGameState, gameConfigFromRuleset, DEFAULT_RULESET, getDefaultCreatedFighter } from "../src/index.js";

function playerWithSize(size: "small" | "medium" | "large") {
  const state = createInitialGameState(
    gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1),
  );
  const p = state.players[0]!;
  p.fighterSize = size;
  return p;
}

describe("movement tuning", () => {
  it("defines faster base run than legacy 6 units", () => {
    const legacy = (6 * 256) / 60;
    assert.ok(MOVEMENT_BASE.runSpeed > legacy);
  });

  it("small run speed exceeds medium exceeds large", () => {
    const small = computeRunSpeed(playerWithSize("small"));
    const medium = computeRunSpeed(playerWithSize("medium"));
    const large = computeRunSpeed(playerWithSize("large"));
    assert.ok(small > medium);
    assert.ok(medium > large);
  });

  it("small dash exceeds large dash", () => {
    const small = computeDashSpeed(playerWithSize("small"));
    const large = computeDashSpeed(playerWithSize("large"));
    assert.ok(small > large);
  });

  it("MOVEMENT_TUNING multipliers are ordered by size", () => {
    assert.ok(MOVEMENT_TUNING.small.runSpeed > MOVEMENT_TUNING.medium.runSpeed);
    assert.ok(MOVEMENT_TUNING.medium.runSpeed > MOVEMENT_TUNING.large.runSpeed);
  });
});
