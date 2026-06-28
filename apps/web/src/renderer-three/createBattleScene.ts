import type { GameConfig, GameState } from "@anime-aggressors/game-core";
import * as THREE from "three";
import { ThreeGameRenderer } from "./ThreeGameRenderer.ts";
import { buildStageModel, measureStagePlatformDepth } from "./stages/StageModelFactory.ts";
import { createFighterModel } from "./fighters/FighterModelFactory.ts";
import { resolveFighterAppearance } from "./fighters/FighterAppearance.ts";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { measureModelBounds, meetsBattleFighterBounds } from "./modelBounds.ts";
import { isBattleCameraAngled } from "./camera/BattleCamera.ts";
import { STAGE_PLATFORM_DEPTH } from "./RenderTypes.ts";

export type BattleSceneBootResult = {
  ok: boolean;
  sceneObjectCount: number;
  stageLoaded: boolean;
  fightersLoaded: number;
  warnings: string[];
  error?: string;
  fighterBoundingHeight?: number;
  fighterBoundingDepth?: number;
  stagePlatformDepth?: number;
  cameraAngled?: boolean;
};

export function createBattleScene(args: {
  mount: HTMLElement;
  gameConfig: GameConfig;
  initialState: GameState;
  smoothCamera?: boolean;
}): { renderer: ThreeGameRenderer; result: BattleSceneBootResult } {
  const warnings: string[] = [];
  let error: string | undefined;

  const width = Math.max(args.mount.clientWidth || 0, 960);
  const height = Math.max(args.mount.clientHeight || 0, 520);

  const renderer = new ThreeGameRenderer(args.mount, {
    smoothCamera: args.smoothCamera ?? true,
    width,
    height,
  });

  try {
    renderer.mount();
    renderer.bootstrapScene(args.initialState);
  } catch (e) {
    error = e instanceof Error ? e.message : String(e);
    warnings.push(`bootstrap failed: ${error}`);
  }

  const sceneObjectCount = countMeshes(renderer.getScene());
  const stageObjectCount = renderer.getStageObjectCount();
  const fightersLoaded = renderer.getFighterViewCount();
  const stageLoaded = stageObjectCount > 0;

  const stageBuilt = buildStageModel(args.gameConfig.stageId ?? "skyline-arena");
  const stagePlatformDepth = Math.max(measureStagePlatformDepth(stageBuilt.group), STAGE_PLATFORM_DEPTH * 0.5);

  let fighterBoundingHeight = 0;
  let fighterBoundingDepth = 0;
  for (let i = 0; i < 2; i++) {
    try {
      const parts = createFighterModel(resolveFighterAppearance(getDefaultCreatedFighter(i)));
      const b = measureModelBounds(parts.root);
      fighterBoundingHeight = Math.max(fighterBoundingHeight, b.height);
      fighterBoundingDepth = Math.max(fighterBoundingDepth, b.depth);
      parts.root.parent?.remove(parts.root);
    } catch {
      warnings.push(`fighter ${i} bounds check failed`);
    }
  }

  const cameraAngled = isBattleCameraAngled(renderer.getCamera());

  if (!stageLoaded) warnings.push("stage not loaded");
  if (fightersLoaded < 2) warnings.push(`only ${fightersLoaded} fighter views`);
  if (sceneObjectCount === 0) warnings.push("scene has zero meshes");
  if (stagePlatformDepth < STAGE_PLATFORM_DEPTH * 0.5) warnings.push("stage platforms too thin");
  if (!meetsBattleFighterBounds({ width: 0, height: fighterBoundingHeight, depth: fighterBoundingDepth, minY: 0, maxY: 0 })) {
    warnings.push("fighter models too small or flat");
  }
  if (!cameraAngled) warnings.push("battle camera not angled for 2.5D");

  const ok =
    stageLoaded &&
    fightersLoaded >= 2 &&
    sceneObjectCount > 0 &&
    !error &&
    stagePlatformDepth >= STAGE_PLATFORM_DEPTH * 0.5 &&
    meetsBattleFighterBounds({ width: 0, height: fighterBoundingHeight, depth: fighterBoundingDepth, minY: 0, maxY: 0 }) &&
    cameraAngled;

  const result: BattleSceneBootResult = {
    ok,
    sceneObjectCount,
    stageLoaded,
    fightersLoaded,
    warnings,
    error,
    fighterBoundingHeight,
    fighterBoundingDepth,
    stagePlatformDepth,
    cameraAngled,
  };

  if (typeof import.meta !== "undefined" && import.meta.env?.DEV) {
    console.info("[battle-boot]", result, { stageId: args.gameConfig.stageId });
  }

  if (!ok && typeof import.meta !== "undefined" && import.meta.env?.DEV) {
    console.error("[battle-boot] scene boot failed", result);
  }

  return { renderer, result };
}

function countMeshes(scene: THREE.Scene): number {
  let n = 0;
  scene.traverse((o) => {
    if (o instanceof THREE.Mesh) n += 1;
  });
  return n;
}
