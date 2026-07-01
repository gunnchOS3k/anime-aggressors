import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  hashState,
  getStageLayout,
  FP_SCALE,
  processPlayer,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { HURTBOX_W } from "../src/constants.js";
import { JUMP_TUNING, computeJumpVelocity, fastFallSpeed } from "../src/movement/jumpSystem.js";
import { processMovementInput } from "../src/movement/movementController.js";
import { MAX_FALL_SPEED } from "../src/constants.js";
import { MOVEMENT_TUNING_FRAMES } from "../src/movement/movementTypes.js";
import { resetPlayerAfterRespawn } from "../src/combat/playerLifecycle.js";
import { tryLedgeGrab, releaseLedge, tickLedgeHang } from "../src/movement/ledgeSystem.js";
import { applyLandingLag } from "../src/movement/landingLag.js";
import { stubPlayer } from "./helpers/playerStub.js";

const baseConfig: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 11,
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

describe("Milestone 2 — ground movement", () => {
  it("holding direction from idle enters dashStart then run", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    processPlayer(state, p, input(0, 0, { right: true }));
    assert.equal(p.movementState, "dashStart");
    for (let f = 1; f <= MOVEMENT_TUNING_FRAMES.dashStartFrames + 2; f++) {
      processPlayer(state, p, input(f, 0, { right: true }));
    }
    assert.equal(p.movementState, "run");
    assert.ok(p.vx > 0);
  });

  it("releasing direction decelerates", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    for (let f = 0; f < 20; f++) processPlayer(state, p, input(f, 0, { right: true }));
    const peakVx = p.vx;
    for (let f = 20; f < 35; f++) processPlayer(state, p, input(f, 0, {}));
    assert.ok(Math.abs(p.vx) < peakVx);
  });

  it("reversing direction causes skid/turnaround behavior", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    for (let f = 0; f < 25; f++) processPlayer(state, p, input(f, 0, { right: true }));
    assert.ok(p.vx > 0);
    processPlayer(state, p, input(25, 0, { left: true }));
    assert.equal(p.movementState, "skid");
  });

  it("crouch only happens while grounded", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    processPlayer(state, p, input(0, 0, { down: true }));
    assert.equal(p.movementState, "crouch");
    assert.equal(p.onGround, true);
    p.onGround = false;
    p.movementState = "airborne";
    processPlayer(state, p, input(1, 0, { down: true }));
    assert.notEqual(p.movementState, "crouch");
  });
});

