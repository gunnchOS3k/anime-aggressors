import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  getStageLayout,
  STAGE_WIDTH,
  FP_SCALE,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { HURTBOX_W } from "../src/constants.js";
import { resolvePlatformLanding } from "../src/stageCollision.js";
import { processPlayer } from "../src/combat.js";

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

describe("stage platform collision", () => {
  it("player lands on main platform", () => {
    const layout = getStageLayout("skyline-arena");
    const main = layout.platforms.find((p) => p.id === "main")!;
    const player = createInitialGameState(config).players[0];
    player.x = STAGE_WIDTH / 2;
    const previousY = main.y - 20 * FP_SCALE;
    player.y = main.y + 2 * FP_SCALE;
    player.vy = 300;
    player.onGround = false;
    const landed = resolvePlatformLanding(player, layout, previousY);
    assert.equal(landed, true);
    assert.equal(player.y, main.y);
    assert.equal(player.vy, 0);
  });

  it("player lands on side platform", () => {
    const layout = getStageLayout("skyline-arena");
    const side = layout.platforms.find((p) => p.id === "side-left")!;
    const player = createInitialGameState(config).players[0];
    player.x = side.x + side.width / 2;
    const previousY = side.y - 15 * FP_SCALE;
    player.y = side.y + 2 * FP_SCALE;
    player.vy = 250;
    player.onGround = false;
    const landed = resolvePlatformLanding(player, layout, previousY);
    assert.equal(landed, true);
    assert.equal(player.y, side.y);
  });

  it("player falls past a platform when moving upward from below", () => {
    const layout = getStageLayout("skyline-arena");
    const side = layout.platforms.find((p) => p.id === "side-left")!;
    const player = createInitialGameState(config).players[0];
    player.x = side.x + side.width / 2;
    player.y = side.y + 30 * FP_SCALE;
    player.vy = -200;
    const previousY = player.y;
    player.y += player.vy;
    const landed = resolvePlatformLanding(player, layout, previousY);
    assert.equal(landed, false);
    assert.ok(player.y > side.y);
  });

  it("player resets jumps on landing via processPlayer", () => {
    const state = createInitialGameState(config);
    state.phase = "fighting";
    const p = state.players[0];
    p.x = STAGE_WIDTH / 2;
    processPlayer(state, p, input(0, 0, { jump: true }));
    for (let f = 1; f <= 3; f++) {
      processPlayer(state, p, input(f, 0, {}));
    }
    p.jumpsRemaining = 0;
    p.jumpsUsed = 2;
    for (let f = 4; f < 120; f++) {
      processPlayer(state, p, input(f, 0, {}));
      if (p.onGround) break;
    }
    assert.equal(p.onGround, true);
    assert.equal(p.jumpsUsed, 0);
    assert.ok(p.jumpsRemaining > 0);
  });
});

describe("platform collision horizontal bounds", () => {
  it("misses platform when horizontally out of range", () => {
    const layout = getStageLayout("skyline-arena");
    const side = layout.platforms.find((p) => p.id === "side-left")!;
    const player = createInitialGameState(config).players[0];
    player.x = side.x - HURTBOX_W;
    const previousY = side.y - 10 * FP_SCALE;
    player.y = side.y + 2 * FP_SCALE;
    player.vy = 300;
    assert.equal(resolvePlatformLanding(player, layout, previousY), false);
  });
});
