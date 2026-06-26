import type { GameState, InputFrame } from "./types.js";
import { cloneGameState } from "./state.js";
import { processPlayer, resolveCombat } from "./combat.js";
import { getStage } from "./stages.js";

export function simulateFrame(state: GameState, inputs: InputFrame[]): GameState {
  const next = cloneGameState(state);
  next.frame += 1;

  if (next.phase === "countdown") {
    next.countdownFrames -= 1;
    if (next.countdownFrames <= 0) {
      next.phase = "fighting";
    }
    return next;
  }

  if (next.phase === "results") {
    return next;
  }

  if (next.phase === "fighting") {
    if (next.hitstopFrames > 0) {
      next.hitstopFrames -= 1;
      return next;
    }

    next.matchTimerFrames -= 1;

    const inputByPlayer = new Map<number, InputFrame>();
    for (const input of inputs) {
      inputByPlayer.set(input.playerId, input);
    }

    for (const player of next.players) {
      processPlayer(next, player, inputByPlayer.get(player.id));
    }

    resolveCombat(next);

    const alive = next.players.filter((p) => p.actionState !== "defeated");
    if (alive.length === 1) {
      next.phase = "results";
      next.winnerId = alive[0].id;
    } else if (alive.length === 0) {
      next.phase = "results";
      next.winnerId = null;
    } else if (next.matchTimerFrames <= 0) {
      next.phase = "results";
      let best = alive[0];
      for (const p of alive) {
        if (p.stocks > best.stocks || (p.stocks === best.stocks && p.damage < best.damage)) {
          best = p;
        }
      }
      next.winnerId = best.id;
    }
  }

  return next;
}

export function resetForRematch(state: GameState): GameState {
  const stage = getStage(state.config.stageId);
  const fresh = cloneGameState(state);
  fresh.frame = 0;
  fresh.phase = "countdown";
  fresh.countdownFrames = 3 * 60;
  fresh.matchTimerFrames = state.config.matchDurationFrames;
  fresh.winnerId = null;
  fresh.hitstopFrames = 0;

  for (let i = 0; i < fresh.players.length; i++) {
    const spawn = stage.spawnPoints[i];
    const p = fresh.players[i];
    p.x = spawn.x;
    p.y = spawn.y;
    p.vx = 0;
    p.vy = 0;
    p.damage = 0;
    p.stocks = state.config.stocks;
    p.actionState = "idle";
    p.actionFrame = 0;
    p.hitstunFrames = 0;
    p.shieldHealth = 100;
    p.invulnFrames = 0;
    p.onGround = true;
    p.coyoteFrames = 0;
    p.jumpBufferFrames = 0;
    p.fastFalling = false;
    p.currentMoveId = "none";
    const char = fresh.config.characterIds[i];
    p.characterId = char ?? p.characterId;
  }

  return fresh;
}
