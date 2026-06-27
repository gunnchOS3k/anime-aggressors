import * as THREE from "three";

export function createPreviewCamera(): THREE.PerspectiveCamera {
  const camera = new THREE.PerspectiveCamera(42, 1, 0.1, 50);
  camera.position.set(0, 1.35, 4.2);
  camera.lookAt(0, 1.1, 0);
  return camera;
}

export function updatePreviewCamera(camera: THREE.PerspectiveCamera, aspect: number, zoom = 1): void {
  camera.aspect = aspect;
  camera.position.z = 4.2 / zoom;
  camera.updateProjectionMatrix();
}
