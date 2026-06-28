import type { GameConfig, GameState } from "@anime-aggressors/game-core";
import * as THREE from "three";
import { ThreeGameRenderer } from "./ThreeGameRenderer.ts";

export type BattleSceneBootResult = {
  ok: boolean;
  sceneObjectCount: number;
  stageLoaded: boolean;
  fightersLoaded: number;
  warnings: string[];
  error?: string;
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

  if (!stageLoaded) warnings.push("stage not loaded");
  if (fightersLoaded < 2) warnings.push(`only ${fightersLoaded} fighter views`);
  if (sceneObjectCount === 0) warnings.push("scene has zero meshes");

  const ok = stageLoaded && fightersLoaded >= 2 && sceneObjectCount > 0 && !error;

  const result: BattleSceneBootResult = {
    ok,
    sceneObjectCount,
    stageLoaded,
    fightersLoaded,
    warnings,
    error,
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
