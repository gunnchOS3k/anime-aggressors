import * as THREE from "three";
import { createNeonMaterial, createStageMaterial } from "../materials/AnimeMaterialLibrary.ts";

export function createStageBackdrop(accentHex = 0x7744cc): THREE.Group {
  const stage = new THREE.Group();

  const floor = new THREE.Mesh(new THREE.CircleGeometry(2.2, 32), createStageMaterial(0x1a1a2e));
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  stage.add(floor);

  const ring = new THREE.Mesh(
    new THREE.RingGeometry(1.85, 2.05, 48),
    createNeonMaterial(accentHex),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.01;
  stage.add(ring);

  const backdrop = new THREE.Mesh(
    new THREE.PlaneGeometry(8, 4),
    new THREE.MeshBasicMaterial({
      color: 0x0a0a18,
      transparent: true,
      opacity: 0.85,
    }),
  );
  backdrop.position.set(0, 2, -2.5);
  stage.add(backdrop);

  const light = new THREE.DirectionalLight(0xffffff, 1.1);
  light.position.set(2, 4, 3);
  stage.add(light);
  stage.add(new THREE.AmbientLight(0x445566, 0.55));

  return stage;
}
