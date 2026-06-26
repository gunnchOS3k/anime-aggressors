import type { InputFrame } from "../types.js";
import type { FlaglineClashState, TeamId } from "../modes/flaglineTypes.js";
import { getFlaglineRoom } from "../modes/flaglineMaps.js";
import { FP_SCALE } from "../constants.js";

export function emptyBotInput(frame: number, playerId: number): InputFrame {
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
  };
}

export function generateFlaglineBotInput(
  state: FlaglineClashState,
  playerId: number,
  frame: number,
): InputFrame {
  const slot = state.teamSlots.find((s) => s.playerId === playerId);
  if (!slot?.isBot) return emptyBotInput(frame, playerId);

  const player = state.game.players[playerId];
  if (!player || player.actionState === "defeated") return emptyBotInput(frame, playerId);

  const room = getFlaglineRoom(state.flagline.currentRoomIndex);
  const coreX = room.flagCore.x;
  const coreY = room.flagCore.y;
  const dx = coreX - player.x;
  const dy = coreY - player.y;

  const input = emptyBotInput(frame, playerId);

  if (Math.abs(dx) > 40 * FP_SCALE) {
    if (dx < 0) input.left = true;
    else input.right = true;
  }

  if (player.y > coreY + 20 * FP_SCALE && player.onGround) {
    input.jump = true;
  }

  if (!player.onGround && player.y > room.flagCore.y + 80 * FP_SCALE) {
    input.up = true;
  }

  for (const other of state.game.players) {
    if (other.id === playerId || other.actionState === "defeated") continue;
    const odx = Math.abs(other.x - player.x);
    const ody = Math.abs(other.y - player.y);
    if (odx < 80 * FP_SCALE && ody < 60 * FP_SCALE) {
      input.attack = frame % 30 < 8;
      if (frame % 90 < 6) input.special = true;
    }
  }

  const stage = state.game.stage;
  if (player.x < stage.left + 100 * FP_SCALE) input.right = true;
  if (player.x > stage.right - 100 * FP_SCALE) input.left = true;

  return input;
}

export function generateAllBotInputs(state: FlaglineClashState, frame: number): InputFrame[] {
  return state.teamSlots
    .filter((s) => s.isBot)
    .map((s) => generateFlaglineBotInput(state, s.playerId, frame));
}

export function teamIdToNumeric(team: TeamId): number {
  return team === "solar" ? 0 : 1;
}
