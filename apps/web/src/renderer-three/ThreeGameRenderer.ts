import * as THREE from "three";
import type { GameState } from "@anime-aggressors/game-core";
import { getActiveHitboxesForState, getHurtboxes } from "@anime-aggressors/game-core";
import { CameraDirector } from "./CameraDirector.js";
import { CharacterView } from "./CharacterView.js";
import { StageView } from "./StageView.js";
import { HitboxDebugView } from "./HitboxDebugView.js";
import { HurtboxDebugView } from "./HurtboxDebugView.js";
import { VfxSystem } from "./VfxSystem.js";
import { setupSceneLighting } from "./SceneLighting.js";
import type { RenderOptions, ThreeRendererOptions } from "./RenderTypes.js";

export class ThreeGameRenderer {
  private container: HTMLElement;
  private scene = new THREE.Scene();
  private renderer: THREE.WebGLRenderer;
  private cameraDirector: CameraDirector;
  private stageView: StageView;
  private characterViews: CharacterView[] = [];
  private hitboxView = new HitboxDebugView();
  private hurtboxView = new HurtboxDebugView();
  private vfx = new VfxSystem();
  private mounted = false;
  private lastKoFrame = -1;
  private width: number;
  private height: number;

  constructor(container: HTMLElement, options: ThreeRendererOptions = {}) {
    this.container = container;
    this.width = options.width ?? (container.clientWidth || 960);
    this.height = options.height ?? (container.clientHeight || 540);

    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    this.renderer.setPixelRatio(options.pixelRatio ?? Math.min(window.devicePixelRatio, 2));
    this.renderer.setClearColor(0x0a0a12);

    this.cameraDirector = new CameraDirector(this.width / this.height, options.smoothCamera ?? true);
    this.stageView = new StageView();
    this.scene.add(this.stageView.group);
    setupSceneLighting(this.scene);
  }

  mount(): void {
    if (this.mounted) return;
    this.renderer.domElement.style.display = "block";
    this.renderer.domElement.style.width = "100%";
    this.renderer.domElement.style.height = "100%";
    this.container.appendChild(this.renderer.domElement);
    this.resize(this.width, this.height);
    this.mounted = true;
  }

  update(gameState: GameState, renderOptions: RenderOptions = {}): void {
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
      this.characterViews[p.id]?.update(p);
    }

    const hitEvent = gameState.hitstopFrames > 0;
    this.cameraDirector.update(gameState, hitEvent, koEvent);
    this.vfx.update(this.scene, gameState.players);

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
  }

  render(): void {
    this.renderer.render(this.scene, this.cameraDirector.getCamera());
  }

  resize(width: number, height: number): void {
    this.width = width;
    this.height = height;
    this.renderer.setSize(width, height);
    this.cameraDirector.resize(width / height);
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
