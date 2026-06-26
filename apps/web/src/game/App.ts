import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  hashState,
  type GameConfig,
  type GameState,
} from "@anime-aggressors/game-core";
import { RollbackSession } from "@anime-aggressors/rollback";
import { pollAllInputs } from "../input/deviceAssignment.js";
import { ThreeGameRenderer } from "../renderer-three/ThreeGameRenderer.js";
import type { RenderOptions } from "../renderer-three/RenderTypes.js";
import { mountDebugPanel } from "./debugPanel.js";
import { showCharacterSelect, type CharacterSelectResult } from "./characterSelect.js";
import { showResults, type ResultsAction } from "./results.js";

export type MatchPhase = "select" | "fighting" | "results";

export type PlatformFighterOptions = {
  trainingMode?: boolean;
};

export class PlatformFighterApp {
  private root: HTMLElement;
  private viewport: HTMLElement;
  private hud: HTMLElement;
  private renderer: ThreeGameRenderer | null = null;
  private debugPanel: ReturnType<typeof mountDebugPanel> | null = null;
  private state: MatchPhase = "select";
  private gameState: GameState | null = null;
  private rollback: RollbackSession | null = null;
  private rafId = 0;
  private lastTime = 0;
  private accumulator = 0;
  private readonly fixedDt = 1 / 60;
  private debug = false;
  private showHitboxes = false;
  private showHurtboxes = false;
  private paused = false;
  private stepOnce = false;
  private selectResult: CharacterSelectResult | null = null;
  private simFrame = 0;
  private trainingMode: boolean;

  constructor(root: HTMLElement, options: PlatformFighterOptions = {}) {
    this.root = root;
    this.trainingMode = options.trainingMode ?? false;
    this.root.innerHTML = `
      <div class="pf-root">
        <div class="vs-toolbar">
          <button id="pf-back" type="button">← Home</button>
          <span class="vs-hint">P1: Arrows+ZXCVB | P2: WASD+12345 | F1 debug | F2 hitboxes | F3 pause | F4 step | R reset</span>
        </div>
        <div class="pf-viewport-wrap">
          <div id="pf-viewport" class="pf-viewport"></div>
          <div id="pf-hud" class="pf-hud"></div>
        </div>
      </div>
    `;
    this.viewport = this.root.querySelector("#pf-viewport") as HTMLElement;
    this.hud = this.root.querySelector("#pf-hud") as HTMLElement;
    this.debugPanel = mountDebugPanel(this.root);
    this.root.querySelector("#pf-back")?.addEventListener("click", () => {
      this.stop();
      window.dispatchEvent(new CustomEvent("aa:navigate-home"));
    });
    window.addEventListener("keydown", this.onKeyDown);
  }

  start(): void {
    this.state = "select";
    showCharacterSelect(this.root, (result) => {
      this.selectResult = result;
      this.beginMatch(result);
    });
  }

  stop(): void {
    cancelAnimationFrame(this.rafId);
    this.renderer?.dispose();
    this.renderer = null;
    window.removeEventListener("keydown", this.onKeyDown);
    this.debugPanel?.destroy();
    this.debugPanel = null;
  }

  private onKeyDown = (e: KeyboardEvent): void => {
    if (this.state !== "fighting") return;
    if (e.key === "F1") {
      e.preventDefault();
      this.debug = !this.debug;
      this.debugPanel?.toggle();
    }
    if (e.key === "F2") {
      e.preventDefault();
      this.showHitboxes = !this.showHitboxes;
      this.showHurtboxes = !this.showHurtboxes;
    }
    if (e.key === "F3") {
      e.preventDefault();
      this.paused = !this.paused;
    }
    if (e.key === "F4" && this.paused) {
      e.preventDefault();
      this.stepOnce = true;
    }
    if (e.key === "r" || e.key === "R") {
      e.preventDefault();
      this.resetMatch();
    }
  };

  private resetMatch(): void {
    if (!this.gameState) return;
    this.gameState = resetForRematch(this.gameState);
    this.rollback = new RollbackSession(this.gameState, {
      snapshotInterval: 1,
      maxRollbackFrames: 120,
      playerCount: 2,
    });
    this.simFrame = 0;
    this.paused = false;
    this.state = "fighting";
  }

