import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createInitialGameState, FP_SCALE, CANONICAL_FIGHTER_IDS, replay, hashState,
  type GameState, type InputFrame, type GameConfig } from "@anime-aggressors/game-core";
import { RollbackSession } from "@anime-aggressors/rollback";
import { applyTrainingResetKey, advanceTrainingFrame, setTrainingDummy } from "../src/match/trainingCommands.ts";
import { TrainingHitTracker } from "../src/match/trainingHitTracker.ts";
import { ReplayRecorder } from "../src/replay/ReplayRecorder.ts";

const config: GameConfig = { playerCount: 2, stocks: 99, matchDurationFrames: 10800,
  characterIds: ["kaia-windrow", "juno-spark"], stageId: "skyline-arena", seed: 99,
  training: { dummyPlayerId: 1, dummyBehavior: "idle" } };
function input(frame: number, partial: Partial<InputFrame> = {}): InputFrame {
  return { frame, playerId: 0, left: false, right: false, up: false, down: false,
    jump: false, attack: false, special: false, shield: false, dodge: false, grab: false, ...partial };
}
function ready(overrides: Partial<GameConfig> = {}): GameState {
  let state = createInitialGameState({ ...config, ...overrides });
  while (state.phase === "countdown") state = advanceTrainingFrame(state, []);
  return state;
}
function connect(state = ready(), tracker = new TrainingHitTracker()): GameState {
  const beforeDamage = state.players[1].damage;
  for (let f = 0; f < 300; f++) {
    const [p1, p2] = state.players;
    const close = Math.abs(p1.x - p2.x) < 80 * FP_SCALE;
    const next = advanceTrainingFrame(state, [input(f, {
      right: p1.x < p2.x && !close, left: p1.x > p2.x && !close, attack: close,
    })]);
    tracker.observe(state, next);
    state = next;
    if (state.players[1].damage > beforeDamage) return state;
  }
  assert.fail(`no ordinary contact for ${state.players[0].characterId}/${state.players[0].bodyVariant}`);
}

describe("local training simulation ownership", () => {
  it("retains the negative baseline: editing a rollback snapshot does not edit its authority", () => {
    const earned = connect();
    const session = new RollbackSession(earned, { playerCount: 2, snapshotInterval: 1, maxRollbackFrames: 120 });
    const copy = session.getState();
    applyTrainingResetKey(copy, "F7");
    assert.equal(copy.players[1].damage, 0);
    assert.equal(session.advanceFrame([], [true, true]).players[1].damage, earned.players[1].damage);
  });
  it("local practice reset remains real on the next authoritative simulation tick", () => {
    let state = connect();
    assert.ok(state.players[1].damage > 0);
    applyTrainingResetKey(state, "F7");
    state = advanceTrainingFrame(state, []);
    assert.equal(state.players[1].damage, 0);
    assert.equal(state.players[1].hitstunFrames, 0);
  });
  it("switches real dummy shielding off before ordinary attacks earn damage", () => {
    let state = ready();
    assert.equal(setTrainingDummy(state, "shield"), true);
    for (let f = 0; f < 30; f++) state = advanceTrainingFrame(state, []);
    assert.equal(state.players[1].actionState, "shielding");
    setTrainingDummy(state, "cpu1");
    assert.equal(state.config.cpuOpponents?.[0]?.playerId, 1);
    setTrainingDummy(state, "idle");
    for (let f = 0; f < 30; f++) state = advanceTrainingFrame(state, []);
    assert.notEqual(state.players[1].actionState, "shielding");
    assert.equal(state.config.cpuOpponents, undefined);
    state = connect(state);
    assert.ok(state.players[1].damage > 0);
  });
  it("counts real contact once through hitstop and ends the chain at recovery", () => {
    const tracker = new TrainingHitTracker();
    let state = connect(ready(), tracker);
    assert.equal(tracker.hits, 1);
    assert.equal(tracker.damage, state.players[1].damage);
    assert.ok(state.hitstopFrames > 0);
    for (let f = 0; f < 100; f++) {
      const next = advanceTrainingFrame(state, []);
      tracker.observe(state, next);
      tracker.observe(state, next); // Duplicate render/observer is not another hit.
      state = next;
    }
    assert.equal(tracker.hits, 1);
    assert.equal(tracker.chain, 0);
    assert.equal(tracker.bestChain, 1);
  });
  it("a distant ordinary swing does not grant contact statistics", () => {
    const tracker = new TrainingHitTracker();
    let state = ready();
    for (let f = 0; f < 90; f++) {
      const next = advanceTrainingFrame(state, [input(f, { attack: f === 0 })]);
      tracker.observe(state, next); state = next;
    }
    assert.equal(tracker.hits, 0);
    assert.equal(tracker.damage, 0);
  });
  it("all nine/two-body configurations earn real common-attack contact and retain reset", () => {
    for (const id of CANONICAL_FIGHTER_IDS) for (const body of ["male", "female"] as const) {
      let state = connect(ready({ characterIds: [id, "juno-spark"], bodyVariants: [body, body] }));
      assert.ok(state.players[1].damage > 0);
      applyTrainingResetKey(state, "F7");
      state = advanceTrainingFrame(state, []);
      assert.equal(state.players[1].damage, 0);
      assert.equal(state.players[0].bodyVariant, body);
    }
  });
  it("replay of a new reset segment agrees with its actual post-reset simulation", () => {
    let state = connect();
    applyTrainingResetKey(state, "F7");
    setTrainingDummy(state, "jump");
    const recorder = new ReplayRecorder({ gameVersion: "source-test", mode: "training", ruleset: {} });
    recorder.start(state);
    for (let f = 0; f < 40; f++) {
      const inputs = [input(f, { left: f < 10 })];
      recorder.recordFrame(f, inputs);
      state = advanceTrainingFrame(state, inputs);
    }
    const initial = JSON.parse(recorder.getInitialStateSerialized()!) as GameState;
    const replayed = replay(initial, recorder.getInputLog().map(row => row.inputs));
    assert.equal(replayed.finalHash, hashState(state));
  });
});
