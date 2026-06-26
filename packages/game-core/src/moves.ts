import type { PlayerActionState } from "./types.js";
import {
  DODGE_MOVE,
  NEUTRAL_ATTACK,
  SPECIAL_ATTACK,
  FORWARD_ATTACK,
  UP_ATTACK,
  DOWN_ATTACK,
  AERIAL_ATTACK,
  SIDE_SPECIAL,
  type MoveFrameData,
  totalMoveFrames,
} from "./frameData.js";

export type MoveId =
  | "neutral_attack"
  | "forward_attack"
  | "up_attack"
  | "down_attack"
  | "aerial_attack"
  | "special_attack"
  | "side_special"
  | "dodge"
  | "none";

export function actionToMoveId(state: PlayerActionState): MoveId {
  switch (state) {
    case "attacking":
      return "neutral_attack";
    case "special":
      return "special_attack";
    case "dodging":
      return "dodge";
    default:
      return "none";
  }
}

export function getMoveData(moveId: MoveId): MoveFrameData | null {
  switch (moveId) {
    case "neutral_attack":
      return NEUTRAL_ATTACK;
    case "forward_attack":
      return FORWARD_ATTACK;
    case "up_attack":
      return UP_ATTACK;
    case "down_attack":
      return DOWN_ATTACK;
    case "aerial_attack":
      return AERIAL_ATTACK;
    case "special_attack":
      return SPECIAL_ATTACK;
    case "side_special":
      return SIDE_SPECIAL;
    case "dodge":
      return DODGE_MOVE;
    default:
      return null;
  }
}

export function getMoveDataForAction(state: PlayerActionState): MoveFrameData | null {
  return getMoveData(actionToMoveId(state));
}

export function isMoveComplete(data: MoveFrameData, actionFrame: number): boolean {
  return actionFrame > totalMoveFrames(data);
}
