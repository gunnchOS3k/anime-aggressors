import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialFlaglineState,
  simulateFlaglineFrame,
  flaglineStateHash,
  serializeFlaglineState,
  deserializeFlaglineState,
  generateFlaglineBotInput,
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

describe("flagline clash", () => {
  it("starts at Center Clash", () => {
    const state = createInitialFlaglineState(42);
    assert.equal(state.flagline.currentRoomIndex, 0);
    assert.equal(state.game.players.length, 4);
  });

  it("serializes and deserializes", () => {
    const state = createInitialFlaglineState(1);
    const json = serializeFlaglineState(state);
    const restored = deserializeFlaglineState(json);
    assert.ok(restored);
    assert.equal(restored!.flagline.currentRoomIndex, 0);
  });

  it("same inputs produce same hash", () => {
    const initial = createInitialFlaglineState(99);
    let a = initial;
    let b = deserializeFlaglineState(serializeFlaglineState(initial))!;
    const inputs = [emptyInput(0, 0), emptyInput(0, 1)];
    for (let i = 0; i < 30; i++) {
      a = simulateFlaglineFrame(a, inputs);
      b = simulateFlaglineFrame(b, inputs);
    }
    assert.equal(flaglineStateHash(a), flaglineStateHash(b));
  });

  it("bots generate deterministic inputs", () => {
    const state = createInitialFlaglineState(7);
    const a = generateFlaglineBotInput(state, 2, 10);
    const b = generateFlaglineBotInput(state, 2, 10);
    assert.deepEqual(a, b);
  });
});
