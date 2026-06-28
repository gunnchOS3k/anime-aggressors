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
  const torsoDepth = 0.58 * torsoScale.d;
  const torso = createToonMesh(
    new THREE.BoxGeometry(0.92 * torsoScale.w, 1.08, torsoDepth),
    bodyMat,
    accent,
  );
  torso.position.y = 1.05;
  addOutline(torso);

  const headSize = appearance.silhouette === "heavy" ? 0.44 : appearance.silhouette === "lean" ? 0.36 : 0.4;
  const head = createToonMesh(new THREE.SphereGeometry(headSize, 10, 10), accent);
  head.position.y = 1.78;
  addOutline(head);

  if (appearance.parts.hair === "angular" || appearance.parts.hair === "tufts") {
    const spike = createToonMesh(new THREE.BoxGeometry(0.14, 0.38, 0.12), accent);
    spike.position.set(0, 2.08, 0.06);
    spike.rotation.z = appearance.parts.hair === "tufts" ? 0.2 : -0.15;
    extras.push(spike);
    root.add(spike);
  }

  if (appearance.parts.hood) {
    const hood = createToonMesh(new THREE.BoxGeometry(headSize * 1.35, 0.28, headSize * 1.1), dark);
    hood.position.set(0, 1.9, -0.06);
    extras.push(hood);
    root.add(hood);
  }

  const armLen = appearance.silhouette === "lean" ? 0.58 : appearance.silhouette === "heavy" ? 0.76 : 0.68;
  const armW = appearance.parts.gauntlets === "block" ? 0.34 : 0.24;
  const armDepth = 0.26;
  const leftArm = createToonMesh(new THREE.BoxGeometry(armW, armLen, armDepth), dark);
  leftArm.position.set(-0.64 * torsoScale.w, 1.15, 0.04);
  const rightArm = createToonMesh(new THREE.BoxGeometry(armW, armLen, armDepth), dark);
  rightArm.position.set(0.64 * torsoScale.w, 1.15, 0.04);

  const handL = createToonMesh(new THREE.BoxGeometry(0.2, 0.2, 0.2), accent);
  handL.position.set(-0.64 * torsoScale.w, 0.78, 0.06);
  const handR = handL.clone();
  handR.position.x = 0.64 * torsoScale.w;
  extras.push(handL, handR);
  root.add(handL, handR);

  if (appearance.parts.gauntlets) {
    const glow = appearance.parts.gauntlets === "flame" ? appearance.vfx.hitSpark : accent;
    const gauntL = createToonMesh(new THREE.BoxGeometry(0.32, 0.26, 0.32), glow);
    gauntL.position.set(-0.64 * torsoScale.w, 0.82, 0.1);
    const gauntR = gauntL.clone();
    gauntR.position.x = 0.64 * torsoScale.w;
    extras.push(gauntL, gauntR);
    root.add(gauntL, gauntR);
  }

  const legH = appearance.silhouette === "heavy" ? 0.78 : 0.88;
  const bootH = appearance.parts.heavyBoots ? 0.2 : 0;
  const legDepth = 0.3;
  const leftLeg = createToonMesh(new THREE.BoxGeometry(0.3, legH, legDepth), dark);
  leftLeg.position.set(-0.3, 0.4 + bootH * 0.5, 0.02);
  const rightLeg = createToonMesh(new THREE.BoxGeometry(0.3, legH, legDepth), dark);
  rightLeg.position.set(0.3, 0.4 + bootH * 0.5, 0.02);

  const footL = createToonMesh(new THREE.BoxGeometry(0.34, 0.14, 0.38), dark);
  footL.position.set(-0.3, 0.08 + bootH, 0.04);
  const footR = footL.clone();
  footR.position.x = 0.3;
  extras.push(footL, footR);
  root.add(footL, footR);

  if (appearance.parts.heavyBoots) {
    const bootL = createToonMesh(new THREE.BoxGeometry(0.38, bootH, 0.42), accent);
    bootL.position.set(-0.3, bootH * 0.5, 0.04);
    const bootR = bootL.clone();
    bootR.position.x = 0.3;
    extras.push(bootL, bootR);
    root.add(bootL, bootR);
  }

  if (appearance.parts.shoulderArmor) {
    const padL = createToonMesh(new THREE.BoxGeometry(0.38, 0.24, 0.38), accent);
    padL.position.set(-0.58 * torsoScale.w, 1.58, 0.02);
    const padR = padL.clone();
    padR.position.x = 0.58 * torsoScale.w;
    extras.push(padL, padR);
    root.add(padL, padR);
  }

  if (appearance.parts.jacket) {
    const jacket = createToonMesh(
      new THREE.BoxGeometry(1.02 * torsoScale.w, appearance.parts.jacket === "long-coat" ? 1.38 : 0.58, 0.58),
      dark,
    );
    jacket.position.set(0, appearance.parts.jacket === "long-coat" ? 0.95 : 1.38, -0.1);
    extras.push(jacket);
    root.add(jacket);
  }

  if (appearance.parts.mantle) {
    const mantle = createToonMesh(new THREE.BoxGeometry(1.2, 0.38, 0.62), accent);
    mantle.position.set(0, 1.68, -0.14);
    extras.push(mantle);
    root.add(mantle);
  }

  if (appearance.parts.wingSleeves) {
    const sleeveL = createToonMesh(new THREE.BoxGeometry(0.12, 0.55, 0.6), accent);
    sleeveL.position.set(-0.74 * torsoScale.w, 1.28, 0.02);
    sleeveL.rotation.z = 0.25;
    const sleeveR = sleeveL.clone();
    sleeveR.position.x = 0.74 * torsoScale.w;
    sleeveR.rotation.z = -0.25;
    extras.push(sleeveL, sleeveR);
    root.add(sleeveL, sleeveR);
  }

  const accessory = buildAccessory(appearance);
  if (accessory) root.add(accessory);

  if (appearance.parts.floatingBits) {
    for (let i = 0; i < 3; i++) {
      const stone = createToonMesh(new THREE.BoxGeometry(0.14, 0.14, 0.14), accent);
      stone.name = `orbit-stone-${i}`;
      stone.position.set(Math.cos(i * 2.1) * 0.8, 1.25 + i * 0.15, Math.sin(i * 2.1) * 0.8);
      extras.push(stone);
      root.add(stone);
    }
  }

  const aura = new THREE.Mesh(
    new THREE.RingGeometry(0.58, 0.82, 28),
    new THREE.MeshBasicMaterial({
      color: appearance.vfx.aura,
      transparent: true,
      opacity: 0.28,
      side: THREE.DoubleSide,
    }),
  );
  aura.rotation.x = -Math.PI / 2;
  aura.position.y = 0.05;

  root.add(torso, head, leftArm, rightArm, leftLeg, rightLeg, aura);

  return { root, torso, head, leftArm, rightArm, leftLeg, rightLeg, accessory, extras, aura };
}

