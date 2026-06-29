import type { DefaultFighterId } from "@anime-aggressors/game-core";
import { normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import type { AnimPose } from "./FighterAnimator.ts";

export type IdleAnimFlavor = {
  bobAmp: number;
  bobSpeed: number;
  armL: number;
  armR: number;
  torsoRot: number;
  auraPulse: number;
  headTilt: number;
  legSpread: number;
  extraBob?: number;
};

const IDLE_FLAVORS: Record<string, IdleAnimFlavor> = {
  "ember-vale": { bobAmp: 0.05, bobSpeed: 2.2, armL: 0.18, armR: -0.12, torsoRot: -0.06, auraPulse: 0.35, headTilt: -0.04, legSpread: 0.06 },
  "rook-ironside": { bobAmp: 0.025, bobSpeed: 1.1, armL: 0.05, armR: -0.05, torsoRot: 0.02, auraPulse: 0.22, headTilt: 0, legSpread: 0.14 },
  "juno-spark": { bobAmp: 0.04, bobSpeed: 3.5, armL: 0.22, armR: -0.2, torsoRot: -0.08, auraPulse: 0.4, headTilt: 0.06, legSpread: 0.08, extraBob: 0.02 },
  "kaia-windrow": { bobAmp: 0.06, bobSpeed: 1.6, armL: 0.28, armR: -0.28, torsoRot: 0, auraPulse: 0.3, headTilt: 0, legSpread: 0.04 },
  "nix-calder": { bobAmp: 0.02, bobSpeed: 0.9, armL: 0.08, armR: -0.08, torsoRot: 0.04, auraPulse: 0.28, headTilt: 0.03, legSpread: 0.1 },
  "orion-vell": { bobAmp: 0.035, bobSpeed: 1.4, armL: 0.35, armR: -0.1, torsoRot: -0.05, auraPulse: 0.32, headTilt: -0.02, legSpread: 0.05 },
  "vesper-nyx": { bobAmp: 0.03, bobSpeed: 2.8, armL: 0.15, armR: -0.15, torsoRot: 0.03, auraPulse: 0.38, headTilt: 0.05, legSpread: 0.06 },
};

export function idleFlavorForFighter(fighterId: string): IdleAnimFlavor {
  const id = normalizeDefaultFighterId(fighterId);
  return IDLE_FLAVORS[id] ?? IDLE_FLAVORS["ember-vale"]!;
}

export function applyIdleFlavor(pose: AnimPose, fighterId: string, frame: number): AnimPose {
  const t = frame * 0.08;
  const f = idleFlavorForFighter(fighterId);
  pose.bob = Math.sin(t * f.bobSpeed) * f.bobAmp + (f.extraBob ? Math.sin(t * 6) * f.extraBob : 0);
  pose.armSwingL = f.armL + Math.sin(t * f.bobSpeed) * 0.08;
  pose.armSwingR = f.armR - Math.sin(t * f.bobSpeed) * 0.08;
  pose.torsoRotZ = f.torsoRot;
  pose.headTilt = f.headTilt;
  pose.legSpread = f.legSpread;
  pose.auraOpacity = f.auraPulse + Math.sin(t * 2) * 0.08;
  return pose;
}

export function listFightersWithIdleAnimation(): DefaultFighterId[] {
  return Object.keys(IDLE_FLAVORS) as DefaultFighterId[];
}
