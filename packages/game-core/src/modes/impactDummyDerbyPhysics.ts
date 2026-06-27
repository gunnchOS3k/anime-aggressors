import type { CreatedFighter } from "../createdFighter.js";
import type {
  DerbyInput,
  DerbyPlayerState,
  ImpactDummyDerbyState,
  ImpactDummyState,
  KineticBatState,
} from "./impactDummyDerbyTypes.js";
import { FP_SCALE, SIM_HZ } from "../constants.js";
import { getSizeStats } from "../sizeClasses.js";
import {
  GRAVITY,
  attackRecoveryFrames,
  barrierKnockbackDamping,
  batLaunchBonus,
  dummyVelocityScale,
  launchAngleModifiers,
  launchPowerScaleForFighter,
  onDerbyHit,
} from "./impactDummyDerbyElements.js";
import { launchAngleDeg } from "./impactDummyDerbyScoring.js";
import { pushDerbyEvent } from "./impactDummyDerbyEvents.js";

export const PLATFORM_Y = 900 * FP_SCALE;
export const PLATFORM_LEFT = 200 * FP_SCALE;
export const PLATFORM_RIGHT = 2200 * FP_SCALE;
export const RUN_SPEED = (7 * FP_SCALE) / SIM_HZ;
export const JUMP_V = -(14 * FP_SCALE) / SIM_HZ;
export const BARRIER_TOP = PLATFORM_Y - 180 * FP_SCALE;

export const BAT_STARTUP = 8;
export const BAT_ACTIVE = 5;
export const BAT_RECOVERY = 24;
export const BAT_SWEET_START = 2;
export const BAT_SWEET_END = 3;
export const BAT_BASE_LAUNCH = 32;
export const BAT_DAMAGE_SCALE = 0.32;
export const BAT_SWEET_MULT = 1.25;
export const BAT_WEAK_MULT = 0.85;

export const ATTACK_STARTUP = 6;
export const ATTACK_ACTIVE_START = 4;
export const ATTACK_ACTIVE_END = 8;

export function integratePlayer(player: DerbyPlayerState, fighter: CreatedFighter, input: DerbyInput): void {
  const sizeStats = getSizeStats(fighter.size);
  const runSpeed = Math.floor(RUN_SPEED * sizeStats.speedMultiplier);
  const jumpV = Math.floor(JUMP_V * sizeStats.jumpMultiplier);

  if (player.actionState === "attacking" && player.actionFrame > attackRecoveryFrames(fighter)) {
    player.actionState = "idle";
    player.actionFrame = 0;
  }
  if (player.actionState === "dodging" && player.actionFrame > 12) {
    player.actionState = "idle";
    player.actionFrame = 0;
  }
  if (player.actionState === "shielding" && !input.shield) {
    player.actionState = "idle";
    player.actionFrame = 0;
  }

  if (player.actionState === "idle" || player.actionState === "running" || player.actionState === "falling") {
    if (input.left) {
      player.vx = -runSpeed;
      player.facing = -1;
      if (player.onGround) player.actionState = "running";
    } else if (input.right) {
      player.vx = runSpeed;
      player.facing = 1;
      if (player.onGround) player.actionState = "running";
    } else if (player.onGround && player.actionState === "running") {
      player.vx = 0;
      player.actionState = "idle";
    }

    if (input.down && !player.onGround) {
      player.fastFalling = true;
    }

    if (input.jump) {
      if (player.onGround) {
        player.vy = jumpV;
        player.onGround = false;
        player.jumpsRemaining = 1;
        player.actionState = "jumping";
      } else if (player.jumpsRemaining > 0) {
        player.vy = Math.floor(jumpV * 0.92);
        player.jumpsRemaining = 0;
        player.actionState = "jumping";
      }
    }

    if (input.dodge && player.onGround) {
      player.actionState = "dodging";
      player.actionFrame = 0;
      player.vx = player.facing * runSpeed * 2;
    }

    if (input.shield && player.onGround) {
      player.actionState = "shielding";
      player.actionFrame = 0;
      player.vx = 0;
    }

    if (input.special && player.onGround) {
      player.actionState = "special";
      player.actionFrame = 0;
      player.vx = player.facing * Math.floor(runSpeed * 1.5);
    }
  }

  if (input.attack && player.actionState !== "attacking" && player.actionState !== "shielding") {
    player.actionState = "attacking";
    player.actionFrame = 0;
  }

  player.actionFrame += 1;
  const gravMult = player.fastFalling && player.vy > 0 ? 1.6 : 1;
  player.vy += Math.floor(GRAVITY * gravMult);
  player.x += player.vx;
  player.y += player.vy;

  if (player.y >= PLATFORM_Y - 64 * FP_SCALE) {
    player.y = PLATFORM_Y - 64 * FP_SCALE;
    player.vy = 0;
    player.onGround = true;
    player.fastFalling = false;
    player.jumpsRemaining = 1;
    if (player.actionState === "jumping" || player.actionState === "falling") {
      player.actionState = "idle";
    }
  } else {
    player.onGround = false;
    if (player.actionState === "idle" || player.actionState === "running") {
      player.actionState = "falling";
    }
  }

  if (player.x < PLATFORM_LEFT) player.x = PLATFORM_LEFT;
  if (player.x > PLATFORM_RIGHT) player.x = PLATFORM_RIGHT;
}

