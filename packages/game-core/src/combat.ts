import type { GameState, InputFrame, PlayerState } from "./types.js";
import {
  GRAVITY,
  BLAST_BOTTOM,
  BLAST_LEFT,
  BLAST_RIGHT,
  BLAST_TOP,
  DODGE_FRAMES,
  HITSTUN_BASE,
  MAX_FALL_SPEED,
  SHIELD_MAX,
  FP_SCALE,
} from "./constants.js";
import { getCharacter, getCharacterForPlayer } from "./characters.js";
import { getStage } from "./stages.js";
import { getStageLayout } from "./stageLayouts.js";
import { resolvePlatformLanding } from "./stageCollision.js";
import { elementGameplayEnabled } from "./rulesets.js";
import { resolveCombatHits, processBlastZoneKOs } from "./combat/hitResolution.js";
import { DODGE_MOVE, NEUTRAL_ATTACK, SPECIAL_ATTACK } from "./frameData.js";
import { getMoveData, isMoveComplete, type MoveId } from "./moves.js";
import {
  fighterIdFromCharacterId,
  getFighterMove,
  getFrameDataForMoveId,
  getMoveById,
  resolveMoveSlotFromInput,
} from "./moves/moveDefinitions.js";
import { maybeSpawnSuperEnergyAttack } from "./combat/energyClash.js";
import {
  applyAuraHitPenalty,
  canStartAuraCharge,
  consumeAuraOnSuper,
  isAuraChargeHeld,
  releaseAuraCharge,
  startAuraCharge,
  tickAuraDecay,
  tickAuraWhileCharging,
} from "./aura/auraCharge.js";
import { createDefaultAuraState } from "./aura/auraTypes.js";
import {
  bufferJumpInput,
  fastFallSpeed,
  resetJumpStateOnLand,
  tickCoyoteTime,
  tickJumpHold,
  tryJump,
} from "./movement/jumpSystem.js";
import { applyDash, applyHorizontalMovement } from "./movement/applyMovement.js";
import {
  scaledHitDamage,
  scaledKnockbackTaken,
} from "./fighterCreation.js";
import { applyElementOnHit, tickElementalEffects } from "./elements.js";
import { scaleKnockback } from "./feel.js";

function getDamageRatio(state: GameState): number {
  return state.config.ruleset?.damageRatio ?? 1;
}

function getLaunchRatio(state: GameState): number {
  return state.config.ruleset?.launchRatio ?? 1;
}

function applyInputMovement(player: PlayerState, input: InputFrame): void {
  applyHorizontalMovement(player, input);
}

function clearMoveHitRegistry(player: PlayerState): void {
  player.hitVictimsThisMove = [];
}

function startAction(player: PlayerState, input: InputFrame): void {
  if (player.actionState === "hitstun" || player.actionState === "defeated") return;
  if (player.actionState === "auraCharging") return;
  if (player.actionState === "dodging") return;
  if (
    (player.actionState === "attacking" || player.actionState === "special") &&
    player.actionFrame > 0
  ) {
    const data = getPlayerMoveFrameData(player);
    if (data && !isMoveComplete(data, player.actionFrame)) return;
  }

  if (input.dodge && player.onGround) {
    player.actionState = "dodging";
    player.actionFrame = 0;
    player.currentMoveId = "dodge";
    applyDash(player);
    player.invulnFrames = DODGE_MOVE.startup + DODGE_MOVE.active;
    return;
  }

  if (isAuraChargeHeld(input) && canStartAuraCharge(player) && !input.jump) {
    startAuraCharge(player);
    return;
  }

  if (input.shield && !input.jump) {
    player.actionState = "shielding";
    player.actionFrame = 0;
    player.vx = 0;
    return;
  }

  if (input.special) {
    clearMoveHitRegistry(player);
    player.actionState = "special";
    player.actionFrame = 0;
    const fighterId = fighterIdFromCharacterId(player.characterId);
    const slot = resolveMoveSlotFromInput(player, input);
    const fighterMove = slot ? getFighterMove(fighterId, slot) : undefined;
    if (fighterMove) {
      player.currentMoveId = fighterMove.id;
    } else {
      player.currentMoveId = input.left || input.right ? "side_special" : "special_attack";
    }
    return;
  }

  if (input.attack) {
    clearMoveHitRegistry(player);
    player.actionState = "attacking";
    player.actionFrame = 0;
    const fighterId = fighterIdFromCharacterId(player.characterId);
    const slot = resolveMoveSlotFromInput(player, input);
    const fighterMove = slot ? getFighterMove(fighterId, slot) : undefined;
    if (fighterMove) {
      player.currentMoveId = fighterMove.id;
      return;
    }
    if (!player.onGround) {
      player.currentMoveId = "aerial_attack";
    } else if (input.up) {
      player.currentMoveId = "up_attack";
    } else if (input.down) {
      player.currentMoveId = "down_attack";
    } else if (input.left || input.right) {
      player.currentMoveId = "forward_attack";
    } else {
      player.currentMoveId = "neutral_attack";
    }
    return;
  }
}

