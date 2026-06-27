import * as THREE from "three";
import type { FighterAppearance } from "./FighterAppearance.ts";
import { createToonMesh, addOutline } from "../materials/AnimeMaterialLibrary.ts";

export type LowPolyHumanoidParts = {
  root: THREE.Group;
  torso: THREE.Mesh;
  head: THREE.Mesh;
  leftArm: THREE.Mesh;
  rightArm: THREE.Mesh;
  leftLeg: THREE.Mesh;
  rightLeg: THREE.Mesh;
  accessory: THREE.Object3D | null;
  aura: THREE.Mesh;
};

export function buildLowPolyHumanoid(appearance: FighterAppearance): LowPolyHumanoidParts {
  const root = new THREE.Group();
  const bodyMat = appearance.primaryHex;
  const accent = appearance.accentHex;
  const dark = appearance.darkHex;

  const torsoScale = silhouetteTorso(appearance.silhouette);
  const torso = createToonMesh(new THREE.BoxGeometry(0.9 * torsoScale.w, 1.05, 0.45 * torsoScale.d), bodyMat, accent);
  torso.position.y = 1.05;
  addOutline(torso);

  const headSize = appearance.silhouette === "heavy" ? 0.42 : appearance.silhouette === "lean" ? 0.34 : 0.38;
  const head = createToonMesh(new THREE.BoxGeometry(headSize, headSize, headSize * 0.9), accent);
  head.position.y = 1.75;
  addOutline(head);

  const armLen = appearance.silhouette === "lean" ? 0.55 : 0.65;
  const leftArm = createToonMesh(new THREE.BoxGeometry(0.22, armLen, 0.22), dark);
  leftArm.position.set(-0.62 * torsoScale.w, 1.15, 0);
  const rightArm = createToonMesh(new THREE.BoxGeometry(0.22, armLen, 0.22), dark);
  rightArm.position.set(0.62 * torsoScale.w, 1.15, 0);

  const legH = appearance.silhouette === "heavy" ? 0.75 : 0.85;
  const leftLeg = createToonMesh(new THREE.BoxGeometry(0.28, legH, 0.28), dark);
  leftLeg.position.set(-0.28, 0.38, 0);
  const rightLeg = createToonMesh(new THREE.BoxGeometry(0.28, legH, 0.28), dark);
  rightLeg.position.set(0.28, 0.38, 0);

  const accessory = buildAccessory(appearance);
  if (accessory) root.add(accessory);

  const aura = new THREE.Mesh(
    new THREE.RingGeometry(0.55, 0.75, 24),
    new THREE.MeshBasicMaterial({
      color: appearance.vfx.aura,
      transparent: true,
      opacity: 0.22,
      side: THREE.DoubleSide,
    }),
  );
  aura.rotation.x = -Math.PI / 2;
  aura.position.y = 0.05;

  root.add(torso, head, leftArm, rightArm, leftLeg, rightLeg, aura);
  root.scale.setScalar(appearance.scale);

  return { root, torso, head, leftArm, rightArm, leftLeg, rightLeg, accessory, aura };
}

function silhouetteTorso(kind: FighterAppearance["silhouette"]): { w: number; d: number } {
  switch (kind) {
    case "angular":
      return { w: 1.08, d: 0.95 };
    case "sleek":
      return { w: 0.92, d: 1.05 };
    case "lean":
      return { w: 0.82, d: 0.88 };
    case "heavy":
      return { w: 1.22, d: 1.1 };
  }
}

function buildAccessory(appearance: FighterAppearance): THREE.Object3D | null {
  const g = new THREE.Group();
  switch (appearance.accessory) {
    case "blade": {
      const blade = createToonMesh(new THREE.BoxGeometry(0.08, 0.9, 0.18), appearance.accentHex, appearance.vfx.hitSpark);
      blade.position.set(0.75, 1.2, 0.2);
      blade.rotation.z = -0.4;
      g.add(blade);
      break;
    }
    case "scarf": {
      const scarf = createToonMesh(new THREE.BoxGeometry(0.15, 0.9, 0.5), appearance.accentHex);
      scarf.position.set(0, 1.5, -0.35);
      g.add(scarf);
      break;
    }
    case "wings": {
      const wingL = createToonMesh(new THREE.BoxGeometry(0.08, 0.55, 0.45), appearance.accentHex);
      wingL.position.set(-0.55, 1.35, -0.15);
      wingL.rotation.z = 0.35;
      const wingR = wingL.clone();
      wingR.position.x = 0.55;
      wingR.rotation.z = -0.35;
      g.add(wingL, wingR);
      break;
    }
    case "cape": {
      const cape = createToonMesh(new THREE.BoxGeometry(1.1, 1.2, 0.08), appearance.darkHex);
      cape.position.set(0, 1.05, -0.32);
      g.add(cape);
      break;
    }
    default:
      return null;
  }
  return g;
}

export function disposeHumanoid(parts: LowPolyHumanoidParts): void {
  parts.root.traverse((obj) => {
    if (obj instanceof THREE.Mesh) {
      obj.geometry.dispose();
      if (Array.isArray(obj.material)) obj.material.forEach((m) => m.dispose());
      else obj.material.dispose();
    }
  });
}
