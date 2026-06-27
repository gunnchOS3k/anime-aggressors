import * as THREE from "three";
import type { PreviewAnimationId } from "@anime-aggressors/game-core";
import type { LowPolyHumanoidParts } from "../fighters/LowPolyHumanoid.ts";

export type PreviewAnimState = {
  torsoRotZ: number;
  torsoScaleY: number;
  headTilt: number;
  armSwingL: number;
  armSwingR: number;
  bob: number;
  rootY: number;
  rootX: number;
  auraOpacity: number;
  rootOpacity: number;
  facing: number;
};

const IDLE: PreviewAnimState = {
  torsoRotZ: 0,
  torsoScaleY: 1,
  headTilt: 0,
  armSwingL: 0,
  armSwingR: 0,
  bob: 0,
  rootY: 0,
  rootX: 0,
  auraOpacity: 0.22,
  rootOpacity: 1,
  facing: 1,
};

export function computePreviewAnimation(
  animationId: PreviewAnimationId | undefined,
  time: number,
  phase: "idle" | "hover" | "select" = "hover",
): PreviewAnimState {
  const t = time * 0.001;
  const base = { ...IDLE, bob: Math.sin(t * 2) * 0.03, auraOpacity: 0.25 + Math.sin(t * 3) * 0.08 };

  if (phase === "select") {
    base.torsoScaleY = 0.92;
    base.bob = 0.08;
    base.auraOpacity = 0.55;
  }

  switch (animationId) {
    case "flame-gauntlet-ignite":
      base.armSwingR = -0.9 + Math.sin(t * 4) * 0.15;
      base.torsoRotZ = -0.2;
      base.auraOpacity = 0.45 + Math.sin(t * 6) * 0.15;
      break;
    case "impact-stomp":
      base.bob = Math.abs(Math.sin(t * 2)) * -0.06;
      base.torsoScaleY = 1 + Math.sin(t * 2) * 0.06;
      base.armSwingL = 0.3;
      base.armSwingR = 0.3;
      base.auraOpacity = 0.5;
      break;
    case "volt-afterimage":
      base.rootX = Math.sin(t * 12) * 0.08;
      base.armSwingL = Math.sin(t * 8) * 0.4;
      base.armSwingR = -Math.sin(t * 8) * 0.4;
      base.rootOpacity = 0.85 + Math.sin(t * 16) * 0.15;
      break;
    case "gale-hover":
      base.rootY = 0.12 + Math.sin(t * 2) * 0.06;
      base.armSwingL = -0.5;
      base.armSwingR = -0.5;
      base.torsoRotZ = Math.sin(t) * 0.05;
      break;
    case "frost-mantle":
      base.torsoRotZ = 0.05;
      base.headTilt = -0.08;
      base.armSwingL = 0.15;
      base.armSwingR = 0.15;
      base.bob = Math.sin(t) * 0.02;
      base.auraOpacity = 0.35;
      break;
    case "gravity-orbit":
      base.armSwingR = -0.35;
      base.torsoRotZ = -0.1;
      base.auraOpacity = 0.4 + Math.sin(t * 2) * 0.1;
      break;
    case "void-afterimage":
      base.rootX = Math.sin(t * 5) * 0.12;
      base.rootOpacity = 0.7 + Math.abs(Math.sin(t * 4)) * 0.3;
      base.torsoRotZ = 0.15;
      break;
    default:
      break;
  }

  return base;
}

export function applyPreviewAnimation(parts: LowPolyHumanoidParts, state: PreviewAnimState): void {
  parts.torso.rotation.z = state.torsoRotZ;
  parts.torso.scale.y = state.torsoScaleY;
  parts.head.rotation.z = state.headTilt;
  parts.leftArm.rotation.x = state.armSwingL;
  parts.rightArm.rotation.x = state.armSwingR;
  parts.root.position.y = state.bob + state.rootY;
  parts.root.position.x = state.rootX;
  parts.root.rotation.y = state.facing > 0 ? 0.35 : Math.PI - 0.35;
  (parts.aura.material as THREE.MeshBasicMaterial).opacity = state.auraOpacity;
  parts.root.traverse((obj) => {
    if (obj instanceof THREE.Mesh && obj !== parts.aura) {
      const mat = obj.material as THREE.MeshToonMaterial;
      if (mat.transparent !== true) {
        mat.opacity = state.rootOpacity;
        mat.transparent = state.rootOpacity < 0.99;
      }
    }
  });

  parts.extras.forEach((obj) => {
    if (obj.name.startsWith("orbit-stone")) {
      const idx = Number(obj.name.split("-").pop());
      const orbitT = performance.now() * 0.001 + idx;
      obj.position.x = Math.cos(orbitT * 1.5 + idx) * 0.75;
      obj.position.z = Math.sin(orbitT * 1.5 + idx) * 0.75;
      obj.position.y = 1.2 + idx * 0.15 + Math.sin(orbitT * 2) * 0.05;
    }
    if (obj.name === "scarf") {
      obj.rotation.z = Math.sin(performance.now() * 0.002) * 0.2;
    }
  });
}

export function createPreviewVfxLayer(animationId: PreviewAnimationId | undefined): THREE.Group {
  const g = new THREE.Group();
  g.name = "preview-vfx";

  const ring = new THREE.Mesh(
    new THREE.RingGeometry(0.85, 1.05, 32),
    new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.15, side: THREE.DoubleSide }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.02;
  ring.name = "shock-ring";
  ring.visible = animationId === "impact-stomp";
  g.add(ring);

  return g;
}

export function updatePreviewVfx(vfx: THREE.Group, animationId: PreviewAnimationId | undefined, time: number): void {
  const t = time * 0.001;
  const ring = vfx.getObjectByName("shock-ring") as THREE.Mesh | undefined;
  if (ring) {
    ring.visible = animationId === "impact-stomp";
    if (ring.visible) {
      const scale = 1 + (Math.sin(t * 2) * 0.5 + 0.5) * 0.35;
      ring.scale.setScalar(scale);
      (ring.material as THREE.MeshBasicMaterial).opacity = 0.12 + Math.sin(t * 2) * 0.08;
    }
  }
}