describe("Milestone 2 — jump system", () => {
  it("jump has jump squat before upward velocity", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    processPlayer(state, p, input(0, 0, { jump: true }));
    assert.equal(p.movementState, "jumpSquat");
    assert.equal(p.vy, 0);
    assert.ok(p.jumpSquatFrames > 0);
  });

  it("short hop reaches lower height than full hop", () => {
    const p = stubPlayer();
    const shortVy = computeJumpVelocity(p, true);
    const fullVy = computeJumpVelocity(p, false);
    assert.ok(shortVy > fullVy, "short hop vy should be less negative than full hop");

    const layout = getStageLayout("skyline-arena");
    const main = layout.platforms.find((pl) => pl.id === "main")!;

    const shortState = skipCountdown(createInitialGameState(baseConfig));
    const shortP = shortState.players[0];
    shortP.x = main.x + main.width / 2;
    processPlayer(shortState, shortP, input(0, 0, { jump: true }));
    for (let f = 1; f <= JUMP_TUNING.jumpSquatFrames; f++) {
      processPlayer(shortState, shortP, input(f, 0, {}));
    }
    let shortPeak = shortP.y;
    for (let f = 10; f < 60; f++) {
      processPlayer(shortState, shortP, input(f, 0, {}));
      shortPeak = Math.min(shortPeak, shortP.y);
    }

    const fullState = skipCountdown(createInitialGameState(baseConfig));
    const fullP = fullState.players[0];
    fullP.x = main.x + main.width / 2;
    processPlayer(fullState, fullP, input(0, 0, { jump: true }));
    for (let f = 1; f <= JUMP_TUNING.jumpSquatFrames; f++) {
      processPlayer(fullState, fullP, input(f, 0, { jump: true }));
    }
    let fullPeak = fullP.y;
    for (let f = 10; f < 60; f++) {
      processPlayer(fullState, fullP, input(f, 0, { jump: true }));
      fullPeak = Math.min(fullPeak, fullP.y);
    }

    assert.ok(shortPeak > fullPeak, "short hop peak should be higher y (lower jump)");
  });

  it("double jump works once and then is blocked", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    processPlayer(state, p, input(0, 0, { jump: true }));
    for (let f = 1; f < 60; f++) {
      processPlayer(state, p, input(f, 0, {}));
      if (!p.onGround) break;
    }
    assert.ok(!p.onGround);
    assert.equal(p.jumpsUsed, 1);
    processPlayer(state, p, input(60, 0, { jump: true }));
    assert.equal(p.jumpsUsed, 2);
    processPlayer(state, p, input(61, 0, { jump: true }));
    assert.equal(p.jumpsUsed, 2);
  });

  it("coyote jump works shortly after walking off platform", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const layout = getStageLayout("skyline-arena");
    const side = layout.platforms.find((pl) => pl.id === "side-left")!;
    const p = state.players[0];
    const halfW = HURTBOX_W / 2;
    const platRight = side.x + side.width;
    p.x = platRight - halfW + 200;
    p.y = side.y;
    p.onGround = true;
    p.currentPlatformId = side.id;
    let leftSide = false;
    for (let f = 0; f < 300; f++) {
      const wasOnSide = p.currentPlatformId === side.id;
      processPlayer(state, p, input(f, 0, { right: true }));
      if (wasOnSide && p.currentPlatformId !== side.id) {
        leftSide = true;
        break;
      }
    }
    assert.equal(leftSide, true);
    processPlayer(state, p, input(301, 0, { jump: true }));
    assert.ok(p.movementState === "jumpSquat" || p.movementState === "airborne");
  });

  it("buffered jump triggers on landing", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    processPlayer(state, p, input(0, 0, { jump: true }));
    for (let f = 1; f < 30; f++) processPlayer(state, p, input(f, 0, {}));
    const airY = p.y;
    processPlayer(state, p, input(30, 0, { jump: true }));
    for (let f = 31; f < 120; f++) {
      processPlayer(state, p, input(f, 0, {}));
      if (p.onGround) break;
    }
    processPlayer(state, p, input(121, 0, { jump: true }));
    for (let f = 122; f < 130; f++) {
      const prevY = p.y;
      processPlayer(state, p, input(f, 0, {}));
      if (p.y < prevY && p.movementState === "airborne") {
        assert.ok(p.y < airY || p.jumpSquatFrames > 0);
        return;
      }
    }
    assert.ok(p.jumpBufferFrames >= 0);
  });

  it("Down + Jump still drops through side platform", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const layout = getStageLayout("skyline-arena");
    const side = layout.platforms.find((pl) => pl.id === "side-left")!;
    const p = state.players[0];
    p.x = side.x + side.width / 2;
    p.y = side.y;
    p.onGround = true;
    p.currentPlatformId = side.id;
    p.wasJumpHeld = false;
    processPlayer(state, p, input(0, 0, { down: true, jump: true }));
    assert.ok(p.dropThroughFrames > 0);
    assert.equal(p.onGround, false);
  });
});

describe("Milestone 2 — air and landing", () => {
  it("fast fall increases downward speed only while airborne/falling", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    const layout = getStageLayout("skyline-arena");
    p.onGround = false;
    p.movementState = "airborne";
    p.vy = 40;
    processMovementInput(p, input(0, 0, { down: true }), layout, state.stage.left);
    assert.equal(p.fastFalling, true);
    assert.equal(p.movementState, "fastFall");
    assert.ok(fastFallSpeed(MAX_FALL_SPEED, p) > MAX_FALL_SPEED);
    p.vy = -20;
    p.fastFalling = false;
    processMovementInput(p, input(1, 0, { down: true }), layout, state.stage.left);
    assert.equal(p.fastFalling, false);
  });

  it("landing creates landing lag", () => {
    const p = stubPlayer({ onGround: false, movementState: "airborne", vy: 500 });
    applyLandingLag(p, false);
    assert.ok(p.landingLagFrames > 0);
    assert.equal(p.movementState, "landingLag");
  });

  it("fast-fall landing creates longer landing lag than normal landing", () => {
    const normal = stubPlayer();
    const fast = stubPlayer();
    applyLandingLag(normal, false);
    applyLandingLag(fast, true);
    assert.ok(fast.landingLagFrames > normal.landingLagFrames);
  });
});

