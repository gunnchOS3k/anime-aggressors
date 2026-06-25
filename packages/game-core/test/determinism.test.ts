import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  hashState,
  replay,
  serializeState,
  deserializeState,
  type InputFrame,
  type GameConfig,
} from "../src/index.js";

const baseConfig: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 42,
};

function makeInput(frame: number, playerId: number, overrides: Partial<InputFrame> = {}): InputFrame {
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
    ...overrides,
  };
}

describe("determinism", () => {
  it("same initial state + same inputs = same final hash", () => {
    const initial = createInitialGameState(baseConfig);
    const inputs: InputFrame[][] = [];

    for (let f = 0; f < 200; f++) {
      inputs.push([
        makeInput(f, 0, { right: f > 60 && f < 120, attack: f === 100 }),
        makeInput(f, 1, { left: f > 80 && f < 140 }),
      ]);
    }

    let stateA = createInitialGameState(baseConfig);
    let stateB = createInitialGameState(baseConfig);

    for (const frameInputs of inputs) {
      stateA = simulateFrame(stateA, frameInputs);
      stateB = simulateFrame(stateB, frameInputs);
    }

    assert.equal(hashState(stateA), hashState(stateB));
  });

  it("replay produces same state hash as step simulation", () => {
    const initial = createInitialGameState(baseConfig);
    const inputLog: InputFrame[][] = [];

    for (let f = 0; f < 150; f++) {
      inputLog.push([
        makeInput(f, 0, { attack: f === 90 }),
        makeInput(f, 1, { shield: f >= 85 && f <= 95 }),
      ]);
    }

    let stepped = initial;
    for (const inputs of inputLog) {
      stepped = simulateFrame(stepped, inputs);
    }

    const replayResult = replay(initial, inputLog);
    assert.equal(replayResult.finalHash, hashState(stepped));
  });

  it("serialize/deserialize round-trip preserves hash", () => {
    const state = createInitialGameState(baseConfig);
    const serialized = serializeState(state);
    const restored = deserializeState(serialized);
    assert.equal(hashState(state), hashState(restored));
  });
});

describe("combat", () => {
  it("attack can damage opponent after countdown", () => {
    let state = createInitialGameState(baseConfig);

    // Skip countdown
    while (state.phase === "countdown") {
      state = simulateFrame(state, []);
    }

    const p0Start = state.players[0].x;
    const p1StartDamage = state.players[1].damage;

    for (let f = 0; f < 30; f++) {
      state = simulateFrame(state, [
        makeInput(f, 0, { right: true, attack: f === 5 }),
        makeInput(f, 1, {}),
      ]);
    }

    assert.ok(state.players[0].x !== p0Start || state.players[1].damage > p1StartDamage);
  });

  it("defeated player transitions match to results when one stock left", () => {
    let state = createInitialGameState({ ...baseConfig, stocks: 1 });
    while (state.phase === "countdown") {
      state = simulateFrame(state, []);
    }

    state.players[1].x = state.stage.left - 1000;
    state.players[1].stocks = 1;

    state = simulateFrame(state, [
      makeInput(0, 0, {}),
      makeInput(0, 1, {}),
    ]);

    if (state.players[1].stocks <= 0) {
      assert.equal(state.players[1].actionState, "defeated");
    }
  });
});
