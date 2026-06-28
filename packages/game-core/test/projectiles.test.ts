import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  getFighterMove,
  type GameConfig,
} from "../src/index.js";
import {
  createEnergyAttack,
  deserializeEnergyAttack,
  elementFromFighterColor,
  energyAttacksOverlap,
  resetProjectileIdCounter,
  serializeEnergyAttack,
  tickEnergyAttack,
} from "../src/combat/projectiles.js";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember-vale", "juno-spark"],
  seed: 1,
};

describe("energy projectiles", () => {
  it("creates clashable super energy attack", () => {
    resetProjectileIdCounter(1);
    const state = createInitialGameState(config);
    const move = getFighterMove("ember-vale", "super")!;
    const attack = createEnergyAttack(state.players[0], move, 1);
    assert.equal(attack.clashable, true);
    assert.equal(attack.kind, "beam");
    assert.ok(attack.power > 0);
    assert.equal(attack.element, elementFromFighterColor("red"));
  });

  it("detects overlap between opposing clashable attacks", () => {
    resetProjectileIdCounter(1);
    const state = createInitialGameState(config);
    const moveA = getFighterMove("ember-vale", "super")!;
    const moveB = getFighterMove("juno-spark", "super")!;
    const a = createEnergyAttack(state.players[0], moveA, 1);
    const b = createEnergyAttack(state.players[1], moveB, -1);
    b.x = a.x + 20;
    b.y = a.y;
    assert.equal(energyAttacksOverlap(a, b), true);
  });

  it("does not overlap same-player attacks", () => {
    resetProjectileIdCounter(1);
    const state = createInitialGameState(config);
    const move = getFighterMove("ember-vale", "super")!;
    const a = createEnergyAttack(state.players[0], move, 1);
    const b = createEnergyAttack(state.players[0], move, 1);
    b.x = a.x;
    assert.equal(energyAttacksOverlap(a, b), false);
  });

  it("ticks attack position and duration", () => {
    resetProjectileIdCounter(1);
    const state = createInitialGameState(config);
    const move = getFighterMove("ember-vale", "super")!;
    const attack = createEnergyAttack(state.players[0], move, 1);
    const startX = attack.x;
    const startDur = attack.durationFrames;
    tickEnergyAttack(attack);
    assert.equal(attack.x, startX + attack.vx);
    assert.equal(attack.durationFrames, startDur - 1);
  });

  it("serializes and deserializes energy attack", () => {
    resetProjectileIdCounter(1);
    const state = createInitialGameState(config);
    const move = getFighterMove("ember-vale", "super")!;
    const attack = createEnergyAttack(state.players[0], move, 1);
    const restored = deserializeEnergyAttack(serializeEnergyAttack(attack));
    assert.equal(restored.id, attack.id);
    assert.equal(restored.power, attack.power);
  });
});