function integratePhysics(player: PlayerState, stage: GameState["stage"], stageId: string): void {
  const wasOnGround = player.onGround;
  const previousY = player.y;

  if (player.actionState !== "shielding") {
    player.vy += GRAVITY;
    let maxFall = MAX_FALL_SPEED;
    if (player.fastFalling && !player.onGround) {
      maxFall = fastFallSpeed(MAX_FALL_SPEED, player);
    }
    if (player.vy > maxFall) player.vy = maxFall;
  }

  player.x += player.vx;
  player.y += player.vy;

  const layout = getStageLayout(stageId);
  const landedOnPlatform = resolvePlatformLanding(player, layout, previousY);

  if (landedOnPlatform) {
    const wasAirborne = !wasOnGround;
    player.onGround = true;
    player.fastFalling = false;
    if (wasAirborne) {
      resetJumpStateOnLand(player);
    }
    if (player.actionState === "jumping" || player.actionState === "falling") {
      player.actionState = "idle";
    }
  } else if (player.y >= stage.floorY) {
    player.y = stage.floorY;
    player.vy = 0;
    const wasAirborne = !wasOnGround;
    player.onGround = true;
    player.fastFalling = false;
    if (wasAirborne) {
      resetJumpStateOnLand(player);
    }
    if (player.actionState === "jumping" || player.actionState === "falling") {
      player.actionState = "idle";
    }
  } else {
    player.onGround = false;
    if (player.actionState === "idle" || player.actionState === "running") {
      player.actionState = "falling";
    }
  }

  tickCoyoteTime(player, wasOnGround);

  // Horizontal blast zones are not hard-clamped — crossing triggers stock loss in resolveCombat.
}

function getPlayerMoveFrameData(player: PlayerState): import("./frameData.js").MoveFrameData | null {
  const fighterData = getFrameDataForMoveId(player.currentMoveId);
  if (fighterData) return fighterData;
  return getMoveData(player.currentMoveId as MoveId);
}

function tickActionState(state: GameState, player: PlayerState): void {
  player.actionFrame += 1;

  if (player.invulnFrames > 0) player.invulnFrames -= 1;

  if (player.actionState === "hitstun") {
    player.hitstunFrames -= 1;
    if (player.hitstunFrames <= 0) {
      player.actionState = "idle";
      player.currentMoveId = "none";
    }
    return;
  }

  if (player.actionState === "attacking" || player.actionState === "special") {
    const data = getPlayerMoveFrameData(player);
    const fighterMove = getMoveById(player.currentMoveId);
    if (fighterMove) {
      maybeSpawnSuperEnergyAttack(state, player.id, fighterMove.fighterId, fighterMove, player.actionFrame);
    }
    if (data && isMoveComplete(data, player.actionFrame)) {
      player.actionState = "idle";
      player.currentMoveId = "none";
      player.hitVictimsThisMove = [];
    }
  }
  if (player.actionState === "dodging" && isMoveComplete(DODGE_MOVE, player.actionFrame)) {
    player.actionState = "idle";
    player.currentMoveId = "none";
    player.hitVictimsThisMove = [];
  }
  if (player.actionState === "shielding") {
    player.shieldHealth = Math.max(0, player.shieldHealth - 1);
    if (player.shieldHealth <= 0) {
      player.actionState = "hitstun";
      player.hitstunFrames = HITSTUN_BASE * 2;
    }
  }
  if (player.actionState === "auraCharging") {
    player.shieldHealth = Math.max(SHIELD_MAX * 0.4, player.shieldHealth - 0.5);
  }
}

