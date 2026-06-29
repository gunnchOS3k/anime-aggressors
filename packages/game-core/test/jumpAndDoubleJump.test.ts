import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  processPlayer,
  JUMP_TUNING,
} from "../src/index.js";
import type { InputFrame } from "../src/types.js";
import { FP_SCALE } from "../src/constants.js";

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

const config = gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1);

describe("jump and double jump", () => {
  it("grounded jump changes vertical velocity upward", () => {
    const state = createInitialGameState(config);
    state.phase = "fighting";
    const p = state.players[0]!;
    processPlayer(state, p, input(0, 0, { jump: true }));
    assert.ok(p.vy < 0);
    assert.equal(p.jumpsUsed, 1);
    assert.equal(p.onGround, false);
  });

  it("airborne jump triggers double jump", () => {
    const state = createInitialGameState(config);
    state.phase = "fighting";
    const p = state.players[0]!;
    processPlayer(state, p, input(0, 0, { jump: true }));
    p.y = state.stage.floorY - 200 * FP_SCALE;
    p.onGround = false;
    p.jumpsUsed = 1;
    p.vy = -80;
    processPlayer(state, p, input(1, 0, { jump: false }));
    processPlayer(state, p, input(2, 0, { jump: true }));
    assert.equal(p.jumpsUsed, 2);
  });

  it("third jump does not trigger without reset", () => {
    const state = createInitialGameState(config);
    state.phase = "fighting";
    const p = state.players[0]!;
    processPlayer(state, p, input(0, 0, { jump: true }));
    p.y = state.stage.floorY - 200 * FP_SCALE;
    p.onGround = false;
    p.jumpsUsed = 1;
    p.vy = -80;
    processPlayer(state, p, input(1, 0, { jump: false }));
    processPlayer(state, p, input(2, 0, { jump: true }));
    p.y = state.stage.floorY - 200 * FP_SCALE;
    p.onGround = false;
    processPlayer(state, p, input(3, 0, { jump: false }));
    processPlayer(state, p, input(4, 0, { jump: true }));
    assert.equal(p.jumpsUsed, 2);
  });

  it("landing resets jumpsUsed", () => {
    const state = createInitialGameState(config);
    state.phase = "fighting";
    const p = state.players[0]!;
    processPlayer(state, p, input(0, 0, { jump: true }));
    for (let f = 1; f < 80; f++) {
      processPlayer(state, p, input(f, 0, {}));
      if (p.onGround) break;
    }
    assert.equal(p.jumpsUsed, 0);
    assert.equal(p.jumpsRemaining, 2);
  });

  it("coyote jump works shortly after leaving ledge", () => {
    const state = createInitialGameState(config);
    state.phase = "fighting";
    const p = state.players[0]!;
    p.onGround = false;
    p.coyoteFrames = JUMP_TUNING.coyoteFrames;
    p.jumpsUsed = 0;
    processPlayer(state, p, input(0, 0, { jump: true }));
    assert.equal(p.jumpsUsed, 1);
    assert.ok(p.vy < 0);
  });
});
