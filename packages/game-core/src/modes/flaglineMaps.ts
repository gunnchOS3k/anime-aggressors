import { FLOOR_Y, FP_SCALE } from "../constants.js";
import type { FlaglineRoom, FlaglineRoomIndex } from "./flaglineTypes.js";

const CORE_W = 120 * FP_SCALE;
const CORE_H = 80 * FP_SCALE;
const CENTER_X = 1200 * FP_SCALE;
const CORE_Y = FLOOR_Y - 120 * FP_SCALE;

function room(
  index: FlaglineRoomIndex,
  id: string,
  name: string,
  stageId: string,
  solarX: number,
  lunarX: number,
): FlaglineRoom {
  return {
    index,
    id,
    name,
    stageId,
    flagCore: { x: CENTER_X, y: CORE_Y, width: CORE_W, height: CORE_H },
    solarSpawn: [
      { x: solarX, y: FLOOR_Y - 64 * FP_SCALE },
      { x: solarX + 80 * FP_SCALE, y: FLOOR_Y - 64 * FP_SCALE },
    ],
    lunarSpawn: [
      { x: lunarX, y: FLOOR_Y - 64 * FP_SCALE },
      { x: lunarX - 80 * FP_SCALE, y: FLOOR_Y - 64 * FP_SCALE },
    ],
  };
}

export const FLAGLINE_ROOMS: Record<FlaglineRoomIndex, FlaglineRoom> = {
  [-2]: room(-2, "lunar-base", "Lunar Base", "flagline-lunar-base", 400 * FP_SCALE, 2000 * FP_SCALE),
  [-1]: room(-1, "lunar-outpost", "Lunar Outpost", "flagline-lunar-outpost", 600 * FP_SCALE, 1800 * FP_SCALE),
  [0]: room(0, "center-clash", "Center Clash", "flagline-center-clash", 800 * FP_SCALE, 1600 * FP_SCALE),
  [1]: room(1, "solar-outpost", "Solar Outpost", "flagline-solar-outpost", 600 * FP_SCALE, 1800 * FP_SCALE),
  [2]: room(2, "solar-base", "Solar Base", "flagline-solar-base", 400 * FP_SCALE, 2000 * FP_SCALE),
};

export const FLAGLINE_ROOM_ORDER: FlaglineRoomIndex[] = [-2, -1, 0, 1, 2];

export function getFlaglineRoom(index: FlaglineRoomIndex): FlaglineRoom {
  return FLAGLINE_ROOMS[index];
}

export function getRoomLabel(index: FlaglineRoomIndex): string {
  return FLAGLINE_ROOMS[index].name;
}
