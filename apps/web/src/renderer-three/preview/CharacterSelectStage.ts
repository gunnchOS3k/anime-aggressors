import * as THREE from "three";
import { createNeonMaterial, createStageMaterial } from "../materials/AnimeMaterialLibrary.ts";

export function createStageBackdrop(accentHex = 0x7744cc): THREE.Group {
  const stage = new THREE.Group();

  const platform = new THREE.Mesh(
    new THREE.CylinderGeometry(1.35, 1.55, 0.28, 32),
    createStageMaterial(0x1a1a2e),
  );
  platform.position.y = -0.12;
  platform.receiveShadow = true;
  stage.add(platform);

  const ring = new THREE.Mesh(new THREE.TorusGeometry(1.55, 0.06, 12, 48), createNeonMaterial(accentHex));
  ring.rotation.x = Math.PI / 2;
  ring.position.y = 0.02;
  stage.add(ring);

  const innerRing = new THREE.Mesh(
    new THREE.TorusGeometry(1.15, 0.03, 8, 32),
    createNeonMaterial(accentHex),
  );
  innerRing.rotation.x = Math.PI / 2;
  innerRing.position.y = 0.04;
  stage.add(innerRing);

  const backdrop = new THREE.Mesh(
    new THREE.PlaneGeometry(9, 5),
    new THREE.MeshBasicMaterial({ color: 0x0a0a18, transparent: true, opacity: 0.75 }),
  );
  backdrop.position.set(0, 2.2, -2.8);
  stage.add(backdrop);

  const glow = new THREE.Mesh(
    new THREE.PlaneGeometry(6, 3),
    new THREE.MeshBasicMaterial({ color: accentHex, transparent: true, opacity: 0.12 }),
  );
  glow.position.set(0, 1.4, -2.2);
  stage.add(glow);

  return stage;
}

export function setupPreviewSceneLighting(scene: THREE.Scene): void {
  scene.add(new THREE.AmbientLight(0x556688, 0.65));
  const key = new THREE.DirectionalLight(0xfff0dd, 1.25);
  key.position.set(2.5, 4.5, 5);
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x88aaff, 0.75);
  rim.position.set(-3, 2.5, -2);
  scene.add(rim);
  const fill = new THREE.DirectionalLight(0xcc8866, 0.35);
  fill.position.set(0, 1, 4);
  scene.add(fill);
}
