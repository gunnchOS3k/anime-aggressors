import type { GameState, InputFrame, PlayerState } from "./types.js";
import {
  AIR_CONTROL,
  ATTACK_FRAMES,
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
  SPECIAL_FRAMES,
} from "./constants.js";
import { getCharacter } from "./characters.js";
import { getStage } from "./stages.js";
import { boxesOverlap, getActiveHitboxes, getHurtbox } from "./collision.js";

function applyInputMovement(player: PlayerState, input: InputFrame): void {
  const char = getCharacter(player.characterId);
  const run = (RUN_SPEED * char.runSpeedMult) / 100;

  if (player.actionState === "hitstun" || player.actionState === "defeated") {
    return;
  }

  if (player.actionState === "dodging") {
    return;
  }

  const canMove = player.onGround || player.actionState === "jumping" || player.actionState === "falling";
  if (!canMove) return;

  const speed = player.onGround ? run : AIR_CONTROL;

  if (input.left) {
    player.vx = -speed;
    player.facing = -1;
  } else if (input.right) {
    player.vx = speed;
    player.facing = 1;
  } else if (player.onGround) {
    player.vx = 0;
  }
}

function startAction(player: PlayerState, input: InputFrame): void {
  if (player.actionState === "hitstun" || player.actionState === "defeated") return;
  if (player.actionState === "attacking" || player.actionState === "special" || player.actionState === "dodging") {
    return;
  }

  if (input.dodge && player.onGround) {
    player.actionState = "dodging";
    player.actionFrame = 0;
    player.vx = player.facing * DODGE_SPEED;
    player.invulnFrames = DODGE_FRAMES;
    return;
  }

  if (input.shield) {
    player.actionState = "shielding";
    player.actionFrame = 0;
    player.vx = 0;
    return;
  }

  if (input.jump && player.jumpsRemaining > 0) {
    player.vy = JUMP_VELOCITY;
    player.jumpsRemaining -= 1;
    player.onGround = false;
    player.actionState = "jumping";
    player.actionFrame = 0;
    return;
  }

  if (input.special) {
    player.actionState = "special";
    player.actionFrame = 0;
    return;
  }

  if (input.attack) {
    player.actionState = "attacking";
    player.actionFrame = 0;
    return;
  }
}

function integratePhysics(player: PlayerState, stage: GameState["stage"]): void {
  if (player.actionState !== "shielding") {
    player.vy += GRAVITY;
    if (player.vy > MAX_FALL_SPEED) player.vy = MAX_FALL_SPEED;
  }

  player.x += player.vx;
  player.y += player.vy;

  if (player.y >= stage.floorY) {
    player.y = stage.floorY;
    player.vy = 0;
    player.onGround = true;
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

  if (player.x < stage.left) player.x = stage.left;
  if (player.x > stage.right) player.x = stage.right;
}

function tickActionState(player: PlayerState): void {
  player.actionFrame += 1;

  if (player.invulnFrames > 0) player.invulnFrames -= 1;

  if (player.actionState === "hitstun") {
    player.hitstunFrames -= 1;
    if (player.hitstunFrames <= 0) {
      player.actionState = "idle";
    }
    return;
  }

  if (player.actionState === "attacking" && player.actionFrame > ATTACK_FRAMES) {
    player.actionState = "idle";
  }
  if (player.actionState === "special" && player.actionFrame > SPECIAL_FRAMES) {
    player.actionState = "idle";
  }
  if (player.actionState === "dodging" && player.actionFrame > DODGE_FRAMES) {
    player.actionState = "idle";
  }
  if (player.actionState === "shielding") {
    player.shieldHealth = Math.max(0, player.shieldHealth - 1);
    if (player.shieldHealth <= 0) {
      player.actionState = "idle";
      player.shieldHealth = SHIELD_MAX;
    }
  }
}

function applyHit(attacker: PlayerState, defender: PlayerState, damage: number, kbX: number, kbY: number): void {
  if (defender.invulnFrames > 0) return;

  if (defender.actionState === "shielding") {
    defender.shieldHealth -= damage;
    if (defender.shieldHealth <= 0) {
      defender.actionState = "hitstun";
      defender.hitstunFrames = HITSTUN_BASE * 2;
    }
    return;
  }

  defender.damage += damage;
  defender.vx += kbX + (damage * attacker.facing) / 10;
  defender.vy += kbY;
  defender.actionState = "hitstun";
  defender.hitstunFrames = HITSTUN_BASE + Math.floor(defender.damage / 10);
  defender.onGround = false;
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
        applyHit(
          state.players[hit.ownerId],
          defender,
          hit.damage,
          hit.knockbackX,
          hit.knockbackY,
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
    if (player.actionState !== "shielding" || !input.shield) {
      if (player.actionState === "shielding" && !input.shield) {
        player.actionState = "idle";
        player.shieldHealth = SHIELD_MAX;
      }
    }

    startAction(player, input);
    applyInputMovement(player, input);
  }

  tickActionState(player);
  integratePhysics(player, state.stage);
}

export { applyHit, checkBlastZones, respawnPlayer };
