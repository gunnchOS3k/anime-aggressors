import * as THREE from "three";
import type { GameState } from "@anime-aggressors/game-core";
import { computeCameraBounds, type CameraBounds } from "./cameraBounds.js";
import { computeCinematicPulse, launchCameraBias } from "./camera/CinematicEffects.ts";

export type { CameraBounds };

export class CameraDirector {
  private camera: THREE.OrthographicCamera;
  private target = new THREE.Vector3(12, 5, 0);
  private zoom = 28;
  private smooth: boolean;
  private shake = 0;
  private aspect = 16 / 9;

  constructor(aspect: number, smooth = true) {
    this.smooth = smooth;
    this.aspect = aspect;
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 500);
    this.camera.position.set(0, 4, 40);
    this.camera.lookAt(0, 4, 0);
    this.resize(aspect);
  }

  getCamera(): THREE.OrthographicCamera {
    return this.camera;
  }

  computeBounds(state: GameState): CameraBounds {
    return computeCameraBounds(state);
  }

  update(state: GameState, hitEvent = false, koEvent = false): void {
    const b = this.computeBounds(state);
    const cx = (b.minX + b.maxX) / 2;
    const cy = (b.minY + b.maxY) / 2;
    const spanX = Math.max(18, b.maxX - b.minX);
    const spanY = Math.max(10, b.maxY - b.minY);
    const pulse = computeCinematicPulse(hitEvent, koEvent, state.hitstopFrames);
    const launchBias = launchCameraBias(state);
    const desiredZoom = Math.max(spanX / 2, spanY / 1.1) * (1.15 + pulse.zoomBias + launchBias);

    if (pulse.shake > this.shake) this.shake = pulse.shake;
    if (koEvent) this.shake = Math.max(this.shake, 1.0);

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
    this.shake *= 0.85;

    this.camera.position.set(this.target.x + shakeX, this.target.y + shakeY, 40);
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
}
