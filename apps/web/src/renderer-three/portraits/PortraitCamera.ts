/** Bust portrait camera framing for optional Three.js renderer. */
export const PORTRAIT_CAMERA = {
  fov: 28,
  position: { x: 0, y: 1.35, z: 2.8 },
  lookAt: { x: 0, y: 1.05, z: 0 },
  bustCropY: 0.55,
} as const;

export function portraitAspectRatio(): number {
  return 4 / 5;
}
