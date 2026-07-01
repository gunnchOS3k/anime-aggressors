import type { GameState, InputFrame } from "./types.js";
import { cloneGameState } from "./state.js";
import { processPlayer, resolveCombat } from "./combat.js";
import { tickEnergyAttacks, detectEnergyClashes, tickEnergyClashes } from "./combat/energyClash.js";
import { mergeCpuInputs } from "./bots/versusCpu.js";
import { applyTrainingDummyBehavior } from "./training/trainingMode.js";
import { getStage } from "./stages.js";
import { getStageLayout } from "./stageLayouts.js";
import { createDefaultAuraState } from "./aura/auraTypes.js";
import { resetMovementFields } from "./movement/movementTypes.js";
import { resetCombatFields } from "./combat/combatState.js";
import { clearStaleQueue } from "./combat/staleMoves.js";

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

    let frameInputs = inputs;
    if (next.config.cpuOpponents?.length) {
      frameInputs = mergeCpuInputs(next, inputs, next.config.cpuOpponents);
    }

    if (next.config.training) {
      const { dummyPlayerId, dummyBehavior } = next.config.training;
      const dummy = next.players[dummyPlayerId];
      if (dummy && dummyBehavior !== "cpu1") {
        const partial = applyTrainingDummyBehavior(dummy, dummyBehavior, next.frame);
        const existing = frameInputs.find((i) => i.playerId === dummyPlayerId);
        const base = existing ?? {
          frame: next.frame,
          playerId: dummyPlayerId,
          left: false,
          right: false,
          up: false,
          down: false,
          jump: false,
          attack: false,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        };
        const merged = { ...base, ...partial, frame: next.frame, playerId: dummyPlayerId };
        frameInputs = [...frameInputs.filter((i) => i.playerId !== dummyPlayerId), merged];
      }
    }

    const inputByPlayer = new Map<number, InputFrame>();
    for (const input of frameInputs) {
      inputByPlayer.set(input.playerId, input);
    }

    for (const player of next.players) {
      processPlayer(next, player, inputByPlayer.get(player.id));
    }

    resolveCombat(next, frameInputs);

    tickEnergyAttacks(next);
    detectEnergyClashes(next);
    tickEnergyClashes(next, inputs);

    const matchType = next.config.ruleset?.matchType ?? "stock";

    if (matchType === "stamina") {
      for (const p of next.players) {
        if (p.staminaHp <= 0 && p.actionState !== "defeated") {
          p.actionState = "defeated";
        }
      }
    }

    const alive = next.players.filter((p) => p.actionState !== "defeated");
    if (alive.length === 1) {
      next.phase = "results";
      next.winnerId = alive[0].id;
    } else if (alive.length === 0) {
      next.phase = "results";
      next.winnerId = null;
    } else if (next.matchTimerFrames <= 0 && next.config.ruleset?.timerSeconds !== null) {
      next.phase = "results";
      if (matchType === "time") {
        let best = alive[0];
        for (const p of alive) {
          if (p.score > best.score || (p.score === best.score && p.damage < best.damage)) {
            best = p;
          }
        }
        next.winnerId = best.id;
      } else {
        let best = alive[0];
        for (const p of alive) {
          if (p.stocks > best.stocks || (p.stocks === best.stocks && p.damage < best.damage)) {
            best = p;
          }
        }
        next.winnerId = best.id;
      }
    }
  }

  return next;
}

export function resetForRematch(state: GameState): GameState {
  const stage = getStage(state.config.stageId);
  const layout = getStageLayout(stage.layoutId ?? stage.id);
  const fresh = cloneGameState(state);
  fresh.frame = 0;
  fresh.phase = "countdown";
  fresh.countdownFrames = 3 * 60;
  fresh.matchTimerFrames = state.config.matchDurationFrames;
  fresh.winnerId = null;
  fresh.hitstopFrames = 0;
  fresh.lastHitEvents = [];

  for (let i = 0; i < fresh.players.length; i++) {
    const spawn = stage.spawnPoints[i];
    const p = fresh.players[i];
    p.x = spawn.x;
    p.y = spawn.y;
    p.vx = 0;
    p.vy = 0;
    p.damage = 0;
    p.staminaHp = state.config.ruleset?.matchType === "stamina" ? state.config.ruleset.staminaHp : 0;
    p.score = 0;
    p.stocks = state.config.stocks;
    p.actionState = "idle";
    p.actionFrame = 0;
    resetCombatFields(p);
    clearStaleQueue(p);
    p.shieldHealth = 100;
    p.invulnFrames = 0;
    p.onGround = true;
    p.coyoteFrames = 0;
    p.jumpBufferFrames = 0;
    p.jumpsUsed = 0;
    p.jumpHoldFrames = 0;
    p.wasJumpHeld = false;
    p.fastFalling = false;
    p.currentPlatformId = layout.mainPlatformId;
    p.dropThroughFrames = 0;
    p.ignoredPlatformId = "";
    resetMovementFields(p);
    p.aura = createDefaultAuraState();
    const char = fresh.config.characterIds[i];
    p.characterId = char ?? p.characterId;
  }

  return fresh;
}
