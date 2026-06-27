import * as THREE from "three";
import type { CreatedFighter, PreviewAnimationId } from "@anime-aggressors/game-core";
import { getDefaultFighterProfile, normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "../fighters/FighterAppearance.ts";
import { createFighterModel, destroyFighterModel, type LowPolyHumanoidParts } from "../fighters/FighterModelFactory.ts";
import { createStageBackdrop } from "./CharacterSelectStage.ts";
import { createPreviewCamera, updatePreviewCamera } from "./PreviewCamera.ts";
import {
  applyPreviewAnimation,
  computePreviewAnimation,
  createPreviewVfxLayer,
  updatePreviewVfx,
} from "./PreviewAnimationController.ts";

export type PreviewPhase = "idle" | "hover" | "select";

export class CharacterPreviewRenderer {
  readonly scene = new THREE.Scene();
  readonly camera: THREE.PerspectiveCamera;
  readonly renderer: THREE.WebGLRenderer;
  private stage: THREE.Group;
  private parts: LowPolyHumanoidParts | null = null;
  private vfx: THREE.Group;
  private animationId: PreviewAnimationId | undefined;
  private phase: PreviewPhase = "hover";
  private raf = 0;
  private accentHex = 0x7744cc;
  private appearanceKey = "";

  constructor(canvas: HTMLCanvasElement) {
    this.camera = createPreviewCamera();
    this.renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.stage = createStageBackdrop();
    this.scene.add(this.stage);
    this.vfx = createPreviewVfxLayer(undefined);
    this.scene.add(this.vfx);
    this.scene.fog = new THREE.Fog(0x0a0a18, 6, 14);
  }

  resize(width: number, height: number): void {
    this.renderer.setSize(width, height, false);
    updatePreviewCamera(this.camera, width / Math.max(height, 1));
  }

  setFighter(fighter: Pick<CreatedFighter, "id" | "name" | "size" | "color">, phase: PreviewPhase = "hover"): void {
    this.phase = phase;
    const normalizedId = normalizeDefaultFighterId(fighter.id);
    const profile = getDefaultFighterProfile(normalizedId);
    this.animationId = profile?.previewAnimation;
    const appearance = resolveFighterAppearance(fighter);
    this.accentHex = appearance.vfx.aura;
    const key = `${fighter.id}-${fighter.size}-${fighter.color}-${phase}`;
    if (key === this.appearanceKey && this.parts) return;
    this.appearanceKey = key;

    if (this.parts) {
      this.scene.remove(this.parts.root);
      destroyFighterModel(this.parts);
      this.parts = null;
    }

    this.parts = createFighterModel(appearance);
    this.scene.remove(this.stage);
    this.stage = createStageBackdrop(this.accentHex);
    this.scene.add(this.stage);
    this.scene.add(this.parts.root);

    this.scene.remove(this.vfx);
    this.vfx = createPreviewVfxLayer(this.animationId);
    this.scene.add(this.vfx);
  }

  setPhase(phase: PreviewPhase): void {
    this.phase = phase;
  }

  start(): void {
    if (this.raf) return;
    const tick = (time: number) => {
      this.raf = requestAnimationFrame(tick);
      this.renderFrame(time);
    };
    this.raf = requestAnimationFrame(tick);
  }

  stop(): void {
    if (this.raf) cancelAnimationFrame(this.raf);
    this.raf = 0;
  }

  renderFrame(time: number): void {
    if (this.parts) {
      const state = computePreviewAnimation(this.animationId, time, this.phase);
      applyPreviewAnimation(this.parts, state);
    }
    updatePreviewVfx(this.vfx, this.animationId, time);
    this.renderer.render(this.scene, this.camera);
  }

  dispose(): void {
    this.stop();
    if (this.parts) destroyFighterModel(this.parts);
    this.renderer.dispose();
  }
}

export function resolvePreviewAnimationForFighter(fighterId: string): PreviewAnimationId | undefined {
  return getDefaultFighterProfile(normalizeDefaultFighterId(fighterId))?.previewAnimation;
}
