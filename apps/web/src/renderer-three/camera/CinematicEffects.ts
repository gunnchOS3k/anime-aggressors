import type { GameState } from "@anime-aggressors/game-core";

export type CinematicPulse = {
  shake: number;
  hitStopScale: number;
  zoomBias: number;
};

export function computeCinematicPulse(
  hitEvent: boolean,
  koEvent: boolean,
  hitstopFrames: number,
): CinematicPulse {
  let shake = 0;
  let hitStopScale = 1;
  let zoomBias = 0;

  if (hitEvent || hitstopFrames > 0) {
    shake = hitstopFrames > 8 ? 0.55 : 0.32;
    hitStopScale = 0.35;
    zoomBias = -0.08;
  }
  if (koEvent) {
    shake = 1.1;
    hitStopScale = 0.15;
    zoomBias = -0.18;
  }

  return { shake, hitStopScale, zoomBias };
}

export function applyHitStopToDelta(delta: number, pulse: CinematicPulse): number {
  return delta * pulse.hitStopScale;
}

export function launchCameraBias(state: GameState): number {
  const maxVy = Math.max(...state.players.map((p) => Math.abs(p.vy)));
  if (maxVy > 1200) return -0.12;
  return 0;
}
