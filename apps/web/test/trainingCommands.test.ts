import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState, simulateFrame, FP_SCALE, CANONICAL_FIGHTER_IDS,
  type GameConfig, type GameState, type InputFrame,
} from "@anime-aggressors/game-core";
import { applyTrainingResetKey } from "../src/match/trainingCommands.ts";
import { TRAINING_SHORTCUT_LINES, P1_CONTROL_LINES } from "../src/input/controlReference.ts";

const config: GameConfig = {
  playerCount: 2, stocks: 3, matchDurationFrames: 10800,
  stageId: "skyline-arena", characterIds: ["kaia-windrow", "juno-spark"], seed: 99,
  training: { dummyPlayerId: 1, dummyBehavior: "idle" },
};
function input(frame: number, playerId: number, partial: Partial<InputFrame> = {}): InputFrame {
  return { frame, playerId, left: false, right: false, up: false, down: false,
    jump: false, attack: false, special: false, shield: false, dodge: false, grab: false, ...partial };
}
function earnHit(): GameState {
  let state = createInitialGameState(config);
  while (state.phase === "countdown") state = simulateFrame(state, []);
  for (let f = 0; f < 300; f++) {
    const [p1, p2] = state.players;
    const close = Math.abs(p1.x - p2.x) < 80 * FP_SCALE;
    state = simulateFrame(state, [input(f, 0, {
      right: p1.x < p2.x && !close, left: p1.x > p2.x && !close, attack: close,
    }), input(f, 1)]);
    if (state.players[1].damage > 0) return state;
  }
  assert.fail("ordinary approach/attack did not earn contact; do not seed damage to pass");
}

describe("training reset commands", () => {
  it("movement D preserves damage earned through ordinary simulation inputs", () => {
    const state = earnHit();
    const damage = state.players[1].damage;
    assert.ok(damage > 0);
    for (const key of ["d", "D", "p", "P"]) {
      assert.equal(applyTrainingResetKey(state, key), false);
      assert.equal(state.players[1].damage, damage);
    }
    assert.equal(applyTrainingResetKey(state, "F7"), true);
    assert.equal(state.players[1].damage, 0);
    assert.equal(state.hitstopFrames, 0);
  });
  it("held reset does not repeatedly erase new damage", () => {
    const state = earnHit();
    const damage = state.players[1].damage;
    assert.equal(applyTrainingResetKey(state, "F7", true), true);
    assert.equal(state.players[1].damage, damage);
  });
  it("position reset uses existing spawn authority and preserves earned damage", () => {
    const initial = createInitialGameState(config);
    const state = earnHit();
    const damage = state.players[1].damage;
    assert.equal(applyTrainingResetKey(state, "F8"), true);
    assert.deepEqual(state.players.map(p => [p.x, p.y]), initial.players.map(p => [p.x, p.y]));
    assert.equal(state.players[1].damage, damage);
  });
  it("practice shortcuts cannot reset competitive state", () => {
    const state = earnHit();
    state.config.training = undefined;
    const before = JSON.stringify(state);
    assert.equal(applyTrainingResetKey(state, "F7"), false);
    assert.equal(applyTrainingResetKey(state, "F8"), false);
    assert.equal(JSON.stringify(state), before);
  });
  it("all nine identities and both body selections survive practice reset", () => {
    for (const id of CANONICAL_FIGHTER_IDS) for (const body of ["male", "female"] as const) {
      const state = createInitialGameState({ ...config, characterIds: [id, "juno-spark"], bodyVariants: [body, body] });
      const identities = state.players.map(p => [p.characterId, p.bodyVariant]);
      applyTrainingResetKey(state, "F7");
      applyTrainingResetKey(state, "F8");
      assert.deepEqual(state.players.map(p => [p.characterId, p.bodyVariant]), identities);
    }
  });
  it("help distinguishes movement from explicit reset keys", () => {
    assert.ok(P1_CONTROL_LINES.includes("Move: A / D"));
    assert.match(TRAINING_SHORTCUT_LINES[0], /F7 damage reset.*F8 position reset/);
    assert.doesNotMatch(TRAINING_SHORTCUT_LINES[0], /D damage reset/);
  });
});