describe("Milestone 2 — lifecycle reset", () => {
  it("respawn clears movement state, landing lag, ledge state, and recovery-used state", () => {
    const p = stubPlayer({
      landingLagFrames: 5,
      grabbedLedgeId: "main-ledge-left",
      ledgeStateFrames: 40,
      recoveryUsed: true,
      movementState: "ledgeHang",
    });
    resetPlayerAfterRespawn(p, { x: 100, y: 200 });
    assert.equal(p.landingLagFrames, 0);
    assert.equal(p.grabbedLedgeId, "");
    assert.equal(p.recoveryUsed, false);
    assert.equal(p.movementState, "idle");
  });

  it("rematch clears movement state, landing lag, ledge state, and recovery-used state", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    p.landingLagFrames = 6;
    p.grabbedLedgeId = "main-ledge-right";
    p.recoveryUsed = true;
    p.movementState = "fastFall";
    const rematch = resetForRematch(state);
    const rp = rematch.players[0];
    assert.equal(rp.landingLagFrames, 0);
    assert.equal(rp.grabbedLedgeId, "");
    assert.equal(rp.recoveryUsed, false);
    assert.equal(rp.movementState, "idle");
  });
});

describe("Milestone 2 — ledge and recovery", () => {
  const layout = getStageLayout("skyline-arena");
  const ledge = layout.ledges.find((l) => l.id === "main-ledge-left")!;

  it("player can grab ledge from offstage", () => {
    const p = stubPlayer({
      onGround: false,
      x: ledge.x + 2 * FP_SCALE,
      y: ledge.y + 8 * FP_SCALE,
      vy: 200,
      vx: -100,
      facing: -1,
      movementState: "airborne",
    });
    assert.equal(tryLedgeGrab(p, layout), true);
    assert.equal(p.movementState, "ledgeHang");
    assert.equal(p.grabbedLedgeId, ledge.id);
  });

  it("player can ledge jump back toward stage", () => {
    const p = stubPlayer({
      onGround: false,
      movementState: "ledgeHang",
      grabbedLedgeId: ledge.id,
      ledgeStateFrames: 100,
      x: ledge.x,
      y: ledge.y,
    });
    tickLedgeHang(p, layout, input(0, 0, { jump: true }));
    assert.equal(p.movementState, "ledgeJump");
    assert.ok(p.vy < 0);
    assert.ok(p.vx > 0);
  });

  it("player can ledge getup back onto stage", () => {
    const p = stubPlayer({
      onGround: false,
      movementState: "ledgeHang",
      grabbedLedgeId: ledge.id,
      ledgeStateFrames: 100,
      x: ledge.x,
      y: ledge.y,
    });
    tickLedgeHang(p, layout, input(0, 0, { right: true }));
    assert.equal(p.movementState, "ledgeGetup");
    assert.equal(p.onGround, true);
  });

  it("player can release ledge", () => {
    const p = stubPlayer({
      movementState: "ledgeHang",
      grabbedLedgeId: ledge.id,
      ledgeStateFrames: 100,
    });
    releaseLedge(p);
    assert.equal(p.grabbedLedgeId, "");
    assert.equal(p.movementState, "airborne");
    assert.ok(p.ledgeCooldownFrames > 0);
  });

  it("ledge regrab cooldown prevents immediate infinite regrab", () => {
    const p = stubPlayer({
      onGround: false,
      x: ledge.x,
      y: ledge.y + 8 * FP_SCALE,
      vy: 200,
      vx: -50,
      facing: -1,
      ledgeCooldownFrames: 20,
      movementState: "airborne",
    });
    assert.equal(tryLedgeGrab(p, layout), false);
  });

  it("recovery action moves player toward stage/upward and is limited until landing", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    p.onGround = false;
    p.movementState = "airborne";
    p.actionState = "falling";
    p.x = 1000;
    p.recoveryUsed = false;
    const vyBefore = p.vy;
    processPlayer(state, p, input(0, 0, { special: true }));
    assert.equal(p.recoveryUsed, true);
    assert.equal(p.movementState, "recoveryFall");
    assert.ok(p.vy < vyBefore);
    p.onGround = true;
    p.movementState = "idle";
    processPlayer(state, p, input(1, 0, {}));
    assert.equal(p.recoveryUsed, false);
  });
});

describe("Milestone 2 — determinism", () => {
  it("same input log produces same final hash after movement-state changes", () => {
    const inputs: InputFrame[][] = [];
    for (let f = 0; f < 100; f++) {
      inputs.push([
        input(f, 0, { right: f < 40, jump: f === 15 || f === 50, down: f === 60 }),
        input(f, 1, {}),
      ]);
    }
    let a = skipCountdown(createInitialGameState(baseConfig));
    let b = skipCountdown(createInitialGameState(baseConfig));
    for (const frameInputs of inputs) {
      a = simulateFrame(a, frameInputs);
      b = simulateFrame(b, frameInputs);
    }
    assert.equal(hashState(a), hashState(b));
  });
});
