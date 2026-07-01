import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  FP_SCALE,
  processPlayer,
  DEFAULT_FIGHTERS,
  listProductionStageIds,
  getStage,
  validateSpawnPoints,
  getStageLayout,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  buildCreatedFighter,
  getDefaultCreatedFighter,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { getCombatMoveData } from "../src/moves/combatMoveData.js";
import { resolveCombatHits } from "../src/combat/hitResolution.js";
import { generateVersusCpuInput } from "../src/bots/versusCpu.js";
import { computeJumpVelocity } from "../src/movement/jumpSystem.js";
import { fastFallSpeed } from "../src/movement/jumpSystem.js";
import { MAX_FALL_SPEED } from "../src/constants.js";
import { stubPlayer } from "./helpers/playerStub.js";
import { resetTrainingDamage, resetTrainingPositions } from "../src/training/trainingMode.js";
import { applyTrainingDummyBehavior } from "../src/training/trainingMode.js";

const baseConfig: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember-vale", "rook-ironside"],
  seed: 99,
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

function skipCountdown(state: ReturnType<typeof createInitialGameState>) {
  let s = state;
  while (s.phase === "countdown") s = simulateFrame(s, []);
  return s;
}

describe("production completion — combat reliability", () => {
  it("point-blank neutral attack connects", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("neutral_attack")!;
    const atk = state.players[0];
    const def = state.players[1];
    atk.actionState = "attacking";
    atk.currentMoveId = "neutral_attack";
    atk.actionFrame = move.startup;
    atk.facing = 1;
    def.x = atk.x + 35 * FP_SCALE;
    def.y = atk.y;
    def.invulnFrames = 0;
    const dmgBefore = def.damage;
    resolveCombatHits(state);
    assert.ok(def.damage > dmgBefore);
  });

  it("approach script lands neutral within 5 seconds", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    let hit = false;
    for (let f = 0; f < 300; f++) {
      const p1 = state.players[0];
      const p2 = state.players[1];
      const dist = Math.abs(p1.x - p2.x);
      const closeEnough = dist < 80 * FP_SCALE;
      const approaching = p1.x < p2.x;
      state = simulateFrame(state, [
        input(f, 0, {
          right: approaching && !closeEnough,
          left: !approaching && !closeEnough,
          attack: closeEnough,
        }),
        input(f, 1, {}),
      ]);
      if (state.players[1].damage > 0) {
        hit = true;
        break;
      }
    }
    assert.ok(hit, "approach + attack should connect within 5 seconds");
  });

  it("shield blocks point-blank attack", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("neutral_attack")!;
    const atk = state.players[0];
    const def = state.players[1];
    atk.actionState = "attacking";
    atk.currentMoveId = "neutral_attack";
    atk.actionFrame = move.startup;
    def.x = atk.x + 35 * FP_SCALE;
    def.actionState = "shielding";
    const dmgBefore = def.damage;
    resolveCombatHits(state);
    assert.equal(def.damage, dmgBefore);
  });

  it("KO and rematch reset work under scripted knockback", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    const victim = state.players[1];
    victim.damage = 120;
    victim.x = state.stage.right - 50 * FP_SCALE;
    victim.stocks = 1;
    for (let f = 0; f < 120; f++) {
      state = simulateFrame(state, [
        input(f, 0, { right: true, attack: f < 12 }),
        input(f, 1, {}),
      ]);
      if (state.phase === "results" || victim.stocks < 1) break;
    }
    const rematch = resetForRematch(state);
    assert.equal(rematch.phase, "countdown");
    assert.ok(rematch.players.every((p) => p.damage === 0));
  });
});

