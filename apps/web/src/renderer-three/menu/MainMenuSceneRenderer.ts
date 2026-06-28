import * as THREE from "three";
import { setupPreviewSceneLighting } from "../preview/CharacterSelectStage.ts";
import { createMenuStageDiorama, updateMenuStageLightSweep } from "./MenuStageDiorama.ts";
import { createMenuAuraBackdrop, type MenuAuraBackdrop } from "./MenuAuraBackdrop.ts";
import {
  createMenuFighterShowcase,
  updateMenuFighterShowcase,
  disposeMenuFighterShowcase,
  type MenuFighterShowcaseResult,
} from "./MenuFighterShowcase.ts";

export type MainMenuSceneStats = {
  objectCount: number;
  fighterCount: number;
  meshCount: number;
};

export class MainMenuSceneRenderer {
  readonly scene = new THREE.Scene();
  readonly camera: THREE.PerspectiveCamera;
  readonly renderer: THREE.WebGLRenderer;
  private canvas: HTMLCanvasElement;
  private diorama: ReturnType<typeof createMenuStageDiorama>;
  private aura: MenuAuraBackdrop;
  private showcase: MenuFighterShowcaseResult;
  private raf = 0;
  private frame = 0;
  private disposed = false;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.scene.background = new THREE.Color(0x060610);
    this.scene.fog = new THREE.Fog(0x060610, 6, 18);

    this.camera = new THREE.PerspectiveCamera(42, 16 / 9, 0.1, 40);
    this.camera.position.set(0, 2.1, 6.2);
    this.camera.lookAt(0, 0.9, 0);

    this.renderer = new THREE.WebGLRenderer({ canvas, alpha: false, antialias: true });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setClearColor(0x060610, 1);

    setupPreviewSceneLighting(this.scene);

    this.diorama = createMenuStageDiorama();
    this.scene.add(this.diorama.group);

    this.aura = createMenuAuraBackdrop(["red", "indigo"]);
    this.scene.add(this.aura.getGroup());

    this.showcase = createMenuFighterShowcase();
    this.scene.add(this.showcase.group);

    this.resize(canvas.clientWidth || window.innerWidth, canvas.clientHeight || window.innerHeight);
  }

  getStats(): MainMenuSceneStats {
    let objectCount = 0;
    this.scene.traverse((o) => {
      if (o instanceof THREE.Mesh) objectCount += 1;
    });
    return {
      objectCount,
      fighterCount: this.showcase.fighterCount,
      meshCount: this.showcase.meshCount,
    };
  }

  hasFighterShowcase(): boolean {
    return this.showcase.fighterCount >= 1;
  }

  resize(width: number, height: number): void {
    const w = Math.max(width, 320);
    const h = Math.max(height, 240);
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
  }

  start(): void {
    this.stop();
    const tick = () => {
      if (this.disposed) return;
      this.frame += 1;
      const t = this.frame / 60;
      updateMenuStageLightSweep(this.diorama.lightSweep, t);
      updateMenuFighterShowcase(this.showcase.slots, t);
      this.aura.update(t);
      this.camera.position.x = Math.sin(t * 0.12) * 0.35;
      this.camera.lookAt(0, 0.85 + Math.sin(t * 0.2) * 0.05, 0);
      this.renderer.render(this.scene, this.camera);
      this.raf = requestAnimationFrame(tick);
    };
    this.raf = requestAnimationFrame(tick);
  }

  stop(): void {
    if (this.raf) cancelAnimationFrame(this.raf);
    this.raf = 0;
  }

  dispose(): void {
    this.disposed = true;
    this.stop();
    disposeMenuFighterShowcase(this.showcase.slots);
    this.aura.dispose();
    this.renderer.dispose();
  }
}

export function createMainMenuSceneRenderer(canvas: HTMLCanvasElement): MainMenuSceneRenderer {
  return new MainMenuSceneRenderer(canvas);
}
