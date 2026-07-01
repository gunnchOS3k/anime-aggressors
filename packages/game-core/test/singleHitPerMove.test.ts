import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  simulateFrame,
  NEUTRAL_ATTACK,
  FP_SCALE,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { boxesOverlap, getActiveHitboxes, getHurtbox } from "../src/collision.js";
import { resolveCombatHits } from "../src/combat/hitResolution.js";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 42,
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

function fightingState() {
  let state = createInitialGameState(config);
  while (state.phase === "countdown") {
    state = simulateFrame(state, []);
  }
  return state;
}

function overlapAttackers(state: ReturnType<typeof fightingState>) {
  const p0 = state.players[0];
  const p1 = state.players[1];
  p0.actionState = "attacking";
  p0.actionFrame = NEUTRAL_ATTACK.startup;
  p0.currentMoveId = "neutral_attack";
  p0.facing = 1;
  p1.x = p0.x + 40 * FP_SCALE;
  p1.y = p0.y;
  p1.invulnFrames = 0;
  p1.actionState = "idle";
}

describe("single hit per move instance", () => {
  it("attack overlaps hurtbox increases defender damage", () => {
    const state = fightingState();
    overlapAttackers(state);
    const dmgBefore = state.players[1].damage;
    const events = resolveCombatHits(state);
    assert.ok(events.length >= 1);
    assert.ok(state.players[1].damage > dmgBefore);
  });

  it("same move active for multiple frames does not repeatedly damage every frame", () => {
    const state = fightingState();
    overlapAttackers(state);
    resolveCombatHits(state);
    const dmgAfterFirst = state.players[1].damage;
    state.players[0].actionFrame = NEUTRAL_ATTACK.startup + 1;
    resolveCombatHits(state);
    assert.equal(state.players[1].damage, dmgAfterFirst);
  });

  it("defender enters hitstun on hit", () => {
    const state = fightingState();
    overlapAttackers(state);
    resolveCombatHits(state);
    assert.equal(state.players[1].actionState, "hitstun");
    assert.ok(state.players[1].hitstunFrames > 0);
  });

  it("defender receives knockback on hit", () => {
    const state = fightingState();
    overlapAttackers(state);
    const vxBefore = state.players[1].vx;
    const vyBefore = state.players[1].vy;
    resolveCombatHits(state);
    assert.ok(
      state.players[1].vx !== vxBefore || state.players[1].vy !== vyBefore,
      "knockback should change velocity",
    );
  });

  it("stocks decrease after leaving blast zone", () => {
    let state = fightingState();
    state.players[0].stocks = 1;
    state.players[0].x = -999999;
    state = simulateFrame(state, [input(0, 0), input(0, 1)]);
    assert.ok(
      state.players[0].stocks <= 0 || state.players[0].actionState === "defeated",
    );
  });
});

describe("hit overlap helpers", () => {
  it("active hitbox overlaps hurtbox when positioned correctly", () => {
    const state = fightingState();
    overlapAttackers(state);
    const hitboxes = getActiveHitboxes(state.players[0]);
    const hurt = getHurtbox(state.players[1]);
    assert.ok(hitboxes.length > 0);
    assert.ok(boxesOverlap(hitboxes[0], hurt));
  });
});
