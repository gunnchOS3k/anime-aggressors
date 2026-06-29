export type CombatAudioEvent =
  | "lightHit"
  | "mediumHit"
  | "heavyHit"
  | "shieldHit"
  | "dodge"
  | "grab"
  | "throw"
  | "launch"
  | "ko"
  | "superStartup"
  | "superHit"
  | "beamClashStart"
  | "beamClashWin";

const EVENT_TONES: Record<CombatAudioEvent, { freq: number; dur: number; gain: number }> = {
  lightHit: { freq: 320, dur: 0.04, gain: 0.08 },
  mediumHit: { freq: 240, dur: 0.06, gain: 0.1 },
  heavyHit: { freq: 160, dur: 0.09, gain: 0.14 },
  shieldHit: { freq: 400, dur: 0.05, gain: 0.07 },
  dodge: { freq: 520, dur: 0.03, gain: 0.05 },
  grab: { freq: 200, dur: 0.05, gain: 0.09 },
  throw: { freq: 180, dur: 0.08, gain: 0.11 },
  launch: { freq: 140, dur: 0.12, gain: 0.12 },
  ko: { freq: 90, dur: 0.2, gain: 0.16 },
  superStartup: { freq: 280, dur: 0.15, gain: 0.1 },
  superHit: { freq: 120, dur: 0.14, gain: 0.15 },
  beamClashStart: { freq: 220, dur: 0.1, gain: 0.09 },
  beamClashWin: { freq: 300, dur: 0.12, gain: 0.12 },
};

export function playCombatAudioPlaceholder(event: CombatAudioEvent): void {
  if (typeof window === "undefined") return;
  try {
    const Ctx = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    if (!Ctx) return;
    const ctx = new Ctx();
    const tone = EVENT_TONES[event];
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = "square";
    osc.frequency.value = tone.freq;
    gain.gain.value = tone.gain;
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + tone.dur);
    osc.onended = () => void ctx.close();
  } catch {
    /* safe no-op */
  }
}

export function audioEventForHitStrength(strength: string): CombatAudioEvent {
  if (strength === "super") return "superHit";
  if (strength === "heavy" || strength === "launch") return "heavyHit";
  if (strength === "medium") return "mediumHit";
  return "lightHit";
}
