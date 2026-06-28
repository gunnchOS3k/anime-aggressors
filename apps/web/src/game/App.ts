import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  hashState,
  ELEMENTS,
  SIZE_STATS,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getActiveClash,
  getComboRoutesForFighter,
  type GameConfig,
  type GameState,
  type GameRuleset,
  type MatchRecord,
  type ReplayRecord,
} from "@anime-aggressors/game-core";
import { RollbackSession } from "@anime-aggressors/rollback";
import { pollAllInputs } from "../input/deviceAssignment.js";
import { createBattleScene } from "../renderer-three/createBattleScene.ts";
import { RendererDiagnostics } from "../renderer-three/RendererDiagnostics.ts";
import type { BattleSceneBootResult } from "../renderer-three/createBattleScene.ts";
import type { RenderOptions } from "../renderer-three/RenderTypes.js";
import { mountDebugPanel } from "./debugPanel.js";
import { showCharacterSelect, type CharacterSelectResult } from "../screens/FighterSelectScreen.js";
import { showResults, type ResultsAction } from "./results.js";
import { globalAudio } from "../audio/AudioManager.js";
import { navigateHome } from "../router.js";
import { getMatchSetup } from "../match/matchSession.js";
import { getProfileForSlot } from "../storage/inputProfileStorage.js";
import { ReplayRecorder } from "../replay/ReplayRecorder.js";
import { StatEventTracker, processMatchEnd } from "../career/careerService.js";
import { saveCurrentGame } from "../saves/SaveGameManager.js";
import { renderAuraMeter } from "../ui/AuraMeter.ts";
import { renderSuperReadyBadge } from "../ui/SuperReadyBadge.ts";
import { renderComboHintOverlay } from "../ui/ComboHintOverlay.js";
import { renderTrainingMoveOverlay } from "../ui/TrainingMoveOverlay.ts";
import { renderEnergyClashPrompt, isClashActive } from "../ui/EnergyClashPrompt.js";

function fighterIdFromCharacterId(characterId: string): string {
  return characterId.replace(/^created:/, "");
}

export type MatchPhase = "select" | "fighting" | "results";

export type PlatformFighterOptions = {
  trainingMode?: boolean;
  skipSelect?: boolean;
};

export class PlatformFighterApp {
  private root: HTMLElement;
  private viewport: HTMLElement;
  private hud: HTMLElement;
  private renderer: import("../renderer-three/ThreeGameRenderer.js").ThreeGameRenderer | null = null;
  private rendererDiagnostics: RendererDiagnostics | null = null;
  private bootResult: BattleSceneBootResult | null = null;
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
  private prevDamage: number[] = [0, 0];
  private replayRecorder: ReplayRecorder | null = null;
  private statTracker: StatEventTracker | null = null;
  private initialState: GameState | null = null;
  private matchEndResult: { match: MatchRecord; replay: ReplayRecord | null } | null = null;
  private matchMode = "playMatch";
  private comboHits = 0;
  private trainingOverlayEl: HTMLElement | null = null;

  private options: PlatformFighterOptions;

  constructor(root: HTMLElement, options: PlatformFighterOptions = {}) {
    this.root = root;
    this.options = options;
    this.trainingMode = options.trainingMode ?? false;
    this.root.innerHTML = `
      <div class="pf-root battle-screen">
        <div class="vs-toolbar">
          <button id="pf-back" type="button">← Home</button>
          <span class="vs-hint">P1: ${getProfileForSlot(1).name} | P2: ${getProfileForSlot(2).name} | F1 debug | F2 hitboxes | F3 pause | F4 step | F6 renderer | R reset</span>
        </div>
        <div class="pf-viewport-wrap battle-canvas-shell">
          <div id="pf-viewport" class="pf-viewport battle-canvas-shell"></div>
          <div id="pf-hud" class="pf-hud"></div>
          <div id="pf-training-overlays" class="pf-training-overlays"></div>
          <div id="pf-renderer-diagnostics-host"></div>
        </div>
      </div>
    `;
    this.viewport = this.root.querySelector("#pf-viewport") as HTMLElement;
    this.hud = this.root.querySelector("#pf-hud") as HTMLElement;
    this.trainingOverlayEl = this.root.querySelector("#pf-training-overlays") as HTMLElement;
    this.debugPanel = mountDebugPanel(this.root);
    this.root.querySelector("#pf-back")?.addEventListener("click", () => {
      this.stop();
      navigateHome();
    });
    window.addEventListener("keydown", this.onKeyDown);
  }

  start(): void {
    const setup = getMatchSetup();
    if (this.options.skipSelect && setup.p1Fighter && setup.p2Fighter) {
      this.beginMatch(
        { p1: setup.p1Fighter, p2: setup.p2Fighter },
        setup.ruleset,
      );
      return;
    }
    this.state = "select";
    showCharacterSelect(this.root, (result) => {
      this.selectResult = result;
      this.beginMatch(result);
    });
  }

