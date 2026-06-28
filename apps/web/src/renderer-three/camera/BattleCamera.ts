import * as THREE from "three";

/** 2.5D orthographic battle camera — angled down toward the stage. */
export const BATTLE_CAM_ELEVATION = 0.42;
export const BATTLE_CAM_DISTANCE = 0.72;

export function applyBattleCameraAngle(
  camera: THREE.OrthographicCamera,
  target: THREE.Vector3,
  zoom: number,
  shakeX = 0,
  shakeY = 0,
): void {
  const tx = target.x + shakeX;
  const ty = target.y + shakeY;
  camera.position.set(tx, ty + zoom * BATTLE_CAM_ELEVATION, zoom * BATTLE_CAM_DISTANCE);
  camera.up.set(0, 1, 0);
  camera.lookAt(tx, ty, 0);
}

export function isBattleCameraAngled(camera: THREE.OrthographicCamera): boolean {
  return camera.position.z > 50 && camera.position.y > camera.position.z * 0.2;
}
