import * as THREE from "three";
import type { ThreeGameRenderer } from "./ThreeGameRenderer.ts";

export type RendererDiagnosticsSnapshot = {
  rendererMounted: boolean;
  canvasWidth: number;
  canvasHeight: number;
  sceneObjectCount: number;
  stageId: string;
  stageObjectCount: number;
  fighterCount: number;
  cameraPosition: string;
  activeRoute: string;
  lastError: string;
  bootOk: boolean;
  warnings: string[];
};

export type RendererDiagnosticsOptions = {
  enabled?: boolean;
  mount: HTMLElement;
  getRenderer: () => ThreeGameRenderer | null;
  getGameState: () => import("@anime-aggressors/game-core").GameState | null;
  getBootWarnings?: () => string[];
  getLastError?: () => string | undefined;
};

export class RendererDiagnostics {
  private panel: HTMLElement | null = null;
  private enabled: boolean;
  private opts: RendererDiagnosticsOptions;

  constructor(opts: RendererDiagnosticsOptions) {
    this.opts = opts;
    this.enabled = opts.enabled ?? import.meta.env.DEV;
  }

  mount(): void {
    if (!this.enabled || this.panel) return;
    this.panel = document.createElement("div");
    this.panel.className = "renderer-diagnostics";
    this.panel.hidden = true;
    this.opts.mount.appendChild(this.panel);
    window.addEventListener("keydown", this.onKey);
  }

  private onKey = (e: KeyboardEvent): void => {
    if (e.key === "F6") {
      e.preventDefault();
      if (this.panel) this.panel.hidden = !this.panel.hidden;
    }
  };

  update(snapshot: RendererDiagnosticsSnapshot): void {
    if (!this.panel) return;
    if (!snapshot.bootOk) {
      this.panel.hidden = false;
    }
    this.panel.innerHTML = `
      <strong>Renderer Diagnostics</strong> (F6 toggle)
      <ul>
        <li>mounted: ${snapshot.rendererMounted ? "yes" : "no"}</li>
        <li>canvas: ${snapshot.canvasWidth}×${snapshot.canvasHeight}</li>
        <li>scene objects: ${snapshot.sceneObjectCount}</li>
        <li>stage: ${snapshot.stageId} (${snapshot.stageObjectCount} objs)</li>
        <li>fighters: ${snapshot.fighterCount}</li>
        <li>camera: ${snapshot.cameraPosition}</li>
        <li>route: ${snapshot.activeRoute}</li>
        ${snapshot.warnings.map((w) => `<li class="warn">${w}</li>`).join("")}
        ${snapshot.lastError ? `<li class="err">error: ${snapshot.lastError}</li>` : ""}
      </ul>`;
  }

  showFailurePanel(stageId: string, fighterNames: string[], error: string): void {
    if (!this.panel) this.mount();
    if (!this.panel) return;
    this.panel.hidden = false;
    this.panel.innerHTML = `
      <strong>Renderer failed to draw battle scene.</strong>
      <p>Stage: ${stageId}</p>
      <p>Fighters: ${fighterNames.join(" vs ")}</p>
      <p class="err">Error: ${error}</p>
      <p><small>Press F6 for full diagnostics. Fallback stage/fighters should still appear when possible.</small></p>`;
  }

  dispose(): void {
    window.removeEventListener("keydown", this.onKey);
    this.panel?.remove();
    this.panel = null;
  }
}

export function countSceneObjects(renderer: ThreeGameRenderer): number {
  let n = 0;
  renderer.getScene().traverse((o) => {
    if (o instanceof THREE.Mesh) n += 1;
  });
  return n;
}
