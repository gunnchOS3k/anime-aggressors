import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  processPlayer,
  computeDashSpeed,
} from "../src/index.js";
import type { InputFrame, PlayerState } from "../src/types.js";

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

function runFrames(state: ReturnType<typeof createInitialGameState>, player: PlayerState, frames: number, partial: Partial<InputFrame>) {
  for (let f = 0; f < frames; f++) {
    processPlayer(state, player, input(f, player.id, partial));
  }
}

describe("platform fighter movement feel", () => {
  const config = gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1);

  it("small reaches farther than medium over 60 frames", () => {
    const smallState = createInitialGameState(config);
    const medState = createInitialGameState(config);
    const small = smallState.players[0]!;
    const medium = medState.players[0]!;
    small.fighterSize = "small";
    medium.fighterSize = "medium";
    runFrames(smallState, small, 60, { right: true });
    runFrames(medState, medium, 60, { right: true });
    assert.ok(small.x > medium.x);
  });

  it("medium reaches farther than large over 60 frames", () => {
    const medState = createInitialGameState(config);
    const largeState = createInitialGameState(config);
    const medium = medState.players[0]!;
    const large = largeState.players[0]!;
    medium.fighterSize = "medium";
    large.fighterSize = "large";
    runFrames(medState, medium, 60, { right: true });
    runFrames(largeState, large, 60, { right: true });
    assert.ok(medium.x > large.x);
  });

  it("dash covers meaningful distance within 12 frames", () => {
    const state = createInitialGameState(config);
    const p = state.players[0]!;
    const startX = p.x;
    p.actionState = "dodging";
    p.facing = 1;
    p.vx = computeDashSpeed(p);
    for (let f = 0; f < 12; f++) {
      processPlayer(state, p, input(f, 0, {}));
    }
    assert.ok(Math.abs(p.x - startX) > 200);
  });

  it("jump applies upward velocity and leaves ground", () => {
    const state = createInitialGameState(config);
    const p = state.players[0]!;
    assert.equal(p.onGround, true);
    processPlayer(state, p, input(0, 0, { jump: true }));
    assert.equal(p.actionState, "jumping");
    assert.ok(p.vy < 0);
    assert.equal(p.onGround, false);
  });

  it("air drift changes x while airborne", () => {
    const state = createInitialGameState(config);
    const p = state.players[0]!;
    p.onGround = false;
    p.actionState = "falling";
    const startX = p.x;
    runFrames(state, p, 20, { right: true });
    assert.ok(p.x > startX);
  });

  it("large is slower but still covers playable distance", () => {
    const state = createInitialGameState(config);
    const p = state.players[0]!;
    p.fighterSize = "large";
    runFrames(state, p, 60, { right: true });
    assert.ok(p.x > 300);
  });
});
