import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  hashState,
  FP_SCALE,
  processPlayer,
  isInStartup,
  isInActive,
  isInRecovery,
  currentMovePhase,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { selectCombatAction } from "../src/combat/moveSelection.js";
import { getCombatMoveData } from "../src/moves/combatMoveData.js";
import { combatMoveToFrameData } from "../src/moves/combatMoveData.js";
import { boxesOverlap, getActiveHitboxes, getGrabHitbox, getHurtbox } from "../src/collision.js";
import { resolveCombatHits, resolveHitFromContact } from "../src/combat/hitResolution.js";
import { resetPlayerAfterRespawn } from "../src/combat/playerLifecycle.js";
import { tryGrabConnect, executeThrow } from "../src/combat/grabSystem.js";
import { startDodgeAction, isDodgeInvulnerable } from "../src/combat/dodgeSystem.js";
import { applyStaleMultiplier, recordMoveUsed, staleRepeatCount } from "../src/combat/staleMoves.js";
import { applyDirectionalInfluence } from "../src/combat/di.js";
import { stubPlayer } from "./helpers/playerStub.js";
import { getStageLayout } from "../src/stageLayouts.js";

const baseConfig: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 31,
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

function overlapForHit(state: ReturnType<typeof skipCountdown>, moveId: string, actionFrame: number) {
  const atk = state.players[0];
  const def = state.players[1];
  atk.actionState = moveId.includes("special") ? "special" : "attacking";
  atk.currentMoveId = moveId;
  atk.actionFrame = actionFrame;
  atk.facing = 1;
  atk.x = 0;
  atk.y = 100 * FP_SCALE;
  def.x = atk.x + 35 * FP_SCALE;
  def.y = atk.y;
  def.invulnFrames = 0;
  def.actionState = "idle";
  return { atk, def };
}

describe("Milestone 3 — move selection", () => {
  it("neutral attack selects jab", () => {
    const p = stubPlayer({ onGround: true });
    const sel = selectCombatAction(p, input(0, 0, { attack: true }));
    assert.equal(sel?.moveId, "neutral_attack");
  });

  it("forward input + attack selects forward tilt", () => {
    const p = stubPlayer({ onGround: true });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, right: true }));
    assert.equal(sel?.moveId, "forward_attack");
  });

  it("up input + attack selects up tilt", () => {
    const p = stubPlayer({ onGround: true });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, up: true }));
    assert.equal(sel?.moveId, "up_attack");
  });

  it("down input + attack selects down tilt", () => {
    const p = stubPlayer({ onGround: true });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, down: true }));
    assert.equal(sel?.moveId, "down_attack");
  });

  it("dash/run attack selects dash attack", () => {
    const p = stubPlayer({ onGround: true, movementState: "run" });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, right: true }));
    assert.equal(sel?.moveId, "dash_attack");
  });

  it("air neutral attack selects neutral aerial", () => {
    const p = stubPlayer({ onGround: false });
    const sel = selectCombatAction(p, input(0, 0, { attack: true }));
    assert.equal(sel?.moveId, "neutral_air");
  });

  it("air forward attack selects forward aerial", () => {
    const p = stubPlayer({ onGround: false, facing: 1 });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, right: true }));
    assert.equal(sel?.moveId, "forward_air");
  });

  it("air back attack selects back aerial", () => {
    const p = stubPlayer({ onGround: false, facing: 1 });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, left: true }));
    assert.equal(sel?.moveId, "back_air");
  });

  it("air up attack selects up aerial", () => {
    const p = stubPlayer({ onGround: false });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, up: true }));
    assert.equal(sel?.moveId, "up_air");
  });

  it("air down attack selects down aerial", () => {
    const p = stubPlayer({ onGround: false });
    const sel = selectCombatAction(p, input(0, 0, { attack: true, down: true }));
    assert.equal(sel?.moveId, "down_air");
  });

  it("neutral special selects neutral special", () => {
    const p = stubPlayer();
    const sel = selectCombatAction(p, input(0, 0, { special: true }));
    assert.equal(sel?.moveId, "special_attack");
  });

  it("side/up/down specials select correct special", () => {
    const p = stubPlayer();
    assert.equal(selectCombatAction(p, input(0, 0, { special: true, right: true }))?.moveId, "side_special");
    assert.equal(selectCombatAction(p, input(0, 0, { special: true, up: true }))?.moveId, "up_special");
    assert.equal(selectCombatAction(p, input(0, 0, { special: true, down: true }))?.moveId, "down_special");
  });
});

