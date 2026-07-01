import type { SfxEventType } from "@anime-aggressors/game-core";
import { SFX_CATALOG } from "./sfxCatalog.js";
import { getAudioVolume, isAudioMuted } from "../demo/audioSettings.ts";

export class AudioManager {
  private ctx: AudioContext | null = null;
  private enabled = true;

  private ensureContext(): AudioContext | null {
    if (!this.enabled || isAudioMuted()) return null;
    if (!this.ctx) {
      this.ctx = new AudioContext();
    }
    return this.ctx;
  }

  play(type: SfxEventType, intensity = 1): void {
    const ctx = this.ensureContext();
    if (!ctx) return;

    const spec = SFX_CATALOG[type];
    const volume = getAudioVolume();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = spec.type;
    osc.frequency.value = spec.freq * (0.9 + intensity * 0.2);
    gain.gain.value = 0.08 * intensity * volume;
    osc.connect(gain);
    gain.connect(ctx.destination);
    const t = ctx.currentTime;
    osc.start(t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + spec.duration);
    osc.stop(t + spec.duration + 0.01);
  }

  playMenuConfirm(): void {
    this.play("menu_select");
  }

  playMenuNavigate(): void {
    this.play("dodge", 0.5);
  }

  setEnabled(on: boolean): void {
    this.enabled = on;
  }
}

export const globalAudio = new AudioManager();
