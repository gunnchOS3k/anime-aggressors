import type { InputFrame, PlayerState } from "../types.js";
import { isMovementLocked } from "../movement/landingLag.js";
import { canStartCombatAction } from "./combatState.js";

export type SelectedCombatAction = {
  moveId: string;
  actionState: import("../types.js").PlayerActionState;
};

function isDashAttacking(player: PlayerState): boolean {
  return (
    player.onGround &&
    (player.movementState === "run" ||
      player.movementState === "dashStart" ||
      player.movementState === "walk")
  );
}

function airDirectionSlot(
  input: Pick<InputFrame, "left" | "right" | "up" | "down">,
  facing: 1 | -1,
): "neutralAir" | "forwardAir" | "backAir" | "upAir" | "downAir" {
  if (input.up) return "upAir";
  if (input.down) return "downAir";
  if (input.left || input.right) {
    const inputForward =
      (input.right && facing > 0) || (input.left && facing < 0);
    return inputForward ? "forwardAir" : "backAir";
  }
  return "neutralAir";
}

const AIR_SLOT_TO_ID: Record<string, string> = {
  neutralAir: "neutral_air",
  forwardAir: "forward_air",
  backAir: "back_air",
  upAir: "up_air",
  downAir: "down_air",
};

/** Deterministic move selection from InputFrame + PlayerState (Milestone 3). */
export function selectCombatAction(
  player: PlayerState,
  input: InputFrame,
): SelectedCombatAction | null {
  if (player.actionState === "defeated") return null;
  if (player.actionState === "hitstun") return null;
  if (player.shieldStunFrames > 0) return null;
  if (player.actionState === "shieldBreak") return null;
  if (player.actionState === "grabbed") return null;
  if (isMovementLocked(player)) return null;

  if (player.actionState === "grabbing" && player.grabTargetId >= 0) {
    return selectThrowAction(player, input);
  }

  if (!canStartCombatAction(player)) return null;

  if (input.grab && player.onGround && player.hitstunFrames <= 0) {
    return { moveId: "grab", actionState: "grabbing" };
  }

  if (input.shield && !input.jump && !(input.special)) {
    return { moveId: "shield", actionState: "shielding" };
  }

  if (input.dodge) {
    if (!player.onGround) {
      return { moveId: "air_dodge", actionState: "airDodging" };
    }
    if (input.left || input.right) {
      return { moveId: "roll", actionState: "rolling" };
    }
    return { moveId: "spot_dodge", actionState: "dodging" };
  }

  if (input.special) {
    if (input.up) return { moveId: "up_special", actionState: "special" };
    if (input.down) return { moveId: "down_special", actionState: "special" };
    if (input.left || input.right) return { moveId: "side_special", actionState: "special" };
    return { moveId: "special_attack", actionState: "special" };
  }

  if (input.attack) {
    if (!player.onGround) {
      const slot = airDirectionSlot(input, player.facing);
      return { moveId: AIR_SLOT_TO_ID[slot], actionState: "attacking" };
    }
    if (isDashAttacking(player) && !input.up && !input.down) {
      return { moveId: "dash_attack", actionState: "attacking" };
    }
    if (input.up) return { moveId: "up_attack", actionState: "attacking" };
    if (input.down) return { moveId: "down_attack", actionState: "attacking" };
    if (input.left || input.right) return { moveId: "forward_attack", actionState: "attacking" };
    return { moveId: "neutral_attack", actionState: "attacking" };
  }

  return null;
}

function selectThrowAction(
  player: PlayerState,
  input: InputFrame,
): SelectedCombatAction | null {
  if (input.up) return { moveId: "throw_up", actionState: "throwing" };
  if (input.down) return { moveId: "throw_down", actionState: "throwing" };
  const forward =
    (input.right && player.facing > 0) || (input.left && player.facing < 0);
  const backward =
    (input.left && player.facing > 0) || (input.right && player.facing < 0);
  if (forward) return { moveId: "throw_forward", actionState: "throwing" };
  if (backward) return { moveId: "throw_back", actionState: "throwing" };
  if (input.attack) return { moveId: "throw_forward", actionState: "throwing" };
  return null;
}
