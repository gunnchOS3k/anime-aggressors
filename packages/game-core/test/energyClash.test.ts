import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  CLASH_WIN_THRESHOLD,
  createInitialGameState,
  detectEnergyClashes,
  getFighterMove,
  serializeEnergyClash,
  deserializeEnergyClash,
  tickEnergyClashes,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { createEnergyAttack, resetProjectileIdCounter } from "../src/combat/projectiles.js";
import { resetClashIdCounter } from "../src/combat/energyClash.js";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember-vale", "juno-spark"],
  seed: 42,
};

function input(playerId: number, partial: Partial<InputFrame> = {}): InputFrame {
  return {
    frame: 0,
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

describe("energy clash", () => {
  it("beam attacks create clash on overlap", () => {
    resetProjectileIdCounter(1);
    resetClashIdCounter(1);
    const state = createInitialGameState(config);
    const moveA = getFighterMove("ember-vale", "super")!;
    const moveB = getFighterMove("juno-spark", "super")!;
    const a = createEnergyAttack(state.players[0], moveA, 1);
    const b = createEnergyAttack(state.players[1], moveB, -1);
    b.x = a.x + 10;
    b.y = a.y;
    state.energyAttacks = [a, b];

    detectEnergyClashes(state);
    assert.equal(state.energyClashes?.length, 1);
    assert.equal(state.energyClashes![0]!.phase, "starting");
  });

  it("clash balance resolves deterministically", () => {
    resetProjectileIdCounter(1);
    resetClashIdCounter(1);
    const state = createInitialGameState(config);
    const moveA = getFighterMove("ember-vale", "super")!;
    const moveB = getFighterMove("juno-spark", "super")!;
    const a = createEnergyAttack(state.players[0], moveA, 1);
    const b = createEnergyAttack(state.players[1], moveB, -1);
    b.x = a.x + 10;
    state.energyAttacks = [a, b];
    detectEnergyClashes(state);

    for (let i = 0; i < 200; i++) {
      tickEnergyClashes(state, [input(0, { special: true, attack: true }), input(1)]);
    }
    const winnerAttack = state.energyAttacks?.find((atk) => atk.durationFrames > 0 && !atk.lockedInClashId);
    const bursted = state.energyAttacks?.every((atk) => atk.durationFrames === 0);
    assert.ok(winnerAttack || bursted || state.hitstopFrames > 0);
  });

  it("neutral clash burst works on timeout", () => {
    resetClashIdCounter(1);
    const state = createInitialGameState(config);
    const attackA = {
      id: "a",
      ownerPlayerId: 0,
      fighterId: "ember-vale",
      moveId: "ember-vale:super",
      kind: "beam" as const,
      x: 100,
      y: 100,
      vx: 0,
      vy: 0,
      width: 100,
      height: 40,
      power: 80,
      stability: 64,
      durationFrames: 30,
      element: "flame" as const,
      clashable: true,
      facing: 1 as const,
      frame: 0,
      lockedInClashId: "ec-1",
    };
    const attackB = {
      ...attackA,
      id: "b",
      ownerPlayerId: 1,
      fighterId: "juno-spark",
      moveId: "juno-spark:super",
      element: "volt" as const,
      facing: -1 as const,
      x: 110,
    };
    state.energyClashes = [
      {
        id: "ec-1",
        attackAId: "a",
        attackBId: "b",
        playerAId: 0,
        playerBId: 1,
        x: 100,
        y: 100,
        balance: 0,
        intensity: 50,
        durationFrames: 119,
        maxDurationFrames: 120,
        phase: "struggling",
      },
    ];
    state.energyAttacks = [attackA, attackB];

    tickEnergyClashes(state, [input(0), input(1)]);
    assert.equal(state.energyAttacks![0]!.durationFrames, 0);
    assert.equal(state.energyAttacks![1]!.durationFrames, 0);
    assert.equal(state.energyAttacks![0]!.lockedInClashId, undefined);
  });

  it("energy clash state serializes", () => {
    const clash = {
      id: "ec-test",
      attackAId: "a",
      attackBId: "b",
      playerAId: 0,
      playerBId: 1,
      x: 200,
      y: 300,
      balance: -CLASH_WIN_THRESHOLD,
      intensity: 75,
      durationFrames: 10,
      maxDurationFrames: 120,
      phase: "resolved" as const,
      winnerPlayerId: 0,
    };
    const json = serializeEnergyClash(clash);
    const restored = deserializeEnergyClash(json);
    assert.deepEqual(restored, clash);
  });
});