export function applyBarrier(state: ImpactDummyDerbyState): void {
  const d = state.dummy;
  const damp = barrierKnockbackDamping(state);

  if (d.y < BARRIER_TOP) {
    d.y = BARRIER_TOP;
    d.vy = Math.max(0, Math.floor(d.vy * damp));
  }

  if (d.x < PLATFORM_LEFT + 32 * FP_SCALE) {
    d.x = PLATFORM_LEFT + 32 * FP_SCALE;
    d.vx = Math.floor(d.vx * damp);
  }
  if (d.x > PLATFORM_RIGHT - 32 * FP_SCALE) {
    d.x = PLATFORM_RIGHT - 32 * FP_SCALE;
    d.vx = Math.floor(d.vx * damp);
  }

  if (d.y >= PLATFORM_Y - 64 * FP_SCALE) {
    d.y = PLATFORM_Y - 64 * FP_SCALE;
    d.grounded = true;
    if (d.vy > 0) d.vy = 0;
    d.vx = Math.floor(d.vx * damp);
  } else {
    d.grounded = false;
  }
}

function inMeleeRange(player: DerbyPlayerState, dummy: ImpactDummyState): boolean {
  const reach = 88 * FP_SCALE;
  return Math.abs(player.x - dummy.x) < reach && Math.abs(player.y - dummy.y) < 96 * FP_SCALE;
}

export function registerHit(state: ImpactDummyDerbyState, damage: number): void {
  const applied = onDerbyHit(state, damage);
  state.dummy.damage += applied;
  state.totalDamageDealt += applied;
  state.dummy.hitstunFrames = 8;
  state.totalHits += 1;

  if (state.frame - state.lastHitFrame <= state.comboWindowFrames) {
    state.comboCount += 1;
  } else {
    state.comboCount = 1;
  }
  state.lastHitFrame = state.frame;
  state.bestCombo = Math.max(state.bestCombo, state.comboCount);

  state.events = pushDerbyEvent(state.events, {
    type: "hitLanded",
    frame: state.frame,
    damage: applied,
    combo: state.comboCount,
  });
}

export function tryNormalAttackHit(state: ImpactDummyDerbyState): void {
  const p = state.player;
  if (p.actionState !== "attacking" && p.actionState !== "special") return;
  if (p.actionFrame < ATTACK_ACTIVE_START || p.actionFrame > ATTACK_ACTIVE_END) return;
  if (!inMeleeRange(p, state.dummy)) return;

  const sizeStats = getSizeStats(state.fighter.size);
  const base =
    p.actionState === "special"
      ? Math.floor(9 * sizeStats.damageMultiplier)
      : Math.floor(5 * sizeStats.damageMultiplier);
  const kb = Math.floor((4 + state.dummy.damage / 18) * FP_SCALE) / SIM_HZ;
  registerHit(state, base);
  state.dummy.vx += p.facing * kb;
  state.dummy.vy -= Math.floor(kb / 2);
}

export function advanceBatSwing(bat: KineticBatState, attackPressed: boolean): void {
  if (bat.swingState === "idle" && attackPressed && bat.equipped) {
    bat.swingState = "startup";
    bat.swingFrame = 0;
  }

  if (bat.swingState === "idle") return;

  bat.swingFrame += 1;
  if (bat.swingState === "startup" && bat.swingFrame >= BAT_STARTUP) {
    bat.swingState = "active";
    bat.swingFrame = 0;
  } else if (bat.swingState === "active") {
    bat.sweetSpotActive = bat.swingFrame >= BAT_SWEET_START && bat.swingFrame <= BAT_SWEET_END;
    if (bat.swingFrame >= BAT_ACTIVE) {
      bat.swingState = "recovery";
      bat.swingFrame = 0;
      bat.sweetSpotActive = false;
    }
  } else if (bat.swingState === "recovery" && bat.swingFrame >= BAT_RECOVERY) {
    bat.swingState = "idle";
    bat.swingFrame = 0;
  }
}

