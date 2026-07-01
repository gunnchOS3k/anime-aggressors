import type { PlayerState } from "../types.js";
import type { GameRuleset } from "../rulesets.js";
import { SHIELD_MAX } from "../constants.js";
import { getCharacterForPlayer } from "../characters.js";
import { createDefaultAuraState } from "../aura/auraTypes.js";
import { resetMovementFields } from "../movement/movementTypes.js";

export const RESPAWN_INVULN_FRAMES = 60;

/** Full combat/movement reset after blast-zone respawn or stock loss recovery. */
export function resetPlayerAfterRespawn(
  player: PlayerState,
  spawn: { x: number; y: number },
  ruleset?: GameRuleset,
): void {
  player.x = spawn.x;
  player.y = spawn.y;
  player.vx = 0;
  player.vy = 0;
  player.damage = 0;
  if (ruleset?.matchType === "stamina") {
    player.staminaHp = ruleset.staminaHp;
  }
  player.actionState = "idle";
  player.actionFrame = 0;
  player.hitstunFrames = 0;
  player.invulnFrames = RESPAWN_INVULN_FRAMES;
  player.coyoteFrames = 0;
  player.jumpBufferFrames = 0;
  player.fastFalling = false;
  player.currentMoveId = "none";
  player.hitVictimsThisMove = [];
  player.dropThroughFrames = 0;
  player.ignoredPlatformId = "";
  player.currentPlatformId = "";
  player.burnFramesRemaining = 0;
  player.slowFramesRemaining = 0;
  player.slowMultiplierFp = 100;
  player.airDriftBonusFrames = 0;
  player.aura = createDefaultAuraState();
  const char = getCharacterForPlayer(player);
  player.jumpsRemaining = char.maxJumps;
  player.jumpsUsed = 0;
  player.jumpHoldFrames = 0;
  player.wasJumpHeld = false;
  player.shieldHealth = SHIELD_MAX;
  player.onGround = true;
  resetMovementFields(player);
}
