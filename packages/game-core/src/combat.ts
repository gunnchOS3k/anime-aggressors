import type { GameState, InputFrame, PlayerState } from "./types.js";
import {
  GRAVITY,
  BLAST_BOTTOM,
  BLAST_LEFT,
  BLAST_RIGHT,
  BLAST_TOP,
  FP_SCALE,
  HITSTUN_BASE,
  SHIELD_MAX,
  STAGE_WIDTH,
} from "./constants.js";
import { getStage } from "./stages.js";
import { getStageLayout } from "./stageLayouts.js";
import { resolveStageCollision, tickDropThrough } from "./stageCollision.js";
import { resetPlayerAfterRespawn } from "./combat/playerLifecycle.js";
import { elementGameplayEnabled } from "./rulesets.js";
import { resolveCombatHits, processBlastZoneKOs } from "./combat/hitResolution.js";
import { NEUTRAL_ATTACK, SPECIAL_ATTACK } from "./frameData.js";
import { getMoveData, isMoveComplete, type MoveId } from "./moves.js";
import { getCombatMoveData } from "./moves/combatMoveData.js";
import { combatMoveToFrameData } from "./moves/combatMoveData.js";
import { maybeSpawnSuperEnergyAttack } from "./combat/energyClash.js";
import { maybeSpawnFighterProjectile, resolveProjectileHits } from "./combat/fighterProjectiles.js";
import { getMoveById, getFighterMove, fighterIdFromCharacterId } from "./moves/moveDefinitions.js";
import {
  applyAuraHitPenalty,
  canStartAuraCharge,
  isAuraChargeHeld,
  releaseAuraCharge,
  startAuraCharge,
  tickAuraDecay,
  tickAuraWhileCharging,
} from "./aura/auraCharge.js";
import {
  resetJumpStateOnLand,
  tickCoyoteTime,
} from "./movement/jumpSystem.js";
import {
  afterMovementPhysics,
  applyFastFallCap,
  processMovementInput,
  tickMovementTimers,
  tickJumpSquatPhase,
} from "./movement/movementController.js";
import { applyLandingLag, isMovementLocked } from "./movement/landingLag.js";
import { tickLedgeHang } from "./movement/ledgeSystem.js";
import { selectCombatAction } from "./combat/moveSelection.js";
import { canStartCombatAction } from "./combat/combatState.js";
import {
  releaseShield,
  tickShieldRegen,
  tickShieldRelease,
  tickShieldStun,
} from "./combat/shieldSystem.js";
import { tryGrabConnect, tickGrabState, executeThrow } from "./combat/grabSystem.js";
import {
  startDodgeAction,
  tickDodgeCooldown,
  tickDodgeAction,
  canDodge,
} from "./combat/dodgeSystem.js";
import { applyDirectionalInfluence } from "./combat/di.js";
import { classifyHitStrength } from "./combat/combatTuning.js";
import { scaledHitDamage, scaledKnockbackTaken } from "./fighterCreation.js";
import { applyElementOnHit, tickElementalEffects } from "./elements.js";
import { scaleKnockback } from "./feel.js";

function getDamageRatio(state: GameState): number {
  return state.config.ruleset?.damageRatio ?? 1;
}

function getLaunchRatio(state: GameState): number {
  return state.config.ruleset?.launchRatio ?? 1;
}

function clearMoveHitRegistry(player: PlayerState): void {
  player.hitVictimsThisMove = [];
  player.multiHitContacts = [];
}

