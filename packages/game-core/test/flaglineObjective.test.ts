import { describe, it } from "node:test";
import assert from "node:assert/strict";
import type { PlayerState } from "../src/types.js";
import { createDefaultAuraState } from "../src/aura/auraTypes.js";
import { FP_SCALE, FLOOR_Y } from "../src/constants.js";
import { getFlaglineRoom } from "../src/modes/flaglineMaps.js";
import {
  updateFlagCoreCapture,
  checkCaptureWin,
  countTeamsInCore,
} from "../src/modes/flaglineObjective.js";
import { FLAGLINE_DEFAULTS, type FlaglineMetaState } from "../src/modes/flaglineTypes.js";

function baseMeta(): FlaglineMetaState {
  return {
    mode: "flaglineClash",
    currentRoomIndex: 0,
    roomsWon: { solar: 0, lunar: 0 },
    roomHistory: [],
    capture: { solar: 0, lunar: 0, contested: false, controllingTeam: null },
    phase: "roomFight",
    winningTeam: null,
    roomWinner: null,
    roomWinReason: null,
    roomTimerFrames: 9999,
    transitionFramesRemaining: 0,
    introFramesRemaining: 0,
  };
}

function player(id: number, x: number, y: number, defeated = false): PlayerState {
  return {
    id,
    characterId: "ember",
    fighterName: "P",
    fighterSize: "medium",
    fighterColor: "red",
    elementEffect: "burn",
    burnFramesRemaining: 0,
    slowFramesRemaining: 0,
    slowMultiplierFp: 100,
    airDriftBonusFrames: 0,
    x,
    y,
    vx: 0,
    vy: 0,
    facing: 1,
    damage: 0,
    stocks: defeated ? 0 : 3,
    staminaHp: 0,
    maxStaminaHp: 100,
    score: 0,
    teamId: 0,
    actionState: defeated ? "defeated" : "idle",
    actionFrame: 0,
    hitstunFrames: 0,
    shieldHealth: 100,
    jumpsRemaining: 2,
    jumpsUsed: 0,
    jumpHoldFrames: 0,
    wasJumpHeld: false,
    onGround: true,
    invulnFrames: 0,
    coyoteFrames: 0,
    jumpBufferFrames: 0,
    fastFalling: false,
    currentMoveId: "none",
    hitVictimsThisMove: [],
    aura: createDefaultAuraState(),
  };
}

const teamSlots = [
  { playerId: 0, teamId: "solar" as const },
  { playerId: 1, teamId: "lunar" as const },
  { playerId: 2, teamId: "solar" as const },
  { playerId: 3, teamId: "lunar" as const },
];

describe("flagline objective", () => {
  const room = getFlaglineRoom(0);
  const core = room.flagCore;

  it("Solar alone fills Solar meter", () => {
    const players = [
      player(0, core.x, core.y),
      player(1, 0, FLOOR_Y),
      player(2, 0, FLOOR_Y),
      player(3, 0, FLOOR_Y),
    ];
    let meta = baseMeta();
    for (let i = 0; i < 60; i++) {
      meta = updateFlagCoreCapture(meta, players, teamSlots, room, FLAGLINE_DEFAULTS, 1);
    }
    assert.ok(meta.capture.solar > 0);
    assert.equal(meta.capture.lunar, 0);
  });

  it("Both teams in zone contests", () => {
    const players = [
      player(0, core.x, core.y),
      player(1, core.x, core.y),
      player(2, 0, FLOOR_Y),
      player(3, 0, FLOOR_Y),
    ];
    const meta = updateFlagCoreCapture(baseMeta(), players, teamSlots, room, FLAGLINE_DEFAULTS, 60);
    assert.equal(meta.capture.contested, true);
  });

  it("No teams in zone decays", () => {
    let meta = baseMeta();
    meta.capture = { solar: 50, lunar: 50, contested: false, controllingTeam: null };
    const players = [
      player(0, 0, FLOOR_Y),
      player(1, 0, FLOOR_Y),
      player(2, 0, FLOOR_Y),
      player(3, 0, FLOOR_Y),
    ];
    meta = updateFlagCoreCapture(meta, players, teamSlots, room, FLAGLINE_DEFAULTS, 60);
    assert.ok(meta.capture.solar < 50);
    assert.ok(meta.capture.lunar < 50);
  });

  it("KO'd players do not count", () => {
    const players = [
      player(0, core.x, core.y, true),
      player(1, 0, FLOOR_Y),
      player(2, 0, FLOOR_Y),
      player(3, 0, FLOOR_Y),
    ];
    const counts = countTeamsInCore(players, teamSlots, room);
    assert.equal(counts.solar, 0);
  });

  it("Capture reaching 100 wins room", () => {
    const meta = { ...baseMeta(), capture: { ...baseMeta().capture, solar: 100 } };
    assert.equal(checkCaptureWin(meta, FLAGLINE_DEFAULTS), "solar");
  });
});
