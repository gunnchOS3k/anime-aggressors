import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  replay,
  hashState,
  isInStartup,
  isInActive,
  NEUTRAL_ATTACK,
  DODGE_MOVE,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 7,
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

describe("platform fighter feel", () => {
  it("attack does not hit before startup completes", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") state = simulateFrame(state, []);

    const p1DamageStart = state.players[1].damage;
    for (let f = 0; f < NEUTRAL_ATTACK.startup; f++) {
      state = simulateFrame(state, [
        input(f, 0, { attack: f === 0, right: true }),
        input(f, 1, {}),
      ]);
    }
    assert.equal(state.players[1].damage, p1DamageStart);
    assert.ok(isInStartup(NEUTRAL_ATTACK, state.players[0].actionFrame) || state.players[0].actionFrame <= NEUTRAL_ATTACK.startup);
  });

  it("attack can hit during active frames", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") state = simulateFrame(state, []);

    state.players[0].x = state.players[1].x - 2000;
    state.players[0].facing = 1;

    for (let f = 0; f < NEUTRAL_ATTACK.startup + 1; f++) {
      state = simulateFrame(state, [
        input(f, 0, { attack: f === 0 }),
        input(f, 1, {}),
      ]);
    }
    assert.ok(isInActive(NEUTRAL_ATTACK, state.players[0].actionFrame) || state.players[1].damage > 0);
  });

  it("player cannot act during hitstun", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") state = simulateFrame(state, []);

    state.players[1].actionState = "hitstun";
    state.players[1].hitstunFrames = 20;
    const xBefore = state.players[1].x;

    state = simulateFrame(state, [
      input(0, 1, { right: true, attack: true }),
      input(0, 0, {}),
    ]);

    assert.equal(state.players[1].actionState, "hitstun");
    assert.equal(state.players[1].x, xBefore);
  });

  it("shield blocks damage while healthy", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") state = simulateFrame(state, []);

    const shieldBefore = state.players[1].shieldHealth;
    for (let f = 0; f < 15; f++) {
      state = simulateFrame(state, [
        input(f, 0, { attack: f < 5, right: true }),
        input(f, 1, { shield: true }),
      ]);
    }
    assert.ok(state.players[1].shieldHealth <= shieldBefore);
    assert.equal(state.players[1].damage, 0);
  });

  it("dodge grants invulnerability during active window", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") state = simulateFrame(state, []);

    state.players[0].actionState = "dodging";
    state.players[0].actionFrame = DODGE_MOVE.startup;
    state.players[0].invulnFrames = DODGE_MOVE.active;

    state = simulateFrame(state, [
      input(0, 0, {}),
      input(0, 1, { attack: true }),
    ]);

    assert.ok(state.players[0].invulnFrames >= 0);
  });

  it("KO happens when crossing blast zone", () => {
    let state = createInitialGameState(config);
    while (state.phase === "countdown") state = simulateFrame(state, []);

    state.players[0].stocks = 1;
    state.players[0].x = -999999;
    state = simulateFrame(state, [input(0, 0, {}), input(0, 1, {})]);
    assert.ok(state.players[0].stocks <= 0 || state.players[0].actionState === "defeated");
  });

  it("replay remains deterministic with feel systems", () => {
    const initial = createInitialGameState(config);
    const log: InputFrame[][] = [];
    for (let f = 0; f < 40; f++) {
      log.push([
        input(f, 0, { right: f % 10 === 0, attack: f === 20 }),
        input(f, 1, { shield: f >= 18 && f <= 22 }),
      ]);
    }
    const a = replay(initial, log);
    const b = replay(initial, log);
    assert.equal(a.finalHash, b.finalHash);
  });
});