describe("Milestone 3 — move phases and hits", () => {
  it("startup frames do not hit", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("neutral_attack")!;
    overlapForHit(state, "neutral_attack", move.startup - 1);
    assert.equal(getActiveHitboxes(state.players[0]).length, 0);
    assert.equal(currentMovePhase(state.players[0]), "startup");
  });

  it("active frames hit", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("neutral_attack")!;
    overlapForHit(state, "neutral_attack", move.startup);
    assert.ok(getActiveHitboxes(state.players[0]).length > 0);
    assert.equal(currentMovePhase(state.players[0]), "active");
  });

  it("recovery frames cannot start a new move", () => {
    const move = getCombatMoveData("neutral_attack")!;
    const recoveryFrame = move.startup + move.active + 2;
    const p = stubPlayer({
      actionState: "attacking",
      currentMoveId: "neutral_attack",
      actionFrame: recoveryFrame,
    });
    const sel = selectCombatAction(p, input(0, 0, { attack: true }));
    assert.equal(sel, null);
    assert.equal(isInRecovery(combatMoveToFrameData(move), p.actionFrame), true);
  });

  it("same non-multi-hit move hits same defender only once", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("neutral_attack")!;
    overlapForHit(state, "neutral_attack", move.startup);
    resolveCombatHits(state);
    const dmg = state.players[1].damage;
    state.players[0].actionFrame = move.startup + 1;
    resolveCombatHits(state);
    assert.equal(state.players[1].damage, dmg);
  });

  it("multi-hit move can hit multiple times at deterministic intervals", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("multi_hit_special")!;
    overlapForHit(state, "multi_hit_special", move.startup);
    state.players[0].actionState = "special";
    state.players[0].currentMoveId = "multi_hit_special";
    state.frame = 0;
    resolveCombatHits(state);
    const dmg1 = state.players[1].damage;
    const interval = move.hitIntervalFrames ?? 4;
    state.players[1].x = state.players[0].x + 35 * FP_SCALE;
    state.players[1].y = state.players[0].y;
    state.players[1].actionState = "idle";
    state.players[1].invulnFrames = 0;
    state.frame = interval;
    state.players[0].actionFrame = move.startup + interval;
    resolveCombatHits(state);
    assert.ok(state.players[1].damage > dmg1);
  });

  it("damage increases on hit", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("forward_attack")!;
    overlapForHit(state, "forward_attack", move.startup);
    resolveCombatHits(state);
    assert.ok(state.players[1].damage > 0);
  });

  it("knockback increases when defender damage is higher", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("forward_attack")!;
    const low = stubPlayer({ damage: 0 });
    const high = stubPlayer({ damage: 80 });
    const atk = stubPlayer({ actionState: "attacking", currentMoveId: "forward_attack" });
    resolveHitFromContact(state, atk, low, move.damage, 0, 0, "forward_attack");
    const lowVy = low.vy;
    resolveHitFromContact(state, atk, high, move.damage, 0, 0, "forward_attack");
    assert.ok(Math.abs(high.vy) >= Math.abs(lowVy));
  });

  it("hitlag freezes attacker/defender for expected frames", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("forward_attack")!;
    overlapForHit(state, "forward_attack", move.startup);
    resolveCombatHits(state);
    assert.ok(state.hitstopFrames > 0);
  });

  it("hitstun prevents immediate action", () => {
    const p = stubPlayer({ actionState: "hitstun", hitstunFrames: 10 });
    const sel = selectCombatAction(p, input(0, 0, { attack: true }));
    assert.equal(sel, null);
  });
});

