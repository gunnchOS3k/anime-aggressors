import * as THREE from "three";
import type { GameState } from "@anime-aggressors/game-core";
import { FP_SCALE, STAGE_HEIGHT, STAGE_WIDTH } from "@anime-aggressors/game-core";
import { getActiveHitboxesForState, getHurtboxes } from "@anime-aggressors/game-core";
import { CameraDirector } from "./CameraDirector.ts";
import { CharacterView } from "./CharacterView.ts";
import { StageView } from "./StageView.ts";
import { HitboxDebugView } from "./HitboxDebugView.ts";
import { HurtboxDebugView } from "./HurtboxDebugView.ts";
import { CombatVfxOrchestrator } from "./vfx/CombatVfxOrchestrator.ts";
import { setupSceneLighting } from "./SceneLighting.ts";
import { fpToWorld } from "./RenderTypes.ts";
import type { RenderOptions, ThreeRendererOptions } from "./RenderTypes.ts";

export class ThreeGameRenderer {
  private container: HTMLElement;
  private scene = new THREE.Scene();
  private renderer: THREE.WebGLRenderer;
  private cameraDirector: CameraDirector;
  private stageView: StageView;
  private characterViews: CharacterView[] = [];
  private hitboxView = new HitboxDebugView();
  private hurtboxView = new HurtboxDebugView();
  private vfx = new CombatVfxOrchestrator();
  private mounted = false;
  private lastKoFrame = -1;
  private currentStageId = "";
  private width: number;
  private height: number;
  private lastError: string | undefined;
  private stageObjectCount = 0;

  constructor(container: HTMLElement, options: ThreeRendererOptions = {}) {
    this.container = container;
    this.width = Math.max(options.width ?? container.clientWidth, 320);
    this.height = Math.max(options.height ?? container.clientHeight, 240);

    this.scene.background = new THREE.Color(0x12122e);

    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    this.renderer.setPixelRatio(options.pixelRatio ?? Math.min(window.devicePixelRatio, 2));
    this.renderer.setClearColor(0x12122e);

    this.cameraDirector = new CameraDirector(this.width / this.height, options.smoothCamera ?? true);
    this.stageView = new StageView();
    this.scene.add(this.stageView.group);
    this.scene.fog = new THREE.Fog(0x12122e, fpToWorld(STAGE_WIDTH), fpToWorld(STAGE_WIDTH * 1.8));
    setupSceneLighting(this.scene);

    const hemi = new THREE.HemisphereLight(0x8899cc, 0x221133, 0.6);
    this.scene.add(hemi);
  }

  bootstrapScene(gameState: GameState): void {
    const stageId = gameState.config.stageId ?? "skyline-arena";
    this.stageObjectCount = this.stageView.setStage(stageId);
    this.currentStageId = stageId;
    this.cameraDirector.resetToStageDefault();

    while (this.characterViews.length < gameState.players.length) {
      const cv = new CharacterView(this.characterViews.length);
      this.characterViews.push(cv);
      this.scene.add(cv.group);
    }

    for (const p of gameState.players) {
      this.characterViews[p.id]?.update(p, gameState.frame);
    }
    this.cameraDirector.update(gameState);
    this.render();
  }

  mount(): void {
    if (this.mounted) return;
    this.renderer.domElement.className = "three-battle-canvas";
    this.renderer.domElement.style.display = "block";
    this.renderer.domElement.style.width = "100%";
    this.renderer.domElement.style.height = "100%";
    this.container.appendChild(this.renderer.domElement);
    this.resize(this.width, this.height);
    this.mounted = true;
  }

  getLastError(): string | undefined {
    return this.lastError;
  }

  getStageObjectCount(): number {
    return this.stageObjectCount;
  }

  getFighterViewCount(): number {
    return this.characterViews.length;
  }

  getCameraPositionString(): string {
    const c = this.cameraDirector.getCamera();
    const t = this.cameraDirector.getTarget();
    return `pos(${c.position.x.toFixed(1)},${c.position.y.toFixed(1)},${c.position.z.toFixed(1)}) target(${t.x.toFixed(1)},${t.y.toFixed(1)})`;
  }

  getCamera(): THREE.OrthographicCamera {
    return this.cameraDirector.getCamera();
  }

  update(gameState: GameState, renderOptions: RenderOptions = {}): void {
    try {
      const stageId = gameState.config.stageId ?? "skyline-arena";
      if (stageId !== this.currentStageId) {
        this.stageObjectCount = this.stageView.setStage(stageId);
        this.currentStageId = stageId;
      }

      while (this.characterViews.length < gameState.players.length) {
        const cv = new CharacterView(this.characterViews.length);
        this.characterViews.push(cv);
        this.scene.add(cv.group);
      }

      let koEvent = false;
      for (const p of gameState.players) {
        if (p.actionState === "defeated" && gameState.frame !== this.lastKoFrame) {
          koEvent = true;
          this.lastKoFrame = gameState.frame;
        }
        this.characterViews[p.id]?.update(p, gameState.frame);
      }

      const hitEvent = gameState.hitstopFrames > 0;
      this.cameraDirector.update(gameState, hitEvent, koEvent);
      this.vfx.update(this.scene, gameState.players, gameState.frame);

      if (renderOptions.showBlastZones) {
        this.stageView.setBlastZonesVisible(true, gameState.stage);
      } else {
        this.stageView.setBlastZonesVisible(false);
      }

      if (renderOptions.showHitboxes) {
        this.hitboxView.sync(getActiveHitboxesForState(gameState.players), this.scene);
      } else {
        this.hitboxView.clear(this.scene);
      }

      if (renderOptions.showHurtboxes) {
        this.hurtboxView.sync(getHurtboxes(gameState.players), this.scene);
      } else {
        this.hurtboxView.clear(this.scene);
      }
      this.lastError = undefined;
    } catch (e) {
      this.lastError = e instanceof Error ? e.message : String(e);
      if (import.meta.env.DEV) console.error("[ThreeGameRenderer]", this.lastError);
    }
  }

  render(): void {
    this.renderer.render(this.scene, this.cameraDirector.getCamera());
  }

  getScene(): THREE.Scene {
    return this.scene;
  }

  getCanvas(): HTMLCanvasElement {
    return this.renderer.domElement;
  }

  isMounted(): boolean {
    return this.mounted;
  }

  resize(width: number, height: number): void {
    this.width = Math.max(width, 320);
    this.height = Math.max(height, 240);
    this.renderer.setSize(this.width, this.height);
    this.cameraDirector.resize(this.width / this.height);
  }

  dispose(): void {
    this.hitboxView.clear(this.scene);
    this.hurtboxView.clear(this.scene);
    this.vfx.dispose(this.scene);
    for (const cv of this.characterViews) {
      this.scene.remove(cv.group);
      cv.dispose();
    }
    this.characterViews = [];
    this.renderer.dispose();
    if (this.mounted && this.renderer.domElement.parentElement === this.container) {
      this.container.removeChild(this.renderer.domElement);
    }
    this.mounted = false;
  }
}
