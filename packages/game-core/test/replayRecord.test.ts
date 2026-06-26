import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createReplayRecord,
  verifyReplayRecord,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  simulateFrame,
  type InputFrame,
} from "../src/index.js";

function emptyInput(frame: number, playerId: number): InputFrame {
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
  };
}

describe("replay record", () => {
  it("stores initial state, input log, and final hash", () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 123);
    const initial = createInitialGameState(config);

    const inputLog = Array.from({ length: 30 }, (_, f) => [
      emptyInput(f, 0),
      emptyInput(f, 1),
    ]);

    const record = createReplayRecord({
      matchId: "m1",
      gameVersion: "0.1.0",
      mode: "playMatch",
      ruleset: DEFAULT_RULESET,
      initialState: initial,
      inputLog: inputLog.map((inputs, frame) => ({ frame, inputs })),
      title: "Test Replay",
    });

    assert.ok(record.initialStateSerialized.length > 0);
    assert.equal(record.inputLog.length, 30);
    assert.ok(record.finalStateHash.length > 0);
    assert.equal(record.title, "Test Replay");
  });

  it("same replay reproduces final hash", () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 456);
    const initial = createInitialGameState(config);

    let state = initial;
    const inputLog = [];
    for (let f = 0; f < 60; f++) {
      const inputs = [emptyInput(f, 0), emptyInput(f, 1)];
      inputLog.push({ frame: f, inputs });
      state = simulateFrame(state, inputs);
    }

    const record = createReplayRecord({
      matchId: "m2",
      gameVersion: "0.1.0",
      mode: "playMatch",
      ruleset: DEFAULT_RULESET,
      initialState: initial,
      inputLog,
      title: "Deterministic",
    });

    const verification = verifyReplayRecord(record);
    assert.equal(verification.valid, true);
    assert.equal(verification.reproducedHash, record.finalStateHash);
  });
});
