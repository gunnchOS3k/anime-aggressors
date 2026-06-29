import type { CombatAudioEvent } from "./CombatAudioEvents.ts";
import { playCombatAudioPlaceholder } from "./CombatAudioEvents.ts";

type Listener = (event: CombatAudioEvent) => void;

export class AudioEventBus {
  private listeners = new Set<Listener>();

  on(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  emit(event: CombatAudioEvent): void {
    for (const l of this.listeners) l(event);
    playCombatAudioPlaceholder(event);
  }
}

export const combatAudioBus = new AudioEventBus();
