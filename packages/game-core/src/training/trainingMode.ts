import type { GameState, PlayerState } from "../types.js";
import { getStage } from "../stages.js";
import { getStageLayout } from "../stageLayouts.js";
import { resetCombatFields } from "../combat/combatState.js";
import { resetMovementFields } from "../movement/movementTypes.js";
import { SHIELD_MAX } from "../constants.js";
import { getCharacterForPlayer } from "../characters.js";
import type { VersusCpuConfig } from "../bots/versusCpu.js";

export type TrainingDummyBehavior = "idle" | "shield" | "jump" | "cpu1";

export type TrainingConfig = {
  dummyPlayerId: number;
  dummyBehavior: TrainingDummyBehavior;
  cpu?: VersusCpuConfig;
};

export function resetTrainingDamage(state: GameState): void {
  for (const p of state.players) {
    p.damage = 0;
    p.staminaHp = p.maxStaminaHp;
    p.hitstunFrames = 0;
    p.shieldStunFrames = 0;
    p.shieldHealth = SHIELD_MAX;
    p.actionState = "idle";
    p.actionFrame = 0;
    resetCombatFields(p);
  }
  state.hitstopFrames = 0;
}

export function resetTrainingPositions(state: GameState): void {
  const stage = getStage(state.config.stageId);
  const layout = getStageLayout(stage.layoutId ?? stage.id);
  for (let i = 0; i < state.players.length; i++) {
    const spawn = stage.spawnPoints[i] ?? stage.spawnPoints[0];
    const p = state.players[i];
    if (!p) continue;
    p.x = spawn.x;
    p.y = spawn.y;
    p.vx = 0;
    p.vy = 0;
    p.onGround = true;
    p.currentPlatformId = layout.mainPlatformId;
    resetMovementFields(p);
    const char = getCharacterForPlayer(p);
    p.jumpsRemaining = char.maxJumps;
    p.jumpsUsed = 0;
  }
}

export function applyTrainingDummyBehavior(
  dummy: PlayerState,
  behavior: TrainingDummyBehavior,
  frame: number,
): Partial<import("../types.js").InputFrame> {
  switch (behavior) {
    case "shield":
      return { shield: true };
    case "jump":
      return { jump: frame % 90 < 12 };
    case "idle":
    default:
      return {};
  }
}

export function getFighterMoveList(fighterId: string): { id: string; label: string; category: string }[] {
  const moves = [
    { id: "neutral_attack", label: "Jab", category: "ground" },
    { id: "forward_attack", label: "Forward Tilt", category: "ground" },
    { id: "up_attack", label: "Up Tilt", category: "ground" },
    { id: "down_attack", label: "Down Tilt", category: "ground" },
    { id: "dash_attack", label: "Dash Attack", category: "ground" },
    { id: "neutral_air", label: "Neutral Air", category: "air" },
    { id: "forward_air", label: "Forward Air", category: "air" },
    { id: "back_air", label: "Back Air", category: "air" },
    { id: "up_air", label: "Up Air", category: "air" },
    { id: "down_air", label: "Down Air", category: "air" },
    { id: "special_attack", label: "Neutral Special", category: "special" },
    { id: "side_special", label: "Side Special", category: "special" },
    { id: "up_special", label: "Up Special", category: "special" },
    { id: "down_special", label: "Down Special", category: "special" },
    { id: "grab", label: "Grab", category: "grab" },
  ];
  const profile = fighterId;
  void profile;
  return moves;
}