export function tryBatLaunch(state: ImpactDummyDerbyState, input: DerbyInput): boolean {
  const bat = state.kineticBat;
  if (!bat.equipped || bat.swingState !== "active") return false;
  if (!inMeleeRange(state.player, state.dummy)) return false;

  const sweet = bat.sweetSpotActive;
  const mult = sweet ? BAT_SWEET_MULT : BAT_WEAK_MULT;
  const sizeScale = launchPowerScaleForFighter(state.fighter);
  const elementScale = batLaunchBonus(state.fighter);
  const power =
    (BAT_BASE_LAUNCH + state.dummy.damage * BAT_DAMAGE_SCALE) * mult * sizeScale * elementScale;

  const { vxScale, vyScale } = launchAngleModifiers(
    state.fighter,
    !!input.up,
    !!input.down,
  );

  const launchVx =
    (state.player.facing * Math.floor(power * FP_SCALE * vxScale)) / SIM_HZ;
  const launchVy = (-Math.floor(power * FP_SCALE * 0.65 * vyScale)) / SIM_HZ;

  state.dummy.vx = launchVx;
  state.dummy.vy = launchVy;
  state.dummy.launched = true;
  state.dummy.grounded = false;
  state.finalLaunchSpeed = Math.abs(launchVx) + Math.abs(launchVy);
  state.finalLaunchAngleDeg = launchAngleDeg(launchVx, launchVy);
  state.launchOriginX = state.dummy.x;
  state.phase = "flight";
  state.phaseFrame = 0;
  bat.equipped = false;
  bat.available = false;
  bat.swingState = "idle";

  state.events = pushDerbyEvent(state.events, {
    type: "batSwing",
    frame: state.frame,
    sweetSpot: sweet,
  });
  state.events = pushDerbyEvent(state.events, {
    type: "launch",
    frame: state.frame,
    speed: state.finalLaunchSpeed,
    angleDeg: state.finalLaunchAngleDeg,
  });
  return true;
}

export function integrateDummy(state: ImpactDummyDerbyState): void {
  const d = state.dummy;
  if (d.hitstunFrames > 0) d.hitstunFrames -= 1;

  const velScale = dummyVelocityScale(state);

  if (state.phase === "flight" || d.launched) {
    d.vy += GRAVITY;
    d.x += Math.floor(d.vx * velScale);
    d.y += Math.floor(d.vy * velScale);
    d.vx = Math.floor(d.vx * 0.998);
    state.flightDistance = Math.max(0, d.x - state.launchOriginX);

    if (d.y >= PLATFORM_Y - 32 * FP_SCALE && d.vy >= 0) {
      d.y = PLATFORM_Y - 32 * FP_SCALE;
      d.vy = 0;
      d.vx = Math.floor(d.vx * 0.7);
      if (Math.abs(d.vx) < FP_SCALE / 8) {
        d.vx = 0;
        d.landed = true;
        if (state.phase === "flight") {
          state.finalDistance = state.flightDistance;
          state.phase = "landed";
          state.phaseFrame = 0;
          state.events = pushDerbyEvent(state.events, {
            type: "landed",
            frame: state.frame,
            distance: state.finalDistance,
          });
        }
      }
    }
  } else {
    d.vy += GRAVITY;
    d.x += Math.floor(d.vx * velScale);
    d.y += Math.floor(d.vy * velScale);
    applyBarrier(state);
  }
}

export function fallbackLaunch(state: ImpactDummyDerbyState): void {
  const power = 12 + state.dummy.damage * 0.15;
  state.dummy.vx = (state.player.facing * Math.floor(power * FP_SCALE)) / SIM_HZ;
  state.dummy.vy = (-Math.floor(power * FP_SCALE * 0.4)) / SIM_HZ;
  state.dummy.launched = true;
  state.finalLaunchSpeed = Math.abs(state.dummy.vx) + Math.abs(state.dummy.vy);
  state.finalLaunchAngleDeg = launchAngleDeg(state.dummy.vx, state.dummy.vy);
  state.launchOriginX = state.dummy.x;
  state.phase = "flight";
  state.phaseFrame = 0;
  state.kineticBat.equipped = false;
  state.events = pushDerbyEvent(state.events, {
    type: "launch",
    frame: state.frame,
    speed: state.finalLaunchSpeed,
    angleDeg: state.finalLaunchAngleDeg,
  });
}
