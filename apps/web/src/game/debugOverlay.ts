import type { InputFrame } from "@anime-aggressors/game-core";

export type DebugInfo = {
  frame: number;
  hash: string;
  rollbackCount: number;
  inputs: InputFrame[];
};

export function renderDebugOverlay(ctx: CanvasRenderingContext2D, info: DebugInfo): void {
  const x = 16;
  let y = 90;

  ctx.fillStyle = "rgba(0,0,0,0.65)";
  ctx.fillRect(x - 8, y - 16, 420, 120);

  ctx.fillStyle = "#00ff88";
  ctx.font = "11px monospace";
  ctx.fillText(`hash: ${info.hash}`, x, y);
  y += 14;
  ctx.fillText(`rollback: ${info.rollbackCount}`, x, y);
  y += 14;

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
    ].filter(Boolean).join(" ");
    ctx.fillText(`P${input.playerId + 1}: ${flags || "(none)"}`, x, y);
    y += 14;
  }
}
