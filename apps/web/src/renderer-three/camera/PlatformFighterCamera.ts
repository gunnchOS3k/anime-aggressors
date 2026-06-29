import type { GameState } from "@anime-aggressors/game-core";
import {
  CAMERA_DEFAULTS,
  computeCameraFrameTarget,
  computeZoomFactor,
  type CameraFrameTarget,
} from "./CameraBounds.ts";
import { CameraImpulseSystem } from "./CameraImpulseSystem.ts";
import { launchCameraBias } from "./CinematicEffects.ts";

export type PlatformCameraState = {
  centerX: number;
  centerY: number;
  zoomFactor: number;
  target: CameraFrameTarget;
};

export class PlatformFighterCamera {
  private centerX = 0;
  private centerY = 0;
  private zoomFactor = CAMERA_DEFAULTS.defaultZoom;
  private impulses = new CameraImpulseSystem();
  private debugEnabled = false;

  getImpulseSystem(): CameraImpulseSystem {
    return this.impulses;
  }

  setDebugEnabled(on: boolean): void {
    this.debugEnabled = on;
  }

  isDebugEnabled(): boolean {
    return this.debugEnabled;
  }

  update(state: GameState, aspect: number, koEvent = false): PlatformCameraState {
    const target = computeCameraFrameTarget(state);
    let desiredZoom = computeZoomFactor(target, aspect);
    desiredZoom += launchCameraBias(state) * 0.15;

    if (koEvent) this.impulses.trigger("ko");

    const lastHit = state.lastHitEvents?.[state.lastHitEvents.length - 1];
    if (lastHit && state.frame - lastHit.frame <= 1) {
      const dir = lastHit.knockbackX >= 0 ? 1 : -1;
      this.impulses.trigger(lastHit.cameraImpulseKind, dir, lastHit.knockbackY > 0 ? -1 : 0);
    }

    const impulse = this.impulses.tick();
    desiredZoom = Math.min(
      CAMERA_DEFAULTS.maxZoom + impulse.zoomPunch,
      Math.max(CAMERA_DEFAULTS.minZoom - impulse.zoomPunch * 0.5, desiredZoom + impulse.zoomPunch),
    );

    this.centerX += (target.centerX - this.centerX) * CAMERA_DEFAULTS.positionSmooth;
    this.centerY += (target.centerY - this.centerY) * CAMERA_DEFAULTS.positionSmooth;
    this.zoomFactor += (desiredZoom - this.zoomFactor) * CAMERA_DEFAULTS.zoomSmooth;

    return {
      centerX: this.centerX + impulse.shakeX,
      centerY: this.centerY + impulse.shakeY,
      zoomFactor: this.zoomFactor,
      target,
    };
  }

  reset(cx: number, cy: number): void {
    this.centerX = cx;
    this.centerY = cy;
    this.zoomFactor = CAMERA_DEFAULTS.defaultZoom;
  }

  getDebugSnapshot(): PlatformCameraState & { impulse: ReturnType<CameraImpulseSystem["getDebugState"]> } {
    return {
      centerX: this.centerX,
      centerY: this.centerY,
      zoomFactor: this.zoomFactor,
      target: {
        centerX: this.centerX,
        centerY: this.centerY,
        minX: 0,
        maxX: 0,
        minY: 0,
        maxY: 0,
        requiredWidth: 0,
        requiredHeight: 0,
      },
      impulse: this.impulses.getDebugState(),
    };
  }
}