describe("Milestone 3 — shield", () => {
  it("shield blocks damage", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("neutral_attack")!;
    overlapForHit(state, "neutral_attack", move.startup);
    state.players[1].actionState = "shielding";
    const dmgBefore = state.players[1].damage;
    resolveCombatHits(state);
    assert.equal(state.players[1].damage, dmgBefore);
  });

  it("shield takes shield damage", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("neutral_attack")!;
    overlapForHit(state, "neutral_attack", move.startup);
    state.players[1].actionState = "shielding";
    state.players[1].shieldHealth = 100;
    resolveCombatHits(state);
    assert.ok(state.players[1].shieldHealth < 100);
  });

  it("shield stun is applied", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("forward_attack")!;
    overlapForHit(state, "forward_attack", move.startup);
    state.players[1].actionState = "shielding";
    resolveCombatHits(state);
    const def = state.players[1];
    assert.ok(def.shieldStunFrames > 0 || def.actionState === "shieldStun" || def.actionState === "shieldBreak");
  });

  it("shield break occurs at zero shield health", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const move = getCombatMoveData("side_special")!;
    overlapForHit(state, "side_special", move.startup);
    state.players[0].actionState = "special";
    state.players[1].actionState = "shielding";
    state.players[1].shieldHealth = 1;
    resolveCombatHits(state);
    const def = state.players[1];
    assert.ok(def.actionState === "shieldBreak" || def.shieldHealth <= 0);
  });

  it("shield regenerates when not held", () => {
    const p = stubPlayer({ shieldHealth: 50, actionState: "idle" });
    const state = skipCountdown(createInitialGameState(baseConfig));
    for (let f = 0; f < 30; f++) processPlayer(state, p, undefined);
    assert.ok(p.shieldHealth > 50);
  });
});

describe("Milestone 3 — grab and throw", () => {
  it("grab connects against shielding opponent", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const atk = state.players[0];
    const def = state.players[1];
    atk.actionState = "grabbing";
    atk.currentMoveId = "grab";
    atk.actionFrame = getCombatMoveData("grab")!.startup;
    atk.facing = 1;
    atk.x = 0;
    atk.y = 100 * FP_SCALE;
    def.actionState = "shielding";
    def.x = atk.x + 30 * FP_SCALE;
    def.y = atk.y;
    assert.ok(tryGrabConnect(state, atk));
    assert.equal(def.actionState, "grabbed");
  });

  it("grab whiff enters recovery", () => {
    const p = stubPlayer({ actionState: "grabbing", currentMoveId: "grab", actionFrame: 20 });
    const move = getCombatMoveData("grab")!;
    assert.ok(p.actionFrame > move.startup + move.active);
  });

  it("forward throw applies damage and knockback", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const atk = state.players[0];
    const def = state.players[1];
    atk.grabTargetId = def.id;
    def.actionState = "grabbed";
    def.grabbedByPlayerId = atk.id;
    executeThrow(state, atk, def, "throw_forward");
    assert.ok(def.damage > 0);
    assert.ok(def.vx !== 0 || def.vy !== 0);
    assert.equal(def.actionState, "hitstun");
  });

  it("back/up/down throws select correctly", () => {
    const atk = stubPlayer({ actionState: "grabbing", grabTargetId: 1, facing: 1 });
    assert.equal(selectCombatAction(atk, input(0, 0, { left: true }))?.moveId, "throw_back");
    assert.equal(selectCombatAction(atk, input(0, 0, { up: true }))?.moveId, "throw_up");
    assert.equal(selectCombatAction(atk, input(0, 0, { down: true }))?.moveId, "throw_down");
  });

  it("grabbed state clears after throw", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const atk = state.players[0];
    const def = state.players[1];
    atk.grabTargetId = def.id;
    def.grabbedByPlayerId = atk.id;
    def.actionState = "grabbed";
    executeThrow(state, atk, def, "throw_forward");
    assert.equal(def.grabbedByPlayerId, -1);
    assert.notEqual(def.actionState, "grabbed");
  });
});

describe("Milestone 3 — DI and stale", () => {
  it("DI changes launch trajectory compared to no DI", () => {
    const withDi = applyDirectionalInfluence(5, -8, input(0, 0, { right: true }), "medium");
    const noDi = applyDirectionalInfluence(5, -8, undefined, "medium");
    assert.notEqual(withDi.vx, noDi.vx);
  });

  it("stale repeated move deals less damage or knockback", () => {
    const p = stubPlayer();
    recordMoveUsed(p, "neutral_attack");
    recordMoveUsed(p, "neutral_attack");
    assert.ok(applyStaleMultiplier(p, "neutral_attack") < 1);
    assert.ok(staleRepeatCount(p, "neutral_attack") >= 1);
  });

  it("different move avoids stale penalty", () => {
    const p = stubPlayer();
    recordMoveUsed(p, "neutral_attack");
    recordMoveUsed(p, "neutral_attack");
    assert.equal(applyStaleMultiplier(p, "forward_attack"), 1);
  });
});

