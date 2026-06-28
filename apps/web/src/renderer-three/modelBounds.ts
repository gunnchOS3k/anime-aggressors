import * as THREE from "three";

export type ModelBounds = {
  width: number;
  height: number;
  depth: number;
  minY: number;
  maxY: number;
};

export function measureModelBounds(root: THREE.Object3D): ModelBounds {
  const box = new THREE.Box3().setFromObject(root);
  if (box.isEmpty()) {
    return { width: 0, height: 0, depth: 0, minY: 0, maxY: 0 };
  }
  const size = box.getSize(new THREE.Vector3());
  return {
    width: size.x,
    height: size.y,
    depth: size.z,
    minY: box.min.y,
    maxY: box.max.y,
  };
}

export function meetsPreviewBounds(bounds: ModelBounds): boolean {
  return bounds.height >= 0.9 && bounds.depth >= 0.25;
}

export function meetsBattleFighterBounds(bounds: ModelBounds): boolean {
  return bounds.height >= 40 && bounds.depth >= 8;
}
