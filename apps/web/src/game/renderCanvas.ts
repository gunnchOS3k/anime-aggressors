import {
  fpToDisplay,
  getActiveHitboxes,
  getHurtbox,
  getCharacter,
  getStage,
  type GameState,
} from "@anime-aggressors/game-core";

export type RenderOptions = {
  showHitboxes: boolean;
};

export function renderFrame(
  ctx: CanvasRenderingContext2D,
  width: number,
  height: number,
  state: GameState,
  options: RenderOptions,
): void {
  ctx.fillStyle = "#1a1a2e";
  ctx.fillRect(0, 0, width, height);

  const stage = getStage(state.config.stageId);
  const scaleX = width / 2400;
  const scaleY = height / 1350;

  // Stage floor
  ctx.fillStyle = "#2d3436";
  const floorY = fpToDisplay(stage.bounds.floorY) * scaleY;
  ctx.fillRect(0, floorY, width, height - floorY);

  ctx.strokeStyle = "#636e72";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(0, floorY);
  ctx.lineTo(width, floorY);
  ctx.stroke();

  // Blast zone hints
  ctx.strokeStyle = "rgba(255, 107, 107, 0.3)";
  ctx.strokeRect(20, 20, width - 40, height - 40);

  // Players
  for (const player of state.players) {
    const char = getCharacter(player.characterId);
    const px = fpToDisplay(player.x) * scaleX;
    const py = fpToDisplay(player.y) * scaleY;

    ctx.fillStyle = char.color;
    ctx.fillRect(px - 24, py - 64, 48, 64);

    ctx.fillStyle = "#fff";
    ctx.font = "12px monospace";
    ctx.fillText(`${char.name} ${player.damage}%`, px - 40, py - 72);
    ctx.fillText(`x${player.stocks}`, px - 10, py - 84);

    if (options.showHitboxes) {
      const hurt = getHurtbox(player);
      ctx.strokeStyle = "rgba(0, 255, 128, 0.6)";
      ctx.strokeRect(
        fpToDisplay(hurt.x) * scaleX,
        fpToDisplay(hurt.y) * scaleY,
        fpToDisplay(hurt.w) * scaleX,
        fpToDisplay(hurt.h) * scaleY,
      );

      for (const hit of getActiveHitboxes(player)) {
        ctx.strokeStyle = "rgba(255, 64, 64, 0.8)";
        ctx.strokeRect(
          fpToDisplay(hit.x) * scaleX,
          fpToDisplay(hit.y) * scaleY,
          fpToDisplay(hit.w) * scaleX,
          fpToDisplay(hit.h) * scaleY,
        );
      }
    }

    if (player.actionState === "defeated") {
      ctx.globalAlpha = 0.35;
      ctx.fillRect(px - 24, py - 64, 48, 64);
      ctx.globalAlpha = 1;
    }
  }

  // HUD
  ctx.fillStyle = "#fff";
  ctx.font = "14px monospace";
  const timerSec = Math.max(0, Math.ceil(state.matchTimerFrames / 60));
  ctx.fillText(`Time: ${Math.floor(timerSec / 60)}:${String(timerSec % 60).padStart(2, "0")}`, 16, 24);
  ctx.fillText(`Phase: ${state.phase}`, 16, 44);
  ctx.fillText(`Frame: ${state.frame}`, 16, 64);

  if (state.phase === "countdown") {
    ctx.font = "48px sans-serif";
    ctx.fillStyle = "#ffeaa7";
    ctx.fillText(String(Math.ceil(state.countdownFrames / 60)), width / 2 - 16, height / 2);
  }
}
