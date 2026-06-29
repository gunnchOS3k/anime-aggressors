export type CameraImpulse = {
  kind: "lightHit" | "heavyHit" | "launch" | "ko" | "super" | "beamClash";
  durationFrames: number;
  amplitude: number;
  zoomPunch: number;
  directionX: number;
  directionY: number;
};

const IMPULSE_PRESETS: Record<CameraImpulse["kind"], Omit<CameraImpulse, "directionX" | "directionY">> = {
  lightHit: { kind: "lightHit", durationFrames: 6, amplitude: 2, zoomPunch: 0.02 },
  heavyHit: { kind: "heavyHit", durationFrames: 10, amplitude: 6, zoomPunch: 0.06 },
  launch: { kind: "launch", durationFrames: 18, amplitude: 4, zoomPunch: 0.04 },
  ko: { kind: "ko", durationFrames: 24, amplitude: 14, zoomPunch: 0.1 },
  super: { kind: "super", durationFrames: 20, amplitude: 10, zoomPunch: 0.12 },
  beamClash: { kind: "beamClash", durationFrames: 28, amplitude: 5, zoomPunch: 0.05 },
};

export class CameraImpulseSystem {
  private active: CameraImpulse | null = null;
  private frame = 0;

  trigger(kind: CameraImpulse["kind"], directionX = 0, directionY = 0): void {
    const preset = IMPULSE_PRESETS[kind];
    this.active = { ...preset, directionX, directionY };
    this.frame = preset.durationFrames;
  }

  tick(): { shakeX: number; shakeY: number; zoomPunch: number; active: boolean } {
    if (!this.active || this.frame <= 0) {
      this.active = null;
      return { shakeX: 0, shakeY: 0, zoomPunch: 0, active: false };
    }
    const t = this.frame / this.active.durationFrames;
    const amp = this.active.amplitude * t;
    const shakeX = (Math.random() - 0.5) * amp + this.active.directionX * amp * 0.3;
    const shakeY = (Math.random() - 0.5) * amp + this.active.directionY * amp * 0.3;
    const zoomPunch = this.active.zoomPunch * t;
    this.frame -= 1;
    return { shakeX, shakeY, zoomPunch, active: true };
  }

  getDebugState(): { kind: string | null; framesRemaining: number } {
    return { kind: this.active?.kind ?? null, framesRemaining: this.frame };
  }
}

export function impulseFromHitStrength(
  strength: string,
): CameraImpulse["kind"] {
  if (strength === "super") return "super";
  if (strength === "heavy" || strength === "launch") return "heavyHit";
  if (strength === "medium") return "heavyHit";
  return "lightHit";
}
