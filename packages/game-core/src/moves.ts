import type { PlayerActionState } from "./types.js";
import {
  DODGE_MOVE,
  NEUTRAL_ATTACK,
  SPECIAL_ATTACK,
  type MoveFrameData,
  totalMoveFrames,
} from "./frameData.js";

export type MoveId = "neutral_attack" | "special_attack" | "dodge" | "none";

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
    case "special_attack":
      return SPECIAL_ATTACK;
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
