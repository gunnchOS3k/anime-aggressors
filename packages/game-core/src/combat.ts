import type { GameState, InputFrame, PlayerState } from "./types.js";
import {
  AIR_CONTROL,
  BLAST_BOTTOM,
  BLAST_LEFT,
  BLAST_RIGHT,
  BLAST_TOP,
  DODGE_FRAMES,
  DODGE_SPEED,
  GRAVITY,
  HITSTUN_BASE,
  JUMP_VELOCITY,
  MAX_FALL_SPEED,
  RUN_SPEED,
  SHIELD_MAX,
} from "./constants.js";
import { getCharacter } from "./characters.js";
import { getStage } from "./stages.js";
import { boxesOverlap, getActiveHitboxes, getHurtbox } from "./collision.js";
import { DODGE_MOVE, NEUTRAL_ATTACK, SPECIAL_ATTACK } from "./frameData.js";
import { getMoveData, isMoveComplete, type MoveId } from "./moves.js";
import {
  bufferJump,
  canCoyoteJump,
  consumeJumpBuffer,
  FAST_FALL_MULT,
  scaleKnockback,
  tickCoyoteTime,
} from "./feel.js";

function applyInputMovement(player: PlayerState, input: InputFrame): void {
  const char = getCharacter(player.characterId);
  const run = (RUN_SPEED * char.runSpeedMult) / 100;

  if (player.actionState === "hitstun" || player.actionState === "defeated") return;
  if (player.actionState === "dodging") return;

  const canMove =
    player.onGround ||
    player.actionState === "jumping" ||
    player.actionState === "falling" ||
    player.actionState === "idle" ||
    player.actionState === "running";

  if (!canMove) return;

  const speed = player.onGround ? run : AIR_CONTROL;

  if (input.left) {
    player.vx = -speed;
    player.facing = -1;
    if (player.onGround) player.actionState = "running";
  } else if (input.right) {
    player.vx = speed;
    player.facing = 1;
    if (player.onGround) player.actionState = "running";
  } else if (player.onGround && player.actionState === "running") {
    player.vx = 0;
    player.actionState = "idle";
  }

  if (!player.onGround && input.down) {
    player.fastFalling = true;
  }
}

