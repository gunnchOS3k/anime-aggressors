import type { SfxEventType } from "@anime-aggressors/game-core";

export const SFX_CATALOG: Record<SfxEventType, { freq: number; duration: number; type: OscillatorType }> = {
  attack_whiff: { freq: 180, duration: 0.04, type: "triangle" },
  hit_confirm: { freq: 320, duration: 0.08, type: "square" },
  shield_hit: { freq: 140, duration: 0.1, type: "sine" },
  dodge: { freq: 400, duration: 0.05, type: "sine" },
  jump: { freq: 260, duration: 0.06, type: "triangle" },
  land: { freq: 90, duration: 0.07, type: "sine" },
  ko: { freq: 520, duration: 0.25, type: "sawtooth" },
  menu_select: { freq: 440, duration: 0.03, type: "sine" },
  result: { freq: 660, duration: 0.2, type: "triangle" },
};
