import * as THREE from "three";

export function createPreviewCamera(): THREE.PerspectiveCamera {
  const camera = new THREE.PerspectiveCamera(38, 1, 0.1, 50);
  camera.position.set(0, 2.2, 6);
  camera.lookAt(0, 1.2, 0);
  return camera;
}

export function updatePreviewCamera(camera: THREE.PerspectiveCamera, aspect: number): void {
  camera.aspect = aspect;
  camera.position.set(0, 2.2, 6);
  camera.lookAt(0, 1.2, 0);
  camera.updateProjectionMatrix();
}