function startCombatAction(player: PlayerState, input: InputFrame): void {
  if (!canStartCombatAction(player)) return;
  if (player.actionState === "auraCharging") return;
  if (!player.onGround && input.special && player.recoveryUsed) return;

  if (isAuraChargeHeld(input) && canStartAuraCharge(player) && !input.jump) {
    startAuraCharge(player);
    return;
  }

  const selected = selectCombatAction(player, input);
  if (!selected) return;

  if (selected.actionState === "shielding") {
    player.actionState = "shielding";
    player.actionFrame = 0;
    player.currentMoveId = "shield";
    player.vx = 0;
    return;
  }

  if (selected.actionState === "dodging" || selected.actionState === "rolling" || selected.actionState === "airDodging") {
    if (!canDodge(player)) return;
    clearMoveHitRegistry(player);
    startDodgeAction(player, selected.moveId, input);
    return;
  }

  if (selected.actionState === "grabbing") {
    clearMoveHitRegistry(player);
    player.actionState = "grabbing";
    player.actionFrame = 0;
    player.currentMoveId = selected.moveId;
    player.grabFrames = 0;
    return;
  }

  if (selected.actionState === "throwing") {
    return;
  }

  clearMoveHitRegistry(player);
  player.actionState = selected.actionState;
  player.actionFrame = 0;
  player.currentMoveId = selected.moveId;
}

function integratePhysics(player: PlayerState, stage: GameState["stage"], stageId: string): void {
  const wasOnGround = player.onGround;
  const wasFastFalling = player.fastFalling;
  const previousY = player.y;

  if (player.movementState === "ledgeHang" || player.movementState === "ledgeGetup") {
    tickCoyoteTime(player, wasOnGround);
    return;
  }

  if (player.movementState === "jumpSquat") {
    return;
  }

  player.x += player.vx;
  player.y += player.vy;

  const layout = getStageLayout(getStage(stageId).layoutId ?? stageId);
  const collision = resolveStageCollision(player, layout, stage.floorY, previousY);

  if (player.actionState !== "shielding") {
    player.vy += GRAVITY;
    const maxFall = applyFastFallCap(player);
    if (player.vy > maxFall) player.vy = maxFall;
  }

  if (collision.landed) {
    const wasAirborne = !wasOnGround;
    player.onGround = true;
    player.currentPlatformId = collision.platformId;
    player.fastFalling = false;
    if (wasAirborne) {
      resetJumpStateOnLand(player);
      applyLandingLag(player, wasFastFalling);
      player.recoveryUsed = false;
    }
    if (player.actionState === "jumping" || player.actionState === "falling" || player.actionState === "airDodging") {
      if (player.landingLagFrames === 0) {
        player.actionState = "idle";
        player.currentMoveId = "none";
      }
    }
  } else {
    player.onGround = false;
    player.currentPlatformId = "";
    if (player.actionState === "idle" || player.actionState === "running") {
      player.actionState = "falling";
    }
  }

  tickCoyoteTime(player, wasOnGround);
  afterMovementPhysics(player, layout, wasOnGround, wasFastFalling);
}

function tickActionState(state: GameState, player: PlayerState): void {
  player.actionFrame += 1;

  tickDodgeCooldown(player);
  tickShieldRegen(player);
  tickShieldRelease(player);
  tickShieldStun(player);

  if (player.invulnFrames > 0) player.invulnFrames -= 1;

  if (player.actionState === "hitstun") {
    player.hitstunFrames -= 1;
    if (player.hitstunFrames <= 0) {
      player.actionState = "idle";
      player.currentMoveId = "none";
    }
    return;
  }

  if (player.actionState === "throwing") {
    const move = getCombatMoveData(player.currentMoveId);
    if (move && player.actionFrame === move.startup) {
      const target = state.players.find((p) => p.id === player.grabTargetId);
      if (target) executeThrow(state, player, target, player.currentMoveId);
    }
    if (move && player.actionFrame > move.startup + move.active + move.recovery) {
      player.actionState = "idle";
      player.currentMoveId = "none";
    }
    return;
  }

  if (player.actionState === "grabbing") {
    const target = state.players.find((p) => p.id === player.grabTargetId);
    tickGrabState(player, target);
    const grab = getCombatMoveData("grab");
    if (grab && isMoveComplete(combatMoveToFrameData(grab), player.actionFrame) && player.grabTargetId < 0) {
      player.actionState = "idle";
      player.currentMoveId = "none";
    }
    return;
  }

  if (player.actionState === "attacking" || player.actionState === "special") {
    const move = getCombatMoveData(player.currentMoveId);
    const fighterMove = getMoveById(player.currentMoveId);
    if (fighterMove) {
      maybeSpawnSuperEnergyAttack(state, player.id, fighterMove.fighterId, fighterMove, player.actionFrame);
    }
    maybeSpawnFighterProjectile(state, player, player.currentMoveId, player.actionFrame);
    if (move && isMoveComplete(combatMoveToFrameData(move), player.actionFrame)) {
      player.actionState = "idle";
      player.currentMoveId = "none";
      clearMoveHitRegistry(player);
    }
  }

  tickDodgeAction(player);

  if (player.actionState === "shielding") {
    player.shieldHealth = Math.max(0, player.shieldHealth - 0.02);
  }

  if (player.actionState === "auraCharging") {
    player.shieldHealth = Math.max(SHIELD_MAX * 0.4, player.shieldHealth - 0.5);
  }
}

