import type { HitEvent } from "@anime-aggressors/game-core";
import { combatAudioBus } from "../audio/AudioEventBus.ts";
import { audioEventForHitStrength } from "../audio/CombatAudioEvents.ts";
import type { CameraImpulseSystem } from "../renderer-three/camera/CameraImpulseSystem.ts";

export type CombatPresentationHooks = {
  onHitSpark?: (event: HitEvent) => void;
  onScreenFlash?: (event: HitEvent) => void;
  onLaunchTrail?: (event: HitEvent) => void;
};

export class CombatEventAdapter {
  private lastFrame = -1;
  private cameraImpulses: CameraImpulseSystem;
  private hooks: CombatPresentationHooks;

  constructor(cameraImpulses: CameraImpulseSystem, hooks: CombatPresentationHooks = {}) {
    this.cameraImpulses = cameraImpulses;
    this.hooks = hooks;
  }

  processHitEvents(events: HitEvent[], frame: number): void {
    if (!events.length || frame === this.lastFrame) return;
    this.lastFrame = frame;

    for (const evt of events) {
      this.cameraImpulses.trigger(evt.cameraImpulseKind, evt.knockbackX >= 0 ? 1 : -1, evt.knockbackY > 0 ? -1 : 0);
      combatAudioBus.emit(audioEventForHitStrength(evt.hitStrength));
      this.hooks.onHitSpark?.(evt);
      if (evt.hitStrength === "heavy" || evt.hitStrength === "super" || evt.hitStrength === "launch") {
        this.hooks.onScreenFlash?.(evt);
      }
      if (evt.hitStrength === "launch" || evt.hitStrength === "super") {
        this.hooks.onLaunchTrail?.(evt);
      }
    }
  }
}
