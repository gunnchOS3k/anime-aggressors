import type { GameState, InputFrame } from "@anime-aggressors/game-core";
import { fpToDisplay, currentMovePhase } from "@anime-aggressors/game-core";

export type DebugInfo = {
  frame: number;
  hash: string;
  rollbackCount: number;
  inputs: InputFrame[];
  gameState: GameState;
  paused?: boolean;
  fighterStateDebug?: boolean;
};

export type DebugPanel = {
  update: (info: DebugInfo) => void;
  toggle: () => void;
  destroy: () => void;
};

export function mountDebugPanel(container: HTMLElement): DebugPanel {
  const panel = document.createElement("div");
  panel.className = "debug-panel hidden";
  panel.innerHTML = `
    <div class="debug-title">Training / Debug (F1)</div>
    <pre id="debug-body"></pre>
  `;
  container.appendChild(panel);

  const body = panel.querySelector("#debug-body") as HTMLPreElement;

  const update = (info: DebugInfo): void => {
    const lines: string[] = [
      `frame: ${info.frame}`,
      `hash: ${info.hash}`,
      `rollback: ${info.rollbackCount}`,
      `paused: ${info.paused ? "yes" : "no"}`,
      "",
    ];

    for (const p of info.gameState.players) {
      lines.push(
        `P${p.id + 1} pos=(${fpToDisplay(p.x)},${fpToDisplay(p.y)}) vel=(${fpToDisplay(p.vx)},${fpToDisplay(p.vy)})`,
        `  action=${p.actionState} moveFrame=${p.actionFrame} move=${p.currentMoveId}`,
        `  phase=${currentMovePhase(p)} damage=${p.damage}% stocks=${p.stocks}`,
        `  hitstun=${p.hitstunFrames} hitstop=${info.gameState.hitstopFrames} shield=${Math.floor(p.shieldHealth)}`,
        `  shieldStun=${p.shieldStunFrames} grab=${p.grabTargetId >= 0 ? `target P${p.grabTargetId + 1}` : p.grabbedByPlayerId >= 0 ? `held by P${p.grabbedByPlayerId + 1}` : "—"}`,
        `  stale=[${p.staleMoveQueue.slice(0, 3).join(",")}]`,
        `  onGround=${p.onGround} invuln=${p.invulnFrames}`,
        `  movement=${p.movementState} plat=${p.currentPlatformId || "—"} ledge=${p.grabbedLedgeId || "—"}`,
        `  jumpsUsed=${p.jumpsUsed} landingLag=${p.landingLagFrames}`,
      );
      if (info.fighterStateDebug) {
        lines.push(
          `  jumpsRemaining=${p.jumpsRemaining} coyote=${p.coyoteFrames} jumpBuf=${p.jumpBufferFrames}`,
          `  auraCharging=${p.aura.charging} hitstop=${info.gameState.hitstopFrames}`,
        );
      }
    }

    lines.push("", "inputs:");
    for (const input of info.inputs) {
      const flags = [
        input.left && "L",
        input.right && "R",
        input.jump && "J",
        input.attack && "A",
        input.special && "S",
        input.shield && "Sh",
        input.dodge && "D",
        input.grab && "G",
        input.wearableGesture && `W:${input.wearableGesture}`,
      ]
        .filter(Boolean)
        .join(" ");
      lines.push(`  P${input.playerId + 1}: ${flags || "(none)"}`);
    }

    lines.push("", "F2 hitboxes | F3 pause | F4 step | F6 fighter state | R reset");
    body.textContent = lines.join("\n");
    if (info.fighterStateDebug) panel.classList.remove("hidden");
  };

  return {
    update,
    toggle: () => panel.classList.toggle("hidden"),
    destroy: () => panel.remove(),
  };
}