function startAction(player: PlayerState, input: InputFrame): void {
  if (player.actionState === "hitstun" || player.actionState === "defeated") return;
  if (
    player.actionState === "attacking" ||
    player.actionState === "special" ||
    player.actionState === "dodging"
  ) {
    return;
  }

  bufferJump(player, input.jump);

  if (input.dodge && player.onGround) {
    player.actionState = "dodging";
    player.actionFrame = 0;
    player.currentMoveId = "dodge";
    player.vx = player.facing * DODGE_SPEED;
    player.invulnFrames = DODGE_MOVE.startup + DODGE_MOVE.active;
    return;
  }

  if (input.shield) {
    player.actionState = "shielding";
    player.actionFrame = 0;
    player.vx = 0;
    return;
  }

  const wantsJump = input.jump || consumeJumpBuffer(player);
  if (wantsJump && (player.jumpsRemaining > 0 || canCoyoteJump(player))) {
    if (player.jumpsRemaining > 0) {
      player.jumpsRemaining -= 1;
    } else {
      player.coyoteFrames = 0;
    }
    player.vy = JUMP_VELOCITY;
    player.onGround = false;
    player.actionState = "jumping";
    player.actionFrame = 0;
    player.fastFalling = false;
    return;
  }

  if (input.special) {
    player.actionState = "special";
    player.actionFrame = 0;
    player.currentMoveId = input.left || input.right ? "side_special" : "special_attack";
    return;
  }

  if (input.attack) {
    player.actionState = "attacking";
    player.actionFrame = 0;
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

function integratePhysics(player: PlayerState, stage: GameState["stage"]): void {
  const wasOnGround = player.onGround;

  if (player.actionState !== "shielding") {
    player.vy += GRAVITY;
    let maxFall = MAX_FALL_SPEED;
    if (player.fastFalling && !player.onGround) {
      maxFall = (MAX_FALL_SPEED * FAST_FALL_MULT) / 100;
    }
    if (player.vy > maxFall) player.vy = maxFall;
  }

  player.x += player.vx;
  player.y += player.vy;

  if (player.y >= stage.floorY) {
    player.y = stage.floorY;
    player.vy = 0;
    player.onGround = true;
    player.fastFalling = false;
    const char = getCharacter(player.characterId);
    player.jumpsRemaining = char.maxJumps;
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

function tickActionState(player: PlayerState): void {
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
    const data = getMoveData(player.currentMoveId as MoveId);
    if (data && isMoveComplete(data, player.actionFrame)) {
      player.actionState = "idle";
      player.currentMoveId = "none";
    }
  }
  if (player.actionState === "dodging" && isMoveComplete(DODGE_MOVE, player.actionFrame)) {
    player.actionState = "idle";
    player.currentMoveId = "none";
  }
  if (player.actionState === "shielding") {
    player.shieldHealth = Math.max(0, player.shieldHealth - 1);
    if (player.shieldHealth <= 0) {
      player.actionState = "hitstun";
      player.hitstunFrames = HITSTUN_BASE * 2;
    }
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

  defender.damage += damage;
  defender.vx += kbX + (kb.kbX * attacker.facing) / 10;
  defender.vy += kbY + kb.kbY / 10;
  defender.actionState = "hitstun";
  defender.hitstunFrames = HITSTUN_BASE + Math.floor(defender.damage / 10);
  defender.onGround = false;
  defender.currentMoveId = "none";

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

function respawnPlayer(player: PlayerState, spawn: { x: number; y: number }): void {
  player.x = spawn.x;
  player.y = spawn.y;
  player.vx = 0;
  player.vy = 0;
  player.damage = 0;
  player.actionState = "idle";
  player.actionFrame = 0;
  player.hitstunFrames = 0;
  player.invulnFrames = 60;
  player.coyoteFrames = 0;
  player.jumpBufferFrames = 0;
  player.fastFalling = false;
  player.currentMoveId = "none";
  const char = getCharacter(player.characterId);
  player.jumpsRemaining = char.maxJumps;
  player.onGround = true;
}

export function resolveCombat(state: GameState): void {
  const hitboxes = state.players.flatMap((p) => getActiveHitboxes(p));

  for (const hit of hitboxes) {
    if (!hit.active) continue;
    for (const defender of state.players) {
      if (defender.id === hit.ownerId) continue;
      if (defender.actionState === "defeated") continue;

      const hurt = getHurtbox(defender);
      if (boxesOverlap(hit, hurt)) {
        const moveData =
          state.players[hit.ownerId].actionState === "special"
            ? SPECIAL_ATTACK
            : NEUTRAL_ATTACK;
        applyHit(
          state,
          state.players[hit.ownerId],
          defender,
          hit.damage,
          hit.knockbackX,
          hit.knockbackY,
          moveData.hitstop,
        );
      }
    }
  }

  for (const player of state.players) {
    if (player.actionState === "defeated") continue;
    if (checkBlastZones(player)) {
      player.stocks -= 1;
      if (player.stocks <= 0) {
        player.actionState = "defeated";
      } else {
        const stageDef = getStage(state.config.stageId);
        const spawn = stageDef.spawnPoints[player.id] ?? stageDef.spawnPoints[0];
        respawnPlayer(player, spawn);
      }
    }
  }
}

export function processPlayer(state: GameState, player: PlayerState, input: InputFrame | undefined): void {
  if (player.actionState === "defeated") return;

  if (input) {
    if (player.actionState === "shielding" && !input.shield) {
      player.actionState = "idle";
      player.shieldHealth = SHIELD_MAX;
    }

    startAction(player, input);
    applyInputMovement(player, input);
  } else {
    if (player.jumpBufferFrames > 0) player.jumpBufferFrames -= 1;
  }

  tickActionState(player);
  integratePhysics(player, state.stage);
}

export { applyHit, checkBlastZones, respawnPlayer };