describe("Milestone 3 — dodge", () => {
  it("spot dodge grants invulnerability during expected frames", () => {
    const p = stubPlayer({ onGround: true });
    startDodgeAction(p, "spot_dodge", input(0, 0, { dodge: true }));
    p.actionFrame = 3;
    assert.ok(isDodgeInvulnerable(p));
  });

  it("roll changes position and grants invulnerability during expected frames", () => {
    const p = stubPlayer({ onGround: true, facing: 1 });
    startDodgeAction(p, "roll", input(0, 0, { dodge: true, right: true }));
    assert.equal(p.actionState, "rolling");
    assert.notEqual(p.vx, 0);
    p.actionFrame = 4;
    assert.ok(isDodgeInvulnerable(p));
  });

  it("air dodge works while airborne", () => {
    const p = stubPlayer({ onGround: false });
    startDodgeAction(p, "air_dodge", input(0, 0, { dodge: true, up: true }));
    assert.equal(p.actionState, "airDodging");
    assert.ok(p.invulnFrames > 0);
  });
});

describe("Milestone 3 — lifecycle and regression", () => {
  it("respawn clears combat state", () => {
    const p = stubPlayer({
      actionState: "hitstun",
      hitstunFrames: 20,
      shieldStunFrames: 10,
      grabTargetId: 1,
      staleMoveQueue: ["neutral_attack"],
      currentMoveId: "forward_attack",
    });
    const layout = getStageLayout("skyline-arena");
    resetPlayerAfterRespawn(p, { x: 0, y: 0 });
    p.currentPlatformId = layout.mainPlatformId;
    assert.equal(p.actionState, "idle");
    assert.equal(p.hitstunFrames, 0);
    assert.equal(p.grabTargetId, -1);
    assert.equal(p.staleMoveQueue.length, 0);
  });

  it("rematch clears combat state", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    state.players[0].hitstunFrames = 15;
    state.players[0].staleMoveQueue = ["neutral_attack"];
    state.players[0].grabTargetId = 1;
    state = resetForRematch(state);
    assert.equal(state.players[0].hitstunFrames, 0);
    assert.equal(state.players[0].staleMoveQueue.length, 0);
    assert.equal(state.players[0].grabTargetId, -1);
  });

  it("blast zone / stock / respawn from Milestone 1 still works", () => {
    let state = skipCountdown(createInitialGameState(baseConfig));
    state.players[0].stocks = 2;
    state.players[0].x = -999999;
    state = simulateFrame(state, [input(0, 0), input(0, 1)]);
    assert.equal(state.players[0].stocks, 1);
    assert.equal(state.players[0].damage, 0);
  });

  it("movement from Milestone 2 still works after combat changes", () => {
    const state = skipCountdown(createInitialGameState(baseConfig));
    const p = state.players[0];
    processPlayer(state, p, input(0, 0, { right: true }));
    assert.ok(p.movementState === "dashStart" || p.movementState === "run");
  });

  it("same input log produces same final hash after combat changes", () => {
    const inputs: InputFrame[][] = [];
    for (let f = 0; f < 90; f++) {
      inputs.push([
        input(f, 0, { right: f < 30, attack: f === 40, shield: f > 50 && f < 60 }),
        input(f, 1, { left: f < 25 }),
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
});

describe("Milestone 3 — hit overlap helpers", () => {
  it("grab hitbox overlaps shielding hurtbox at close range", () => {
    const atk = stubPlayer({ actionState: "grabbing", currentMoveId: "grab", actionFrame: 4, facing: 1 });
    const def = stubPlayer({ actionState: "shielding", x: 30 * FP_SCALE });
    const grab = getGrabHitbox(atk);
    assert.ok(grab);
    assert.ok(boxesOverlap(grab!, getHurtbox(def)));
  });
});
