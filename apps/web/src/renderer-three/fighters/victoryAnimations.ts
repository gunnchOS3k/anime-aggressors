import { normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import type { AnimPose } from "./FighterAnimator.ts";

export type VictoryAnimFlavor = {
  torsoRot: number;
  armR: number;
  armL: number;
  bob: number;
  headTilt: number;
  auraOpacity: number;
  legSpread: number;
};

const VICTORY_FLAVORS: Record<string, (t: number) => VictoryAnimFlavor> = {
  "ember-vale": (t) => ({
    torsoRot: -0.2,
    armR: -1.6 - Math.sin(t * 4) * 0.15,
    armL: 0.5,
    bob: 0.08 + Math.sin(t * 3) * 0.04,
    headTilt: -0.1,
    auraOpacity: 0.75 + Math.sin(t * 5) * 0.15,
    legSpread: 0.12,
  }),
  "rook-ironside": (t) => ({
    torsoRot: 0.05,
    armR: -0.35,
    armL: -0.35,
    bob: -0.06 + (t > 0.3 ? Math.sin(t * 2) * 0.02 : -0.1 * (1 - t)),
    headTilt: 0,
    auraOpacity: 0.55 + (t > 0.25 ? 0.25 : 0),
    legSpread: 0.2,
  }),
  "juno-spark": (t) => ({
    torsoRot: -0.15 + Math.sin(t * 8) * 0.08,
    armR: -0.9,
    armL: 0.7,
    bob: Math.sin(t * 6) * 0.06,
    headTilt: 0.08,
    auraOpacity: 0.65,
    legSpread: 0.1,
  }),
  "kaia-windrow": (t) => ({
    torsoRot: 0,
    armR: -0.5,
    armL: -0.5,
    bob: 0.12 + Math.sin(t * 1.5) * 0.05,
    headTilt: 0,
    auraOpacity: 0.5 + Math.sin(t * 2) * 0.1,
    legSpread: 0.04,
  }),
  "nix-calder": (t) => ({
    torsoRot: 0.08,
    armR: -0.4,
    armL: -0.4,
    bob: 0.02,
    headTilt: 0.05,
    auraOpacity: 0.45 + Math.sin(t * 1.2) * 0.08,
    legSpread: 0.14,
  }),
  "orion-vell": (t) => ({
    torsoRot: -0.08,
    armR: 0.6,
    armL: 0.9,
    bob: Math.sin(t * 1.8) * 0.03,
    headTilt: -0.05,
    auraOpacity: 0.6 + Math.sin(t * 2.5) * 0.12,
    legSpread: 0.08,
  }),
  "vesper-nyx": (t) => ({
    torsoRot: 0.1 * Math.sin(t * 4),
    armR: -0.55,
    armL: -0.55,
    bob: Math.sin(t * 5) * 0.04,
    headTilt: 0.06,
    auraOpacity: 0.5 + Math.abs(Math.sin(t * 6)) * 0.25,
    legSpread: 0.06,
  }),
};

export function victoryFlavorForFighter(fighterId: string, frame: number): VictoryAnimFlavor {
  const id = normalizeDefaultFighterId(fighterId);
  const fn = VICTORY_FLAVORS[id] ?? VICTORY_FLAVORS["ember-vale"]!;
  const t = (frame % 120) / 120;
  return fn(t);
}

export function applyVictoryPose(pose: AnimPose, fighterId: string, frame: number): AnimPose {
  const v = victoryFlavorForFighter(fighterId, frame);
  pose.torsoRotZ = v.torsoRot;
  pose.armSwingR = v.armR;
  pose.armSwingL = v.armL;
  pose.bob = v.bob;
  pose.headTilt = v.headTilt;
  pose.auraOpacity = v.auraOpacity;
  pose.legSpread = v.legSpread;
  return pose;
}

export function listFightersWithVictoryAnimation(): string[] {
  return Object.keys(VICTORY_FLAVORS);
}

export function victorySubtitleForFighter(fighterId: string): string {
  const id = normalizeDefaultFighterId(fighterId);
  const subtitles: Record<string, string> = {
    "ember-vale": "Flame Victory",
    "rook-ironside": "Impact Victory",
    "juno-spark": "Volt Victory",
    "kaia-windrow": "Gale Victory",
    "nix-calder": "Frost Victory",
    "orion-vell": "Gravity Victory",
    "vesper-nyx": "Void Victory",
  };
  return subtitles[id] ?? "Victory";
}
