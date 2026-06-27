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
  extras: THREE.Object3D[];
  aura: THREE.Mesh;
};

export function buildLowPolyHumanoid(appearance: FighterAppearance): LowPolyHumanoidParts {
  const root = new THREE.Group();
  const bodyMat = appearance.primaryHex;
  const accent = appearance.accentHex;
  const dark = appearance.darkHex;
  const extras: THREE.Object3D[] = [];

  const torsoScale = silhouetteTorso(appearance.silhouette);
  const torso = createToonMesh(new THREE.BoxGeometry(0.9 * torsoScale.w, 1.05, 0.45 * torsoScale.d), bodyMat, accent);
  torso.position.y = 1.05;
  addOutline(torso);

  const headSize = appearance.silhouette === "heavy" ? 0.42 : appearance.silhouette === "lean" ? 0.34 : 0.38;
  const head = createToonMesh(new THREE.BoxGeometry(headSize, headSize, headSize * 0.9), accent);
  head.position.y = 1.75;
  addOutline(head);

  if (appearance.parts.hair === "angular" || appearance.parts.hair === "tufts") {
    const spike = createToonMesh(new THREE.BoxGeometry(0.12, 0.35, 0.08), accent);
    spike.position.set(0, 2.05, 0.05);
    spike.rotation.z = appearance.parts.hair === "tufts" ? 0.2 : -0.15;
    extras.push(spike);
    root.add(spike);
  }

  if (appearance.parts.hood) {
    const hood = createToonMesh(new THREE.BoxGeometry(headSize * 1.3, 0.25, headSize), dark);
    hood.position.set(0, 1.88, -0.05);
    extras.push(hood);
    root.add(hood);
  }

  const armLen = appearance.silhouette === "lean" ? 0.55 : appearance.silhouette === "heavy" ? 0.72 : 0.65;
  const armW = appearance.parts.gauntlets === "block" ? 0.32 : 0.22;
  const leftArm = createToonMesh(new THREE.BoxGeometry(armW, armLen, armW), dark);
  leftArm.position.set(-0.62 * torsoScale.w, 1.15, 0);
  const rightArm = createToonMesh(new THREE.BoxGeometry(armW, armLen, armW), dark);
  rightArm.position.set(0.62 * torsoScale.w, 1.15, 0);

  if (appearance.parts.gauntlets) {
    const glow = appearance.parts.gauntlets === "flame" ? appearance.vfx.hitSpark : accent;
    const gauntL = createToonMesh(new THREE.BoxGeometry(0.28, 0.22, 0.28), glow);
    gauntL.position.set(-0.62 * torsoScale.w, 0.82, 0.05);
    const gauntR = gauntL.clone();
    gauntR.position.x = 0.62 * torsoScale.w;
    extras.push(gauntL, gauntR);
    root.add(gauntL, gauntR);
  }

  const legH = appearance.silhouette === "heavy" ? 0.75 : 0.85;
  const bootH = appearance.parts.heavyBoots ? 0.18 : 0;
  const leftLeg = createToonMesh(new THREE.BoxGeometry(0.28, legH, 0.28), dark);
  leftLeg.position.set(-0.28, 0.38 + bootH * 0.5, 0);
  const rightLeg = createToonMesh(new THREE.BoxGeometry(0.28, legH, 0.28), dark);
  rightLeg.position.set(0.28, 0.38 + bootH * 0.5, 0);

  if (appearance.parts.heavyBoots) {
    const bootL = createToonMesh(new THREE.BoxGeometry(0.34, bootH, 0.38), accent);
    bootL.position.set(-0.28, bootH * 0.5, 0.02);
    const bootR = bootL.clone();
    bootR.position.x = 0.28;
    extras.push(bootL, bootR);
    root.add(bootL, bootR);
  }

  if (appearance.parts.shoulderArmor) {
    const padL = createToonMesh(new THREE.BoxGeometry(0.35, 0.22, 0.35), accent);
    padL.position.set(-0.55 * torsoScale.w, 1.55, 0);
    const padR = padL.clone();
    padR.position.x = 0.55 * torsoScale.w;
    extras.push(padL, padR);
    root.add(padL, padR);
  }

  if (appearance.parts.jacket) {
    const jacket = createToonMesh(
      new THREE.BoxGeometry(1.0 * torsoScale.w, appearance.parts.jacket === "long-coat" ? 1.35 : 0.55, 0.5),
      dark,
    );
    jacket.position.set(0, appearance.parts.jacket === "long-coat" ? 0.95 : 1.35, -0.08);
    extras.push(jacket);
    root.add(jacket);
  }

  if (appearance.parts.mantle) {
    const mantle = createToonMesh(new THREE.BoxGeometry(1.15, 0.35, 0.55), accent);
    mantle.position.set(0, 1.65, -0.12);
    extras.push(mantle);
    root.add(mantle);
  }

  if (appearance.parts.wingSleeves) {
    const sleeveL = createToonMesh(new THREE.BoxGeometry(0.1, 0.5, 0.55), accent);
    sleeveL.position.set(-0.72 * torsoScale.w, 1.25, 0);
    sleeveL.rotation.z = 0.25;
    const sleeveR = sleeveL.clone();
    sleeveR.position.x = 0.72 * torsoScale.w;
    sleeveR.rotation.z = -0.25;
    extras.push(sleeveL, sleeveR);
    root.add(sleeveL, sleeveR);
  }

  const accessory = buildAccessory(appearance);
  if (accessory) root.add(accessory);

  if (appearance.parts.floatingBits) {
    for (let i = 0; i < 3; i++) {
      const stone = createToonMesh(new THREE.BoxGeometry(0.12, 0.12, 0.12), accent);
      stone.name = `orbit-stone-${i}`;
      stone.position.set(Math.cos(i * 2.1) * 0.75, 1.2 + i * 0.15, Math.sin(i * 2.1) * 0.75);
      extras.push(stone);
      root.add(stone);
    }
  }

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

  return { root, torso, head, leftArm, rightArm, leftLeg, rightLeg, accessory, extras, aura };
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
  const parts = appearance.parts;

  if (parts.scarf === "lightning" || parts.scarf === "sash") {
    const scarf = createToonMesh(new THREE.BoxGeometry(0.15, 0.9, 0.5), appearance.accentHex);
    scarf.name = "scarf";
    scarf.position.set(0, 1.5, -0.35);
    g.add(scarf);
    return g;
  }

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
      const cape = createToonMesh(
        new THREE.BoxGeometry(parts.cape === "asymmetric" ? 0.85 : 1.1, 1.2, 0.08),
        appearance.darkHex,
      );
      cape.position.set(parts.cape === "asymmetric" ? 0.12 : 0, 1.05, -0.32);
      g.add(cape);
      break;
    }
    default:
      return g.children.length ? g : null;
  }
  return g.children.length ? g : null;
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