function silhouetteTorso(kind: FighterAppearance["silhouette"]): { w: number; d: number } {
  switch (kind) {
    case "angular":
      return { w: 1.08, d: 1.05 };
    case "sleek":
      return { w: 0.92, d: 1.12 };
    case "lean":
      return { w: 0.82, d: 0.95 };
    case "heavy":
      return { w: 1.26, d: 1.18 };
  }
}

function buildAccessory(appearance: FighterAppearance): THREE.Object3D | null {
  const g = new THREE.Group();
  const parts = appearance.parts;

  if (parts.scarf === "lightning" || parts.scarf === "sash") {
    const scarf = createToonMesh(new THREE.BoxGeometry(0.16, 0.95, 0.55), appearance.accentHex);
    scarf.name = "scarf";
    scarf.position.set(0, 1.52, -0.38);
    g.add(scarf);
    return g;
  }

  switch (appearance.accessory) {
    case "blade": {
      const blade = createToonMesh(new THREE.BoxGeometry(0.1, 0.95, 0.2), appearance.accentHex, appearance.vfx.hitSpark);
      blade.position.set(0.78, 1.22, 0.22);
      blade.rotation.z = -0.4;
      g.add(blade);
      break;
    }
    case "scarf": {
      const scarf = createToonMesh(new THREE.BoxGeometry(0.16, 0.95, 0.55), appearance.accentHex);
      scarf.position.set(0, 1.52, -0.38);
      g.add(scarf);
      break;
    }
    case "wings": {
      const wingL = createToonMesh(new THREE.BoxGeometry(0.1, 0.58, 0.48), appearance.accentHex);
      wingL.position.set(-0.58, 1.38, -0.12);
      wingL.rotation.z = 0.35;
      const wingR = wingL.clone();
      wingR.position.x = 0.58;
      wingR.rotation.z = -0.35;
      g.add(wingL, wingR);
      break;
    }
    case "cape": {
      const cape = createToonMesh(
        new THREE.BoxGeometry(parts.cape === "asymmetric" ? 0.88 : 1.15, 1.25, 0.12),
        appearance.darkHex,
      );
      cape.position.set(parts.cape === "asymmetric" ? 0.12 : 0, 1.08, -0.36);
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