  stop(): void {
    cancelAnimationFrame(this.rafId);
    this.rendererDiagnostics?.dispose();
    this.rendererDiagnostics = null;
    this.renderer?.dispose();
    this.renderer = null;
    this.bootResult = null;
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
    if (e.key === "s" || e.key === "S") {
      e.preventDefault();
      void this.saveSnapshot();
    }
  };

  private async saveSnapshot(): Promise<void> {
    if (!this.gameState) return;
    const setup = getMatchSetup();
    await saveCurrentGame(this.gameState, {
      mode: this.matchMode,
      title: `${setup.ruleset?.name ?? "Match"} — frame ${this.gameState.frame}`,
      ruleset: setup.ruleset,
      auto: true,
    });
  }

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
    this.comboHits = 0;
    this.state = "fighting";
  }

  beginMatch(select: CharacterSelectResult, ruleset?: GameRuleset): void {
    const activeRuleset = ruleset ?? getMatchSetup().ruleset ?? DEFAULT_RULESET;
    const setup = getMatchSetup();
    const config: GameConfig = gameConfigFromRuleset(
      activeRuleset,
      [select.p1, select.p2],
      Date.now() & 0xffff,
    );

    this.gameState = createInitialGameState(config);
    this.initialState = structuredClone(this.gameState);
    this.matchMode = this.trainingMode
      ? "training"
      : setup.customFlow
        ? "customGame"
        : "playMatch";
    this.replayRecorder = new ReplayRecorder({
      gameVersion: "0.1.0",
      mode: this.matchMode,
      ruleset: activeRuleset,
      title: `${activeRuleset.name} Replay`,
    });
    this.replayRecorder.start(this.gameState);
    this.statTracker = new StatEventTracker(this.matchMode);
    this.statTracker.initFromState(this.gameState);
    this.statTracker.start(0);
    this.matchEndResult = null;
    this.rollback = new RollbackSession(this.gameState, {
      snapshotInterval: 1,
      maxRollbackFrames: 120,
      playerCount: 2,
    });
    this.simFrame = 0;
    this.comboHits = 0;
    this.state = "fighting";
    this.paused = this.trainingMode;

    this.showFightAnnouncement();

    if (!this.renderer) {
      const diagHost = this.root.querySelector("#pf-renderer-diagnostics-host") as HTMLElement;
      const { renderer, result } = createBattleScene({
        mount: this.viewport,
        gameConfig: config,
        initialState: this.gameState,
        smoothCamera: true,
      });
      this.renderer = renderer;
      this.bootResult = result;

      this.rendererDiagnostics = new RendererDiagnostics({
        enabled: true,
        mount: diagHost ?? this.viewport,
        getRenderer: () => this.renderer,
        getGameState: () => this.gameState,
        getBootWarnings: () => this.bootResult?.warnings ?? [],
        getLastError: () => this.renderer?.getLastError() ?? this.bootResult?.error,
      });
      this.rendererDiagnostics.mount();

      if (!result.ok) {
        const names = this.gameState.players.map((p) => p.fighterName);
        this.rendererDiagnostics.showFailurePanel(
          config.stageId ?? "unknown",
          names,
          result.error ?? (result.warnings.join("; ") || "Scene boot incomplete"),
        );
        if (import.meta.env.DEV) {
          console.error("Battle scene boot failed", result);
        }
      }

      const ro = new ResizeObserver(() => {
        const w = Math.max(this.viewport.clientWidth || 0, 960);
        const h = Math.max(this.viewport.clientHeight || 0, 520);
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
    this.replayRecorder?.recordFrame(this.simFrame, inputs);
    this.gameState = this.rollback.advanceFrame(inputs, [true, true]);
    this.statTracker?.trackFrame(this.gameState, inputs);
    this.simFrame += 1;

    if (this.gameState.phase === "results") {
      this.state = "results";
      this.showResultsScreen();
    }
  }

  private async showResultsScreen(): Promise<void> {
    if (!this.gameState || !this.initialState) return;
    cancelAnimationFrame(this.rafId);

    this.statTracker?.end(this.gameState.frame, this.gameState.winnerId ?? undefined);
    try {
      this.matchEndResult = await processMatchEnd({
        mode: this.matchMode,
        initialState: this.initialState,
        finalState: this.gameState,
        events: this.statTracker?.getEvents() ?? [],
        recorder: this.replayRecorder,
        localPlayerId: 0,
      });
    } catch (err) {
      console.error("Career recording failed", err);
    }

    showResults(
      this.root,
      this.gameState,
      (action: ResultsAction) => {
        if (action === "rematch" && this.gameState) {
          this.resetMatch();
          this.lastTime = performance.now();
          this.loop(this.lastTime);
        } else if (action === "menu") {
          this.stop();
          navigateHome();
        } else {
          this.stop();
        }
      },
      {
        match: this.matchEndResult?.match,
        replay: this.matchEndResult?.replay,
      },
    );
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
    this.rendererDiagnostics?.update({
      rendererMounted: this.renderer.isMounted(),
      canvasWidth: this.renderer.getCanvas().width,
      canvasHeight: this.renderer.getCanvas().height,
      sceneObjectCount: this.bootResult?.sceneObjectCount ?? 0,
      stageId: this.gameState.config.stageId ?? "—",
      stageObjectCount: this.renderer.getStageObjectCount(),
      fighterCount: this.renderer.getFighterViewCount(),
      cameraPosition: this.renderer.getCameraPositionString(),
      activeRoute: window.location.hash || "#/battle",
      lastError: this.renderer.getLastError() ?? this.bootResult?.error ?? "",
      bootOk: this.bootResult?.ok ?? false,
      warnings: this.bootResult?.warnings ?? [],
    });
    if (this.trainingMode) {
      this.updateTrainingOverlays();
    }

    for (const p of this.gameState.players) {
      if (p.damage > this.prevDamage[p.id]) {
        globalAudio.play("hit_confirm");
        if (this.trainingMode && p.id === 1) {
          this.comboHits += 1;
        }
      }
      if (p.stocks < 3 && p.actionState === "defeated") {
        globalAudio.play("ko");
      }
      this.prevDamage[p.id] = p.damage;
    }

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

  private showFightAnnouncement(): void {
    const banner = document.createElement("div");
    banner.className = "pf-fight-banner";
    banner.innerHTML = `<span class="pf-fight-ready">Ready?</span><span class="pf-fight-go">Fight!</span>`;
    this.root.querySelector(".pf-viewport-wrap")?.appendChild(banner);
    window.setTimeout(() => banner.classList.add("show-go"), 900);
    window.setTimeout(() => banner.remove(), 2200);
  }

  private updateHud(): void {
    if (!this.gameState) return;
    const p1 = this.gameState.players[0];
    const p2 = this.gameState.players[1];
    const el1 = ELEMENTS[p1.fighterColor]?.name ?? "—";
    const el2 = ELEMENTS[p2.fighterColor]?.name ?? "—";
    const sz1 = SIZE_STATS[p1.fighterSize]?.label ?? "—";
    const sz2 = SIZE_STATS[p2.fighterSize]?.label ?? "—";
    const matchType = this.gameState.config.ruleset?.matchType ?? "stock";
    const p1Stat =
      matchType === "stamina"
        ? `${p1.staminaHp}/${p1.maxStaminaHp} HP`
        : matchType === "time"
          ? `score ${p1.score}`
          : `${p1.damage}%`;
    const p2Stat =
      matchType === "stamina"
        ? `${p2.staminaHp}/${p2.maxStaminaHp} HP`
        : matchType === "time"
          ? `score ${p2.score}`
          : `${p2.damage}%`;
    const timerSec =
      this.gameState.config.ruleset?.timerSeconds === null
        ? "∞"
        : String(Math.ceil(this.gameState.matchTimerFrames / 60));
    this.hud.innerHTML = `
      <div class="pf-hud-row">
        <span><strong>${p1.fighterName}</strong> (${sz1}/${el1}) · ${p1Stat} · ${p1.stocks}♥ ${renderSuperReadyBadge(p1.aura)}</span>
        <span class="pf-timer">${timerSec}s</span>
        <span><strong>${p2.fighterName}</strong> (${sz2}/${el2}) · ${p2Stat} · ${p2.stocks}♥ ${renderSuperReadyBadge(p2.aura)}</span>
      </div>
      <div class="pf-hud-aura-row">
        ${renderAuraMeter(p1.aura, p1.fighterColor, "left")}
        ${renderAuraMeter(p2.aura, p2.fighterColor, "right")}
      </div>
    `;
  }

  private updateTrainingOverlays(): void {
    if (!this.gameState || !this.trainingOverlayEl) return;
    const p1 = this.gameState.players[0];
    const fighterId = fighterIdFromCharacterId(p1.characterId);
    const beginnerRoute = getComboRoutesForFighter(fighterId).find((r) => r.difficulty === "beginner");
    const clash = getActiveClash(this.gameState);

    const parts = [
      `<div class="pf-training-aura-hint">Hold Shield + Special to charge aura · Level 3 = Super Ready</div>`,
      renderTrainingMoveOverlay({ player: p1, comboCount: this.comboHits }),
      beginnerRoute
        ? renderComboHintOverlay({
            hint: beginnerRoute.description,
            suggestedInput: beginnerRoute.teachingHint,
          })
        : "",
      isClashActive(clash) && clash
        ? renderEnergyClashPrompt({ clash, localPlayerId: 0 })
        : "",
    ];

    this.trainingOverlayEl.innerHTML = parts.filter(Boolean).join("");
  }
}

export function launchMatch(root: HTMLElement, options: PlatformFighterOptions = {}): PlatformFighterApp {
  const app = new PlatformFighterApp(root, options);
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
