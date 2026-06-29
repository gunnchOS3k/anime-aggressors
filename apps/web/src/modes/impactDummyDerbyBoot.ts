import type { CreatedFighter } from "@anime-aggressors/game-core";
import { buildStageModel } from "../renderer-three/stages/StageModelFactory.ts";
import {
  createFighterModel,
  countFighterMeshes,
  type LowPolyHumanoidParts,
} from "../renderer-three/fighters/FighterModelFactory.ts";
import { resolveFighterAppearance } from "../renderer-three/fighters/FighterAppearance.ts";
import { ImpactDummyView } from "../renderer-three/ImpactDummyView.ts";
import { KineticBatView } from "../renderer-three/KineticBatView.ts";
import { DistanceMarkerView } from "../renderer-three/DistanceMarkerView.ts";
import * as THREE from "three";

export type ImpactDummyDerbyBootResult = {
  ok: boolean;
  playerLoaded: boolean;
  dummyLoaded: boolean;
  batLoaded: boolean;
  runwayLoaded: boolean;
  cameraReady: boolean;
  errors: string[];
  stageObjectCount: number;
  playerMeshCount: number;
};

export type DerbyBootAssets = {
  fighterParts: LowPolyHumanoidParts;
  dummyView: ImpactDummyView;
  batView: KineticBatView;
  markers: DistanceMarkerView;
  stageGroup: THREE.Group;
};

export function bootImpactDummyDerby(fighter: CreatedFighter): {
  result: ImpactDummyDerbyBootResult;
  assets: DerbyBootAssets | null;
} {
  const errors: string[] = [];
  let fighterParts: LowPolyHumanoidParts | null = null;
  let playerMeshCount = 0;
  let stageObjectCount = 0;

  try {
    fighterParts = createFighterModel(resolveFighterAppearance(fighter));
    playerMeshCount = countFighterMeshes(fighterParts);
  } catch (e) {
    errors.push(`fighter load failed: ${e instanceof Error ? e.message : String(e)}`);
  }

  const dummyView = new ImpactDummyView();
  const dummyLoaded = dummyView.group.children.length > 0;

  const batView = new KineticBatView();
  const batLoaded = batView.group.children.length > 0;

  const markers = new DistanceMarkerView();

  let stageGroup: THREE.Group;
  try {
    const stage = buildStageModel("impact-platform");
    stageGroup = stage.group;
    stageObjectCount = stage.objectCount;
  } catch (e) {
    errors.push(`stage load failed: ${e instanceof Error ? e.message : String(e)}`);
    stageGroup = new THREE.Group();
    stageObjectCount = 0;
  }

  const runwayLoaded = stageObjectCount > 3;
  const playerLoaded = playerMeshCount >= 6 && fighterParts !== null;
  const cameraReady = runwayLoaded;

  if (!playerLoaded) errors.push("player not loaded");
  if (!dummyLoaded) errors.push("dummy not loaded");
  if (!batLoaded) errors.push("bat not loaded");
  if (!runwayLoaded) errors.push("runway not loaded");

  const ok = playerLoaded && dummyLoaded && batLoaded && runwayLoaded && cameraReady;

  return {
    result: {
      ok,
      playerLoaded,
      dummyLoaded,
      batLoaded,
      runwayLoaded,
      cameraReady,
      errors,
      stageObjectCount,
      playerMeshCount,
    },
    assets:
      fighterParts !== null
        ? { fighterParts, dummyView, batView, markers, stageGroup }
        : null,
  };
}

export function canDerbySimulate(boot: ImpactDummyDerbyBootResult): boolean {
  return boot.ok && boot.playerLoaded && boot.dummyLoaded && boot.runwayLoaded && boot.cameraReady;
}

export function shouldShowDerbyResults(state: {
  phase: string;
  totalHits: number;
  dummy: { damage: number; launched: boolean };
}): boolean {
  if (state.phase !== "results") return false;
  if (state.totalHits === 0 && state.dummy.damage === 0 && !state.dummy.launched) return false;
  return true;
}
