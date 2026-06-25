import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  hashState,
  listCharacters,
  fpToDisplay,
  type GameConfig,
  type GameState,
  type InputFrame,
} from "@anime-aggressors/game-core";
import { RollbackSession } from "@anime-aggressors/rollback";
import { pollAllInputs } from "../input/deviceAssignment.js";
import { renderFrame, type RenderOptions } from "./renderCanvas.js";
import { renderDebugOverlay, type DebugInfo } from "./debugOverlay.js";
import { showCharacterSelect, type CharacterSelectResult } from "./characterSelect.js";
import { showResults, type ResultsAction } from "./results.js";

export type MatchPhase = "select" | "fighting" | "results";

export class VerticalSliceApp {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private state: MatchPhase = "select";
  private gameState: GameState | null = null;
  private rollback: RollbackSession | null = null;
  private rafId = 0;
  private lastTime = 0;
  private accumulator = 0;
  private readonly fixedDt = 1 / 60;
  private debug = false;
  private showHitboxes = false;
  private selectResult: CharacterSelectResult | null = null;
  private simFrame = 0;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("2D context unavailable");
    this.ctx = ctx;
  }

  start(): void {
    this.state = "select";
    showCharacterSelect(this.canvas.parentElement!, (result) => {
      this.selectResult = result;
      this.beginMatch(result);
    });
  }

  stop(): void {
    cancelAnimationFrame(this.rafId);
  }

  toggleDebug(): void {
    this.debug = !this.debug;
  }

  toggleHitboxes(): void {
    this.showHitboxes = !this.showHitboxes;
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
    this.lastTime = performance.now();
    this.accumulator = 0;
    this.loop(this.lastTime);
  }

  private loop(now: number): void {
    const elapsed = Math.min((now - this.lastTime) / 1000, 0.1);
    this.lastTime = now;
    this.accumulator += elapsed;

    while (this.accumulator >= this.fixedDt) {
      this.tick();
      this.accumulator -= this.fixedDt;
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

    showResults(this.canvas.parentElement!, this.gameState, (action: ResultsAction) => {
      if (action === "rematch" && this.gameState) {
        this.gameState = resetForRematch(this.gameState);
        this.rollback = new RollbackSession(this.gameState, {
          snapshotInterval: 1,
          maxRollbackFrames: 120,
          playerCount: 2,
        });
        this.simFrame = 0;
        this.state = "fighting";
        this.lastTime = performance.now();
        this.loop(this.lastTime);
      } else {
        this.start();
      }
    });
  }

  private render(): void {
    if (!this.gameState || this.state !== "fighting") return;

    const opts: RenderOptions = {
      showHitboxes: this.showHitboxes,
    };
    renderFrame(this.ctx, this.canvas.width, this.canvas.height, this.gameState, opts);

    if (this.debug && this.rollback) {
      const debug: DebugInfo = {
        frame: this.gameState.frame,
        hash: hashState(this.gameState),
        rollbackCount: this.rollback.getRollbackCount(),
        inputs: pollAllInputs(this.simFrame),
      };
      renderDebugOverlay(this.ctx, debug);
    }
  }
}

export function launchVerticalSlice(root: HTMLElement): VerticalSliceApp {
  root.innerHTML = `
    <div class="vs-root">
      <div class="vs-toolbar">
        <button id="vs-debug" type="button">Toggle Debug</button>
        <button id="vs-hitboxes" type="button">Toggle Hitboxes</button>
        <span class="vs-hint">P1: Arrows+ZXCVB | P2: WASD+12345 | Gamepads auto-assign</span>
      </div>
      <canvas id="vs-canvas" width="960" height="540"></canvas>
    </div>
  `;

  const canvas = root.querySelector("#vs-canvas") as HTMLCanvasElement;
  const app = new VerticalSliceApp(canvas);

  root.querySelector("#vs-debug")?.addEventListener("click", () => app.toggleDebug());
  root.querySelector("#vs-hitboxes")?.addEventListener("click", () => app.toggleHitboxes());

  app.start();
  return app;
}