function applyHit(
  state: GameState,
  attacker: PlayerState,
  defender: PlayerState,
  damage: number,
  kbX: number,
  kbY: number,
  hitstop: number,
): void {
  if (defender.invulnFrames > 0) return;

  if (defender.actionState === "shielding") {
    defender.shieldHealth -= damage;
    if (defender.shieldHealth <= 0) {
      defender.actionState = "hitstun";
      defender.hitstunFrames = HITSTUN_BASE * 2;
    }
    return;
  }

  const kb = scaleKnockback(
    defender.damage > 50 ? SPECIAL_ATTACK : NEUTRAL_ATTACK,
    defender.damage,
  );

  const moveData =
    attacker.actionState === "special"
      ? getMoveData(attacker.currentMoveId as MoveId) ?? SPECIAL_ATTACK
      : getMoveData(attacker.currentMoveId as MoveId) ?? NEUTRAL_ATTACK;

  const dmgRatio = getDamageRatio(state);
  const launchRatio = getLaunchRatio(state);
  const finalDamage = Math.max(1, Math.floor(scaledHitDamage(damage, attacker) * dmgRatio));
  const kbXScaled = Math.floor(
    scaledKnockbackTaken(kbX !== 0 ? kbX * FP_SCALE : kb.kbX, defender) * launchRatio,
  );
  const kbYScaled = Math.floor(
    scaledKnockbackTaken(kbY !== 0 ? kbY * FP_SCALE : kb.kbY, defender) * launchRatio,
  );

  if (state.config.ruleset?.matchType === "stamina") {
    defender.staminaHp = Math.max(0, defender.staminaHp - finalDamage);
  } else {
    defender.damage += finalDamage;
  }
  defender.vx += kbX !== 0 ? kbX * launchRatio : (kbXScaled * attacker.facing) / 10;
  defender.vy += kbY !== 0 ? kbY * launchRatio : kbYScaled / 10;
  defender.actionState = "hitstun";
  defender.hitstunFrames = HITSTUN_BASE + Math.floor((defender.damage || 0) / 10);
  defender.onGround = false;
  defender.currentMoveId = "none";
  applyAuraHitPenalty(defender, finalDamage >= 15);

  const elementMode = state.config.ruleset?.elementMode ?? "on";
  if (elementGameplayEnabled(elementMode)) {
    applyElementOnHit(attacker, defender, moveData, attacker.actionFrame);
  }

  if (hitstop > state.hitstopFrames) {
    state.hitstopFrames = hitstop;
  }
}

function checkBlastZones(player: PlayerState): boolean {
  return (
    player.x < BLAST_LEFT ||
    player.x > BLAST_RIGHT ||
    player.y < BLAST_TOP ||
    player.y > BLAST_BOTTOM
  );
}

function respawnPlayer(
  player: PlayerState,
  spawn: { x: number; y: number },
  ruleset?: import("./rulesets.js").GameRuleset,
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
  player.invulnFrames = 60;
  player.coyoteFrames = 0;
  player.jumpBufferFrames = 0;
  player.fastFalling = false;
  player.currentMoveId = "none";
  player.hitVictimsThisMove = [];
  player.burnFramesRemaining = 0;
  player.slowFramesRemaining = 0;
  player.slowMultiplierFp = 100;
  player.airDriftBonusFrames = 0;
  player.aura = createDefaultAuraState();
  player.jumpsUsed = 0;
  player.jumpHoldFrames = 0;
  player.wasJumpHeld = false;
  player.jumpsRemaining = getCharacterForPlayer(player).maxJumps;
  player.onGround = true;
}

export function resolveCombat(state: GameState): void {
  state.lastHitEvents = resolveCombatHits(state);
  processBlastZoneKOs(state);
}

export function processPlayer(state: GameState, player: PlayerState, input: InputFrame | undefined): void {
  if (player.actionState === "defeated") return;

  tickAuraDecay(player);

  if (input) {
    if (player.actionState === "shielding" && !input.shield) {
      player.actionState = "idle";
      player.shieldHealth = SHIELD_MAX;
    }

    const jumpJustPressed = input.jump && !player.wasJumpHeld;
    bufferJumpInput(player, input.jump);
    if (tryJump(player, input, jumpJustPressed)) {
      if (player.actionState === "auraCharging" || player.aura.charging) {
        player.aura.charging = false;
        player.currentMoveId = "none";
      }
    } else if (player.actionState === "auraCharging") {
      if (!tickAuraWhileCharging(player, input)) {
        const fighterId = fighterIdFromCharacterId(player.characterId);
        if (releaseAuraCharge(player) === "super") {
          const fighterMove = getFighterMove(fighterId, "super");
          player.currentMoveId = fighterMove?.id ?? "super";
        }
      }
    } else {
      startAction(player, input);
    }
    tickJumpHold(player, !!input.jump);
    applyInputMovement(player, input);
    if (!player.onGround && input.down) {
      player.fastFalling = true;
    }
  } else {
    if (player.jumpBufferFrames > 0) player.jumpBufferFrames -= 1;
  }

  tickActionState(state, player);
  tickElementalEffects(player);
  integratePhysics(player, state.stage, state.config.stageId);
}

export { applyHit, checkBlastZones, respawnPlayer };