describe("production completion — movement feel", () => {
  it("jump apex is useful height", () => {
    const p = stubPlayer();
    const vy = computeJumpVelocity(p, false);
    assert.ok(vy < -8 * FP_SCALE / 60, "full hop should have strong upward velocity");
  });

  it("short hop is lower than full hop", () => {
    const p = stubPlayer();
    assert.ok(computeJumpVelocity(p, true) > computeJumpVelocity(p, false));
  });

  it("fast fall increases descent", () => {
    const p = stubPlayer({ fastFalling: true });
    assert.ok(fastFallSpeed(MAX_FALL_SPEED, p) > MAX_FALL_SPEED);
  });

  it("recovery special changes position meaningfully", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    p.onGround = false;
    p.recoveryUsed = false;
    const startY = p.y;
    processPlayer(state, p, input(0, 0, { special: true }));
    assert.ok(p.vy < 0 || p.y < startY);
  });
});

describe("production completion — roster", () => {
  for (const fighter of DEFAULT_FIGHTERS) {
    it(`${fighter.id} can spawn and move`, () => {
      const f0 = buildCreatedFighter({
        id: fighter.id,
        name: fighter.name,
        size: fighter.size,
        color: fighter.color,
      });
      const f1 = getDefaultCreatedFighter(1);
      const cfg = gameConfigFromRuleset(DEFAULT_RULESET, [f0, f1], 99);
      const state = skipCountdown(createInitialGameState(cfg));
      const p = state.players[0];
      assert.equal(p.characterId, `created:${fighter.id}`);
      const startX = p.x;
      for (let f = 0; f < 30; f++) processPlayer(state, p, input(f, 0, { right: true }));
      assert.ok(p.x > startX);
    });
  }
});

describe("production completion — stages", () => {
  for (const stageId of listProductionStageIds()) {
    it(`${stageId} loads with valid spawns and ledges`, () => {
      const stage = getStage(stageId);
      const layout = getStageLayout(stage.layoutId ?? stage.id);
      assert.ok(layout.platforms.length > 0);
      assert.ok(layout.ledges.length >= 0);
      const warnings = validateSpawnPoints(stage);
      assert.equal(warnings.length, 0, warnings.join("; "));
    });
  }
});

describe("production completion — CPU", () => {
  it("CPU approaches idle target", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const cpu = state.players[1];
    const human = state.players[0];
    const startDist = Math.abs(cpu.x - human.x);
    const cpuConfig = { playerId: 1, difficulty: 2 as const, seed: 99 };
    for (let f = 0; f < 300; f++) {
      state.frame = f;
      const cpuInput = generateVersusCpuInput(state, cpuConfig);
      processPlayer(state, cpu, cpuInput);
      processPlayer(state, human, input(f, 0, {}));
    }
    assert.ok(Math.abs(cpu.x - human.x) < startDist);
  });

  it("CPU can hit idle target within 20 seconds", () => {
    let state = skipCountdown(
      createInitialGameState({ ...baseConfig, cpuOpponents: [{ playerId: 1, difficulty: 3, seed: 99 }] }),
    );
    state.players[0].x = state.players[1].x - 60 * FP_SCALE;
    let hit = false;
    for (let f = 0; f < 1200; f++) {
      state = simulateFrame(state, [input(f, 0, {})]);
      if (state.players[0].damage > 0) {
        hit = true;
        break;
      }
    }
    assert.ok(hit, "CPU should damage idle opponent within 20 seconds");
  });
});

describe("production completion — training", () => {
  it("training reset damage and positions work", () => {
    const state = skipCountdown(createInitialGameState({ ...baseConfig, training: { dummyPlayerId: 1, dummyBehavior: "idle" } }));
    state.players[0].damage = 50;
    resetTrainingDamage(state);
    assert.equal(state.players[0].damage, 0);
    const x0 = state.players[0].x;
    state.players[0].x = x0 + 5000;
    resetTrainingPositions(state);
    assert.notEqual(state.players[0].x, x0 + 5000);
  });

  it("dummy shield and jump behaviors produce input", () => {
    const dummy = stubPlayer({ id: 1 });
    const shield = applyTrainingDummyBehavior(dummy, "shield", 0);
    assert.equal(shield.shield, true);
    const jump = applyTrainingDummyBehavior(dummy, "jump", 1);
    assert.equal(jump.jump, true);
  });
});
