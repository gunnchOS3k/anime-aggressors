import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  hashState,
  getStageLayout,
  FP_SCALE,
  BLAST_LEFT,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { HURTBOX_W } from "../src/constants.js";
import {
  resolveStageCollision,
  beginDropThrough,
  isPassThroughPlatform,
  DROP_THROUGH_IGNORE_FRAMES,
} from "../src/stageCollision.js";
import { processPlayer } from "../src/combat.js";
import { processBlastZoneKOs } from "../src/combat/hitResolution.js";
import { RESPAWN_INVULN_FRAMES } from "../src/combat/playerLifecycle.js";

const baseConfig: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 7,
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

function skipCountdown(state: ReturnType<typeof createInitialGameState>) {
  let s = state;
  while (s.phase === "countdown") {
    s = simulateFrame(s, []);
  }
  return s;
}

describe("Milestone 1 — determinism", () => {
  it("same config + same input log produces same final hash", () => {
    const inputs: InputFrame[][] = [];
    for (let f = 0; f < 120; f++) {
      inputs.push([
        makeInput(f, 0, { right: f > 20 && f < 60 }),
        makeInput(f, 1, { left: f > 40 && f < 80 }),
      ]);
    }
    let a = createInitialGameState(baseConfig);
    let b = createInitialGameState(baseConfig);
    for (const frameInputs of inputs) {
      a = simulateFrame(a, frameInputs);
      b = simulateFrame(b, frameInputs);
    }
    assert.equal(hashState(a), hashState(b));
  });

  it("different input log produces a different final hash", () => {
    let stateA = skipCountdown(createInitialGameState(baseConfig));
    let stateB = skipCountdown(createInitialGameState(baseConfig));
    for (let f = 0; f < 60; f++) {
      stateA = simulateFrame(stateA, [makeInput(f, 0, { right: true }), makeInput(f, 1, {})]);
      stateB = simulateFrame(stateB, [makeInput(f, 0, { left: true }), makeInput(f, 1, {})]);
    }
    assert.notEqual(hashState(stateA), hashState(stateB));
  });
});

describe("Milestone 1 — platform collision", () => {
  const layout = getStageLayout("skyline-arena");
  const main = layout.platforms.find((p) => p.id === "main")!;
  const side = layout.platforms.find((p) => p.id === "side-left")!;

  it("falling player lands on main platform", () => {
    const player = createInitialGameState(baseConfig).players[0];
    player.x = main.x + main.width / 2;
    const previousY = main.y - 20 * FP_SCALE;
    player.y = main.y + 2 * FP_SCALE;
    player.vy = 300;
    player.onGround = false;
    const result = resolveStageCollision(player, layout, main.y, previousY);
    assert.equal(result.landed, true);
    assert.equal(result.platformId, "main");
    assert.equal(player.y, main.y);
    assert.equal(player.vy, 0);
  });

  it("falling player lands on side platform", () => {
    const player = createInitialGameState(baseConfig).players[0];
    player.x = side.x + side.width / 2;
    const previousY = side.y - 15 * FP_SCALE;
    player.y = side.y + 2 * FP_SCALE;
    player.vy = 250;
    player.onGround = false;
    const result = resolveStageCollision(player, layout, main.y, previousY);
    assert.equal(result.landed, true);
    assert.equal(result.platformId, "side-left");
    assert.equal(player.y, side.y);
  });

  it("rising player does not snap onto a platform from below", () => {
    const player = createInitialGameState(baseConfig).players[0];
    player.x = side.x + side.width / 2;
    player.y = side.y + 30 * FP_SCALE;
    player.vy = -200;
    const previousY = player.y;
    player.y += player.vy;
    const result = resolveStageCollision(player, layout, main.y, previousY);
    assert.equal(result.landed, false);
    assert.ok(player.y > side.y);
  });

  it("player can walk off a platform and begin falling", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    const halfW = HURTBOX_W / 2;
    const platRight = side.x + side.width;
    p.x = platRight - halfW + 200;
    p.y = side.y;
    p.onGround = true;
    p.currentPlatformId = side.id;
    p.vx = 0;
    p.vy = 0;
    let leftSide = false;
    for (let f = 0; f < 300; f++) {
      const wasOnSide = p.currentPlatformId === side.id;
      processPlayer(state, p, makeInput(f, 0, { right: true }));
      if (wasOnSide && p.currentPlatformId !== side.id) {
        leftSide = true;
        assert.equal(p.onGround, false, "walking off edge should leave the ground");
        break;
      }
    }
    assert.equal(leftSide, true, "player should leave side platform support");
  });
});

