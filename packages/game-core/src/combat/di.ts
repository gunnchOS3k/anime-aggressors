import type { InputFrame } from "../types.js";

/** Directional influence — nudge launch vector slightly based on held direction. */
export function applyDirectionalInfluence(
  vx: number,
  vy: number,
  input: InputFrame | undefined,
  strength: "light" | "medium" | "heavy" | "launch" | "super" | "beamClash",
): { vx: number; vy: number } {
  if (!input || strength === "light") return { vx, vy };
  const influence = strength === "super" ? 0.18 : strength === "heavy" ? 0.12 : 0.08;
  let dx = 0;
  let dy = 0;
  if (input.left) dx -= influence;
  if (input.right) dx += influence;
  if (input.up) dy += influence * 0.6;
  if (input.down) dy -= influence * 0.4;
  return { vx: vx + dx, vy: vy + dy };
}
