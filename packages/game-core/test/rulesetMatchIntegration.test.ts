import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  cloneRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  gameConfigFromRuleset,
} from "../src/index.js";
import { applyHit } from "../src/combat.js";

describe("ruleset match integration", () => {
  it("custom stock ruleset applies stocks", () => {
    const ruleset = cloneRuleset({ ...DEFAULT_RULESET, stocks: 1 });
    const cfg = gameConfigFromRuleset(ruleset, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1);
    const state = createInitialGameState(cfg);
    assert.equal(state.players[0].stocks, 1);
    assert.equal(state.players[1].stocks, 1);
  });

  it("time ruleset applies timer", () => {
    const ruleset = cloneRuleset({ ...DEFAULT_RULESET, matchType: "time", timerSeconds: 120 });
    const cfg = gameConfigFromRuleset(ruleset, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 2);
    const state = createInitialGameState(cfg);
    assert.equal(state.matchTimerFrames, 120 * 60);
    assert.equal(state.config.ruleset?.matchType, "time");
  });

  it("stamina ruleset applies HP", () => {
    const ruleset = cloneRuleset({ ...DEFAULT_RULESET, matchType: "stamina", staminaHp: 150 });
    const cfg = gameConfigFromRuleset(ruleset, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 3);
    const state = createInitialGameState(cfg);
    assert.equal(state.players[0].staminaHp, 150);
    assert.equal(state.players[0].maxStaminaHp, 150);
  });

  it("damage ratio changes damage", () => {
    const baseRuleset = cloneRuleset({ ...DEFAULT_RULESET, damageRatio: 1 });
    const boosted = cloneRuleset({ ...DEFAULT_RULESET, damageRatio: 2 });
    const fighters = [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)];

    const baseState = createInitialGameState(gameConfigFromRuleset(baseRuleset, fighters, 4));
    const boostedState = createInitialGameState(gameConfigFromRuleset(boosted, fighters, 4));

    applyHit(baseState, baseState.players[0], baseState.players[1], 10, 0, 0, 0);
    applyHit(boostedState, boostedState.players[0], boostedState.players[1], 10, 0, 0, 0);

    assert.ok(boostedState.players[1].damage > baseState.players[1].damage);
  });

  it("launch ratio changes knockback velocity", () => {
    const low = cloneRuleset({ ...DEFAULT_RULESET, launchRatio: 0.5 });
    const high = cloneRuleset({ ...DEFAULT_RULESET, launchRatio: 2 });
    const fighters = [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)];

    const lowState = createInitialGameState(gameConfigFromRuleset(low, fighters, 5));
    const highState = createInitialGameState(gameConfigFromRuleset(high, fighters, 5));

    applyHit(lowState, lowState.players[0], lowState.players[1], 10, 100, 50, 0);
    applyHit(highState, highState.players[0], highState.players[1], 10, 100, 50, 0);

    const lowKb = Math.abs(lowState.players[1].vx) + Math.abs(lowState.players[1].vy);
    const highKb = Math.abs(highState.players[1].vx) + Math.abs(highState.players[1].vy);
    assert.ok(highKb > lowKb);
  });

  it("element visual-only disables gameplay element modifiers", () => {
    const ruleset = cloneRuleset({
      ...DEFAULT_RULESET,
      elementMode: "visualOnly",
    });
    const fighters = [
      { ...getDefaultCreatedFighter(0), color: "red" as const },
      getDefaultCreatedFighter(1),
    ];
    const state = createInitialGameState(gameConfigFromRuleset(ruleset, fighters, 6));
    state.players[0].actionState = "attacking";
    state.players[0].actionFrame = 8;
    state.players[0].currentMoveId = "neutral_attack";
    applyHit(state, state.players[0], state.players[1], 10, 0, 0, 0);
    assert.equal(state.players[1].burnFramesRemaining, 0);
  });
});