describe("Milestone 1 — drop-through", () => {
  const layout = getStageLayout("skyline-arena");
  const side = layout.platforms.find((p) => p.id === "side-left")!;
  const main = layout.platforms.find((p) => p.id === "main")!;

  it("Down + Jump drops through a side platform", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    p.x = side.x + side.width / 2;
    p.y = side.y;
    p.onGround = true;
    p.currentPlatformId = side.id;
    p.wasJumpHeld = false;

    processPlayer(state, p, makeInput(0, 0, { down: true, jump: true }));

    assert.equal(p.dropThroughFrames, DROP_THROUGH_IGNORE_FRAMES);
    assert.equal(p.ignoredPlatformId, side.id);
    assert.equal(p.onGround, false);

    const previousY = p.y;
    p.y += 40 * FP_SCALE;
    p.vy = 200;
    const result = resolveStageCollision(p, layout, main.y, previousY);
    assert.equal(result.landed, false);
  });

  it("drop-through does not affect main floor", () => {
    assert.equal(isPassThroughPlatform(layout, main.id), false);
    const p = createInitialGameState(baseConfig).players[0];
    p.x = main.x + main.width / 2;
    p.y = main.y;
    p.onGround = true;
    p.currentPlatformId = main.id;
    p.wasJumpHeld = false;
    let state = skipCountdown(createInitialGameState(baseConfig));
    processPlayer(state, p, makeInput(0, 0, { down: true, jump: true }));
    assert.equal(p.dropThroughFrames, 0);
    assert.equal(p.ignoredPlatformId, "");
  });
});

describe("Milestone 1 — blast zones, stocks, respawn, match end", () => {
  it("player crossing blast zone loses stock", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    const stocksBefore = p.stocks;
    p.x = BLAST_LEFT - 1000;
    processBlastZoneKOs(state);
    assert.equal(p.stocks, stocksBefore - 1);
  });

  it("player respawns with reset damage and invulnerability when stocks remain", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    p.damage = 87;
    p.hitstunFrames = 20;
    p.currentMoveId = "neutral_attack";
    p.dropThroughFrames = 10;
    p.ignoredPlatformId = "side-left";
    p.x = BLAST_LEFT - 500;
    processBlastZoneKOs(state);
    assert.ok(p.stocks > 0);
    assert.equal(p.damage, 0);
    assert.equal(p.hitstunFrames, 0);
    assert.equal(p.currentMoveId, "none");
    assert.equal(p.dropThroughFrames, 0);
    assert.equal(p.ignoredPlatformId, "");
    assert.equal(p.invulnFrames, RESPAWN_INVULN_FRAMES);
    assert.equal(p.onGround, true);
  });

  it("player reaches defeated state when stocks reach zero", () => {
    let state = skipCountdown(createInitialGameState({ ...baseConfig, stocks: 1 }));
    const p = state.players[0];
    p.stocks = 1;
    p.x = BLAST_LEFT - 500;
    processBlastZoneKOs(state);
    assert.equal(p.stocks, 0);
    assert.equal(p.actionState, "defeated");
  });

  it("match enters results when one player remains", () => {
    let state = skipCountdown(createInitialGameState({ ...baseConfig, stocks: 1 }));
    state.players[1].stocks = 1;
    state.players[1].x = BLAST_LEFT - 500;
    state = simulateFrame(state, [makeInput(0, 0, {}), makeInput(0, 1, {})]);
    assert.equal(state.phase, "results");
    assert.equal(state.winnerId, 0);
    assert.equal(state.players[1].actionState, "defeated");
  });

  it("rematch/reset clears movement/combat/drop-through state", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    p.damage = 55;
    p.dropThroughFrames = 12;
    p.ignoredPlatformId = "side-left";
    p.currentPlatformId = "side-left";
    p.hitVictimsThisMove = [1];
    p.stocks = 1;
    const rematch = resetForRematch(state);
    const rp = rematch.players[0];
    assert.equal(rp.damage, 0);
    assert.equal(rp.stocks, baseConfig.stocks);
    assert.equal(rp.dropThroughFrames, 0);
    assert.equal(rp.ignoredPlatformId, "");
    assert.equal(rp.currentPlatformId, "main");
    assert.deepEqual(rp.hitVictimsThisMove, []);
    assert.equal(rematch.phase, "countdown");
    assert.equal(rematch.winnerId, null);
  });
});
