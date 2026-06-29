import * as THREE from "three";
import { buildStageModel } from "../stages/StageModelFactory.ts";

export type StagePreviewSceneResult = {
  group: THREE.Group;
  stageId: string;
  objectCount: number;
};

export function buildStagePreviewScene(stageId: string): StagePreviewSceneResult {
  const built = buildStageModel(stageId);
  let objectCount = 0;
  built.group.traverse((o) => {
    if (o instanceof THREE.Mesh) objectCount += 1;
  });
  return { group: built.group, stageId: built.stageId, objectCount };
}

export function setupStagePreviewLighting(scene: THREE.Scene): void {
  scene.add(new THREE.AmbientLight(0x556688, 0.55));
  const key = new THREE.DirectionalLight(0xfff0dd, 1.1);
  key.position.set(200, 400, 300);
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x88aaff, 0.5);
  rim.position.set(-300, 200, -200);
  scene.add(rim);
}
