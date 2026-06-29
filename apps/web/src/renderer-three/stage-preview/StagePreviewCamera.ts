import * as THREE from "three";
import { STAGE_HEIGHT, STAGE_WIDTH } from "@anime-aggressors/game-core";
import { fpToWorld } from "../RenderTypes.ts";

export function createStagePreviewCamera(aspect = 16 / 9): THREE.PerspectiveCamera {
  const camera = new THREE.PerspectiveCamera(38, aspect, 1, 8000);
  positionStagePreviewCamera(camera);
  return camera;
}

export function positionStagePreviewCamera(camera: THREE.PerspectiveCamera): void {
  const cx = fpToWorld(STAGE_WIDTH / 2);
  const cy = fpToWorld(STAGE_HEIGHT * 0.62);
  camera.position.set(cx - 180, cy + 120, 420);
  camera.lookAt(cx, cy - 40, 0);
}

export function updateStagePreviewCamera(camera: THREE.PerspectiveCamera, aspect: number): void {
  camera.aspect = aspect;
  camera.updateProjectionMatrix();
}
