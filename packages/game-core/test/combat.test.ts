import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  getActiveHitboxes,
  NEUTRAL_ATTACK,
  SPECIAL_ATTACK,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 1,
};

function input(frame: number, playerId: number, partial: Partial<InputFrame> = {}): InputFrame {
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

describe("combat mechanics", () => {
  it("attacking player generates active hitbox", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") {
      state = simulateFrame(state, []);
    }

    state.players[0].actionState = "attacking";
    state.players[0].actionFrame = NEUTRAL_ATTACK.startup;

    const hitboxes = getActiveHitboxes(state.players[0]);
    assert.ok(hitboxes.length > 0);
    assert.ok(hitboxes[0].active);
    assert.ok(hitboxes[0].damage > 0);
  });

  it("special attack has larger hitbox than basic attack", () => {
    const state = createInitialGameState(config);
    state.players[0].actionState = "attacking";
    state.players[0].actionFrame = NEUTRAL_ATTACK.startup;
    const attackBoxes = getActiveHitboxes(state.players[0]);

    state.players[0].actionState = "special";
    state.players[0].actionFrame = SPECIAL_ATTACK.startup;
    const specialBoxes = getActiveHitboxes(state.players[0]);

    assert.ok(specialBoxes[0].w >= attackBoxes[0].w);
    assert.ok(specialBoxes[0].damage >= attackBoxes[0].damage);
  });

  it("shield reduces incoming damage path", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") {
      state = simulateFrame(state, []);
    }

    const shieldBefore = state.players[1].shieldHealth;

    for (let f = 0; f < 20; f++) {
      state = simulateFrame(state, [
        input(f, 0, { right: true, attack: f < 8 }),
        input(f, 1, { shield: true }),
      ]);
    }

    assert.ok(state.players[1].shieldHealth <= shieldBefore);
  });
});
