import * as THREE from "three";
import type { GameState } from "@anime-aggressors/game-core";
import { FP_SCALE, STAGE_HEIGHT, STAGE_WIDTH } from "@anime-aggressors/game-core";
import { computeCameraBounds, type CameraBounds } from "./cameraBounds.ts";
import { computeCinematicPulse, launchCameraBias } from "./camera/CinematicEffects.ts";
import { fpToWorld } from "./RenderTypes.ts";

export type { CameraBounds };

const DEFAULT_TARGET = new THREE.Vector3(
  fpToWorld(STAGE_WIDTH / 2),
  fpToWorld(STAGE_HEIGHT * 0.62),
  0,
);
const DEFAULT_ZOOM = 420;
const MIN_ZOOM = 180;
const MAX_ZOOM = 720;

export class CameraDirector {
  private camera: THREE.OrthographicCamera;
  private target = DEFAULT_TARGET.clone();
  private zoom = DEFAULT_ZOOM;
  private smooth: boolean;
  private shake = 0;
  private aspect = 16 / 9;

  constructor(aspect: number, smooth = true) {
    this.smooth = smooth;
    this.aspect = aspect;
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 5000);
    this.camera.position.set(DEFAULT_TARGET.x, DEFAULT_TARGET.y, 800);
    this.camera.lookAt(DEFAULT_TARGET);
    this.resize(aspect);
  }

  getCamera(): THREE.OrthographicCamera {
    return this.camera;
  }

  getTarget(): THREE.Vector3 {
    return this.target;
  }

  computeBounds(state: GameState): CameraBounds {
    return computeCameraBounds(state);
  }

  update(state: GameState, hitEvent = false, koEvent = false): void {
    const b = this.computeBounds(state);
    let cx = (b.minX + b.maxX) / 2;
    let cy = (b.minY + b.maxY) / 2;
    if (!Number.isFinite(cx) || !Number.isFinite(cy)) {
      cx = DEFAULT_TARGET.x;
      cy = DEFAULT_TARGET.y;
    }
    const spanX = Math.max(120, b.maxX - b.minX);
    const spanY = Math.max(80, b.maxY - b.minY);
    const pulse = computeCinematicPulse(hitEvent, koEvent, state.hitstopFrames);
    const launchBias = launchCameraBias(state);
    let desiredZoom = Math.max(spanX / 1.6, spanY / 1.2) * (1.1 + pulse.zoomBias + launchBias);
    desiredZoom = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, desiredZoom));

    if (this.smooth) {
      this.target.x += (cx - this.target.x) * 0.12;
      this.target.y += (cy - this.target.y) * 0.12;
      this.zoom += (desiredZoom - this.zoom) * 0.08;
    } else {
      this.target.set(cx, cy, 0);
      this.zoom = desiredZoom;
    }

    const shakeX = this.shake > 0 ? (Math.random() - 0.5) * this.shake : 0;
    const shakeY = this.shake > 0 ? (Math.random() - 0.5) * this.shake : 0;
    if (pulse.shake > this.shake) this.shake = pulse.shake;
    if (koEvent) this.shake = Math.max(this.shake, 12);
    this.shake *= 0.85;

    this.camera.position.set(this.target.x + shakeX, this.target.y + shakeY, 800);
    this.camera.lookAt(this.target.x, this.target.y, 0);
    this.camera.left = -this.zoom;
    this.camera.right = this.zoom;
    this.camera.top = this.zoom / this.aspect;
    this.camera.bottom = -this.zoom / this.aspect;
    this.camera.updateProjectionMatrix();
  }

  resize(aspect: number): void {
    this.aspect = aspect;
    this.camera.left = -this.zoom;
    this.camera.right = this.zoom;
    this.camera.top = this.zoom / this.aspect;
    this.camera.bottom = -this.zoom / this.aspect;
    this.camera.updateProjectionMatrix();
  }

  resetToStageDefault(): void {
    this.target.copy(DEFAULT_TARGET);
    this.zoom = DEFAULT_ZOOM;
  }
}