  private beginMatch(select: CharacterSelectResult): void {
    const config: GameConfig = {
      playerCount: 2,
      stocks: 3,
      matchDurationFrames: 180 * 60,
      stageId: "skyline-arena",
      characterIds: [select.p1CharacterId, select.p2CharacterId],
      seed: Date.now() & 0xffff,
    };

    this.gameState = createInitialGameState(config);
    this.rollback = new RollbackSession(this.gameState, {
      snapshotInterval: 1,
      maxRollbackFrames: 120,
      playerCount: 2,
    });
    this.simFrame = 0;
    this.state = "fighting";
    this.paused = this.trainingMode;

    if (!this.renderer) {
      this.renderer = new ThreeGameRenderer(this.viewport, { smoothCamera: true });
      this.renderer.mount();
      const ro = new ResizeObserver(() => {
        const w = this.viewport.clientWidth || 960;
        const h = this.viewport.clientHeight || 540;
        this.renderer?.resize(w, h);
      });
      ro.observe(this.viewport);
    }

    this.lastTime = performance.now();
    this.accumulator = 0;
    this.loop(this.lastTime);
  }

  private loop(now: number): void {
    const elapsed = Math.min((now - this.lastTime) / 1000, 0.1);
    this.lastTime = now;

    if (!this.paused || this.stepOnce) {
      this.accumulator += elapsed;
      while (this.accumulator >= this.fixedDt) {
        this.tick();
        this.accumulator -= this.fixedDt;
        if (this.stepOnce) {
          this.stepOnce = false;
          break;
        }
      }
    }

    this.render();
    this.rafId = requestAnimationFrame((t) => this.loop(t));
  }

  private tick(): void {
    if (!this.gameState || !this.rollback || this.state !== "fighting") return;

    const inputs = pollAllInputs(this.simFrame);
    this.gameState = this.rollback.advanceFrame(inputs, [true, true]);
    this.simFrame += 1;

    if (this.gameState.phase === "results") {
      this.state = "results";
      this.showResultsScreen();
    }
  }

  private showResultsScreen(): void {
    if (!this.gameState) return;
    cancelAnimationFrame(this.rafId);

    showResults(this.root, this.gameState, (action: ResultsAction) => {
      if (action === "rematch" && this.gameState) {
        this.resetMatch();
        this.lastTime = performance.now();
        this.loop(this.lastTime);
      } else {
        this.start();
      }
    });
  }

  private render(): void {
    if (!this.gameState || !this.renderer || this.state !== "fighting") return;

    const opts: RenderOptions = {
      showHitboxes: this.showHitboxes,
      showHurtboxes: this.showHurtboxes,
      showBlastZones: this.debug || this.trainingMode,
      debug: this.debug,
      hitstopFreeze: this.gameState.hitstopFrames > 0,
    };

    this.renderer.update(this.gameState, opts);
    this.renderer.render();
    this.updateHud();

    if (this.debug || this.trainingMode) {
      this.debugPanel?.update({
        frame: this.gameState.frame,
        hash: hashState(this.gameState),
        rollbackCount: this.rollback?.getRollbackCount() ?? 0,
        inputs: pollAllInputs(this.simFrame),
        gameState: this.gameState,
        paused: this.paused,
      });
    }
  }

  private updateHud(): void {
    if (!this.gameState) return;
    const p1 = this.gameState.players[0];
    const p2 = this.gameState.players[1];
    const timerSec = Math.ceil(this.gameState.matchTimerFrames / 60);
    this.hud.innerHTML = `
      <div class="pf-hud-row">
        <span>P1 ${p1.damage}% · ${p1.stocks} stock${p1.stocks === 1 ? "" : "s"}</span>
        <span class="pf-timer">${timerSec}s</span>
        <span>P2 ${p2.damage}% · ${p2.stocks} stock${p2.stocks === 1 ? "" : "s"}</span>
      </div>
    `;
  }
}

export function launchMatch(root: HTMLElement): PlatformFighterApp {
  const app = new PlatformFighterApp(root, { trainingMode: false });
  app.start();
  return app;
}

export function launchTrainingMode(root: HTMLElement): PlatformFighterApp {
  const app = new PlatformFighterApp(root, { trainingMode: true });
  app.start();
  return app;
}

/** @deprecated Use launchMatch */
export function launchVerticalSlice(root: HTMLElement): PlatformFighterApp {
  return launchMatch(root);
}
