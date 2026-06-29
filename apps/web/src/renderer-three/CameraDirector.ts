import * as THREE from "three";
import type { GameState } from "@anime-aggressors/game-core";
import { STAGE_HEIGHT, STAGE_WIDTH } from "@anime-aggressors/game-core";
import { computeCameraBounds, type CameraBounds } from "./cameraBounds.ts";
import { fpToWorld } from "./RenderTypes.ts";
import { applyBattleCameraAngle } from "./camera/BattleCamera.ts";
import { PlatformFighterCamera } from "./camera/PlatformFighterCamera.ts";
import { CAMERA_DEFAULTS } from "./camera/CameraBounds.ts";

export type { CameraBounds };

const DEFAULT_HALF_WIDTH = 340;
const DEFAULT_TARGET = new THREE.Vector3(
  fpToWorld(STAGE_WIDTH / 2),
  fpToWorld(STAGE_HEIGHT * 0.62),
  0,
);

export class CameraDirector {
  private camera: THREE.OrthographicCamera;
  private platformCam = new PlatformFighterCamera();
  private target = DEFAULT_TARGET.clone();
  private halfWidth = DEFAULT_HALF_WIDTH;
  private aspect = 16 / 9;
  private debugOverlay: HTMLElement | null = null;

  constructor(aspect: number, smooth = true) {
    void smooth;
    this.aspect = aspect;
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 8000);
    applyBattleCameraAngle(this.camera, DEFAULT_TARGET, this.halfWidth);
    this.resize(aspect);
    if (typeof window !== "undefined") {
      window.addEventListener("keydown", (e) => {
        if (e.key === "F4") {
          this.platformCam.setDebugEnabled(!this.platformCam.isDebugEnabled());
          this.updateDebugOverlay();
        }
      });
    }
  }

  getCamera(): THREE.OrthographicCamera {
    return this.camera;
  }

  getTarget(): THREE.Vector3 {
    return this.target;
  }

  getZoom(): number {
    return this.halfWidth;
  }

  getPlatformCamera(): PlatformFighterCamera {
    return this.platformCam;
  }

  computeBounds(state: GameState): CameraBounds {
    return computeCameraBounds(state);
  }

  update(state: GameState, _hitEvent = false, koEvent = false): void {
    const cam = this.platformCam.update(state, this.aspect, koEvent);
    this.target.set(cam.centerX, cam.centerY, 0);
    this.halfWidth = DEFAULT_HALF_WIDTH / cam.zoomFactor;

    applyBattleCameraAngle(this.camera, this.target, this.halfWidth);
    this.camera.left = -this.halfWidth;
    this.camera.right = this.halfWidth;
    this.camera.top = this.halfWidth / this.aspect;
    this.camera.bottom = -this.halfWidth / this.aspect;
    this.camera.updateProjectionMatrix();
    this.updateDebugOverlay(cam);
  }

  resize(aspect: number): void {
    this.aspect = aspect;
    this.camera.left = -this.halfWidth;
    this.camera.right = this.halfWidth;
    this.camera.top = this.halfWidth / this.aspect;
    this.camera.bottom = -this.halfWidth / this.aspect;
    this.camera.updateProjectionMatrix();
  }

  resetToStageDefault(): void {
    this.target.copy(DEFAULT_TARGET);
    this.halfWidth = DEFAULT_HALF_WIDTH;
    this.platformCam.reset(DEFAULT_TARGET.x, DEFAULT_TARGET.y);
  }

  mountDebugOverlay(container: HTMLElement): void {
    this.debugOverlay = document.createElement("div");
    this.debugOverlay.className = "camera-debug-overlay hidden";
    container.appendChild(this.debugOverlay);
  }

  private updateDebugOverlay(cam?: ReturnType<PlatformFighterCamera["update"]>): void {
    if (!this.debugOverlay) return;
    const enabled = this.platformCam.isDebugEnabled();
    this.debugOverlay.classList.toggle("hidden", !enabled);
    if (!enabled || !cam) return;
    this.debugOverlay.innerHTML = `
      <div>Camera center: ${cam.centerX.toFixed(1)}, ${cam.centerY.toFixed(1)}</div>
      <div>Zoom: ${cam.zoomFactor.toFixed(2)} (min ${CAMERA_DEFAULTS.minZoom} / max ${CAMERA_DEFAULTS.maxZoom})</div>
      <div>Bounds: ${cam.target.requiredWidth.toFixed(0)}×${cam.target.requiredHeight.toFixed(0)}</div>
    `;
  }
}