function applyHitstunDI(player: PlayerState, input: InputFrame | undefined): void {
  if (player.actionState !== "hitstun" || !input) return;
  const strength = classifyHitStrength(player.damage, player.currentMoveId);
  const adjusted = applyDirectionalInfluence(player.vx, player.vy, input, strength);
  player.vx = adjusted.vx;
  player.vy = adjusted.vy;
}

export function resolveCombat(state: GameState, inputs?: InputFrame[]): void {
  for (const player of state.players) {
    if (player.actionState === "grabbing") {
      tryGrabConnect(state, player);
    }
  }
  state.lastHitEvents = resolveCombatHits(state, inputs);
  resolveProjectileHits(state, inputs);
  processBlastZoneKOs(state);
}

export function processPlayer(state: GameState, player: PlayerState, input: InputFrame | undefined): void {
  if (player.actionState === "defeated") return;

  tickDropThrough(player);
  tickMovementTimers(player);
  tickAuraDecay(player);

  const stageDef = getStage(state.config.stageId);
  const layout = getStageLayout(stageDef.layoutId ?? stageDef.id);

  if (input) {
    applyHitstunDI(player, input);

    if (player.actionState === "shielding" && !input.shield) {
      releaseShield(player);
    }

    if (player.actionState === "grabbing" && player.grabTargetId >= 0) {
      const throwAction = selectCombatAction(player, input);
      if (throwAction?.actionState === "throwing") {
        player.actionState = "throwing";
        player.actionFrame = 0;
        player.currentMoveId = throwAction.moveId;
      }
    }

    if (player.movementState === "ledgeHang") {
      tickLedgeHang(player, layout, input);
    } else {
      tickJumpSquatPhase(player, !!input.jump);
      const canMove =
        !isMovementLocked(player) ||
        player.movementState === "jumpSquat" ||
        player.actionState === "hitstun";
      if (canMove && player.actionState !== "grabbed") {
        processMovementInput(player, input, layout, STAGE_WIDTH / 2);
      } else {
        player.wasJumpHeld = !!input.jump;
      }
    }

    if (player.actionState === "auraCharging") {
      if (!tickAuraWhileCharging(player, input)) {
        const fighterId = fighterIdFromCharacterId(player.characterId);
        if (releaseAuraCharge(player) === "super") {
          const fighterMove = getFighterMove(fighterId, "super");
          player.currentMoveId = fighterMove?.id ?? "super";
        }
      }
    } else if (
      player.actionState !== "grabbed" &&
      !isMovementLocked(player) &&
      player.movementState !== "recoveryFall"
    ) {
      startCombatAction(player, input);
    }
  } else {
    if (player.jumpBufferFrames > 0) player.jumpBufferFrames -= 1;
    if (player.movementState === "ledgeHang") {
      tickLedgeHang(player, layout, undefined);
    }
  }

  tickActionState(state, player);
  tickElementalEffects(player);
  integratePhysics(player, state.stage, state.config.stageId);
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
      defender.actionState = "shieldBreak";
      defender.shieldStunFrames = HITSTUN_BASE * 2;
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
  stageId?: string,
): void {
  resetPlayerAfterRespawn(player, spawn, ruleset);
  if (stageId) {
    const layout = getStageLayout(getStage(stageId).layoutId ?? stageId);
    player.currentPlatformId = layout.mainPlatformId;
  }
}

export { applyHit, checkBlastZones, respawnPlayer };
