import {
  createInitialGameState,
  simulateFrame,
  resetForRematch,
  hashState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getActiveClash,
  getComboRoutesForFighter,
  getFighterMoveList,
  resetTrainingDamage,
  resetTrainingPositions,
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
import { loadMatchSetup } from "../match/matchSetupSession.ts";
import { ReplayRecorder } from "../replay/ReplayRecorder.js";
import { StatEventTracker, processMatchEnd } from "../career/careerService.js";
import { saveCurrentGame } from "../saves/SaveGameManager.js";
import { renderAuraMeter } from "../ui/AuraMeter.ts";
import { renderSuperReadyBadge } from "../ui/SuperReadyBadge.ts";
import { renderComboHintOverlay } from "../ui/ComboHintOverlay.js";
import { renderTrainingMoveOverlay } from "../ui/TrainingMoveOverlay.ts";
import { renderControlsOverlayHtml, BATTLE_SHORTCUT_LINES, TRAINING_SHORTCUT_LINES } from "../input/controlReference.ts";
import { applyTrainingLaunchSetup } from "../match/trainingSetup.ts";
import { renderEnergyClashPrompt, isClashActive } from "../ui/EnergyClashPrompt.js";
import { mountDemoOnboarding } from "../demo/demoOnboarding.ts";

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
  private fighterStateDebug = false;
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
  private battleComboCount = 0;
  private battleComboDecay = 0;
  private lastMoveCallout = "";
  private trainingOverlayEl: HTMLElement | null = null;
  private controlsOverlayEl: HTMLElement | null = null;
  private showControlsOverlay = false;
  private disposeOnboarding: (() => void) | null = null;
  private prevStocks: number[] = [3, 3];
  private prevShielding: boolean[] = [false, false];

  private trainingDummyBehavior: import("@anime-aggressors/game-core").TrainingDummyBehavior = "idle";

  private options: PlatformFighterOptions;

  constructor(root: HTMLElement, options: PlatformFighterOptions = {}) {
    this.root = root;
    this.options = options;
    this.trainingMode = options.trainingMode ?? false;
    this.root.innerHTML = `
      <div class="pf-root pf-root--fullscreen battle-screen">
        <div class="vs-toolbar vs-toolbar--battle">
          <button id="pf-back" type="button">← Home</button>
          <span class="vs-hint">H controls · ${this.trainingMode ? TRAINING_SHORTCUT_LINES.join(" · ") : BATTLE_SHORTCUT_LINES.slice(1).join(" · ")}</span>
        </div>
        <div class="pf-viewport-wrap battle-canvas-shell">
          <div id="pf-viewport" class="pf-viewport battle-canvas-shell"></div>
          <div id="pf-hud" class="pf-hud"></div>
          <div id="pf-training-overlays" class="pf-training-overlays"></div>
          ${renderControlsOverlayHtml()}
          <div id="pf-renderer-diagnostics-host"></div>
        </div>
      </div>
    `;
    this.viewport = this.root.querySelector("#pf-viewport") as HTMLElement;
    this.hud = this.root.querySelector("#pf-hud") as HTMLElement;
    this.trainingOverlayEl = this.root.querySelector("#pf-training-overlays") as HTMLElement;
    this.controlsOverlayEl = this.root.querySelector(".pf-controls-overlay") as HTMLElement;
    this.debugPanel = mountDebugPanel(this.root);
    this.root.querySelector("#pf-back")?.addEventListener("click", () => {
      this.stop();
      navigateHome();
    });
    window.addEventListener("keydown", this.onKeyDown);
  }

  start(): void {
    const setup = getMatchSetup();
    if (this.trainingMode) {
      const training = applyTrainingLaunchSetup();
      this.beginMatch({ p1: training.p1, p2: training.p2 }, training.ruleset);
      return;
    }
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
    this.disposeOnboarding?.();
    this.disposeOnboarding = null;
    this.debugPanel?.destroy();
    this.debugPanel = null;
  }

  private onKeyDown = (e: KeyboardEvent): void => {
    if (e.key === "h" || e.key === "H") {
      if (this.state === "fighting" || this.state === "select") {
        e.preventDefault();
        this.showControlsOverlay = !this.showControlsOverlay;
        if (this.controlsOverlayEl) {
          this.controlsOverlayEl.hidden = !this.showControlsOverlay;
        }
      }
      return;
    }
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
    if (e.key === "F6") {
      e.preventDefault();
      this.fighterStateDebug = !this.fighterStateDebug;
    }
    if (e.key === "r" || e.key === "R") {
      e.preventDefault();
      this.resetMatch();
    }
    if (this.trainingMode && this.gameState) {
      if (e.key === "d" || e.key === "D") {
        e.preventDefault();
        resetTrainingDamage(this.gameState);
      }
      if (e.key === "p" || e.key === "P") {
        e.preventDefault();
        resetTrainingPositions(this.gameState);
      }
      if (e.key === "1") {
        e.preventDefault();
        this.trainingDummyBehavior = "idle";
      }
      if (e.key === "2") {
        e.preventDefault();
        this.trainingDummyBehavior = "shield";
      }
      if (e.key === "3") {
        e.preventDefault();
        this.trainingDummyBehavior = "jump";
      }
      if (e.key === "4") {
        e.preventDefault();
        this.trainingDummyBehavior = "cpu1";
      }
      if (this.gameState.config.training) {
        this.gameState.config.training.dummyBehavior = this.trainingDummyBehavior;
        if (this.trainingDummyBehavior === "cpu1") {
          this.gameState.config.cpuOpponents = [
            { playerId: 1, difficulty: 1, seed: this.gameState.config.seed },
          ];
        } else {
          this.gameState.config.cpuOpponents = undefined;
        }
      }
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

    if (this.trainingMode) {
      config.training = {
        dummyPlayerId: 1,
        dummyBehavior: this.trainingDummyBehavior,
        cpu: { playerId: 1, difficulty: 1, seed: config.seed },
      };
      if (this.trainingDummyBehavior === "cpu1") {
        config.cpuOpponents = [{ playerId: 1, difficulty: 1, seed: config.seed }];
      }
    } else {
      const setupSession = loadMatchSetup();
      const bot = setupSession.fighters.find((f) => f.isBot);
      if (bot) {
        config.cpuOpponents = [
          { playerId: bot.playerId, difficulty: bot.cpuLevel ?? 1, seed: config.seed },
        ];
      }
    }

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
    this.disposeOnboarding?.();
    this.disposeOnboarding = mountDemoOnboarding(this.root);

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

    for (const hit of this.gameState.lastHitEvents ?? []) {
      if (hit.attackerPlayerId === 0) {
        this.battleComboCount += 1;
        this.battleComboDecay = 90;
        this.lastMoveCallout = hit.moveId.replace(/-/g, " ");
      }
    }
    if (this.battleComboDecay > 0) {
      this.battleComboDecay -= 1;
      if (this.battleComboDecay === 0) this.battleComboCount = 0;
    }

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
    globalAudio.play("result");
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
      const shielding = p.actionState === "shielding";
      if (shielding && !this.prevShielding[p.id]) {
        globalAudio.play("shield_hit", 0.6);
      }
      this.prevShielding[p.id] = shielding;
      if (p.stocks < this.prevStocks[p.id]) {
        globalAudio.play("ko");
      }
      this.prevStocks[p.id] = p.stocks;
      this.prevDamage[p.id] = p.damage;
    }

    if (this.debug || this.trainingMode || this.fighterStateDebug) {
      this.debugPanel?.update({
        frame: this.gameState.frame,
        hash: hashState(this.gameState),
        rollbackCount: this.rollback?.getRollbackCount() ?? 0,
        inputs: pollAllInputs(this.simFrame),
        gameState: this.gameState,
        paused: this.paused,
        fighterStateDebug: this.fighterStateDebug,
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

  private formatPlayerHudLabel(
    p: import("@anime-aggressors/game-core").PlayerState,
    playerIndex: number,
  ): string {
    const cpu = this.gameState?.config.cpuOpponents?.find((c) => c.playerId === p.id);
    const cpuTag = cpu ? ` <span class="pf-hud-cpu">CPU Lv${cpu.difficulty}</span>` : "";
    const status = this.formatStatusChip(p);
    return `<strong class="pf-hud-name">${p.fighterName}</strong>${cpuTag}${status}`;
  }

  private formatStatusChip(p: import("@anime-aggressors/game-core").PlayerState): string {
    if (p.invulnFrames > 0) return `<span class="pf-hud-status pf-hud-status--invuln">INV</span>`;
    if (p.actionState === "shielding") return `<span class="pf-hud-status pf-hud-status--shield">SHIELD</span>`;
    if (p.actionState === "shieldStun" || p.actionState === "shieldBreak")
      return `<span class="pf-hud-status pf-hud-status--shield-break">SHIELD STUN</span>`;
    if (p.actionState === "hitstun") return `<span class="pf-hud-status pf-hud-status--hitstun">HITSTUN</span>`;
    if (p.actionState === "grabbed") return `<span class="pf-hud-status pf-hud-status--grabbed">GRABBED</span>`;
    return "";
  }

  private updateHud(): void {
    if (!this.gameState) return;
    const p1 = this.gameState.players[0];
    const p2 = this.gameState.players[1];
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
      ${this.battleComboCount >= 2 ? `<div class="pf-combo-callout">${this.battleComboCount} HIT COMBO</div>` : ""}
      ${this.lastMoveCallout && this.battleComboDecay > 60 ? `<div class="pf-move-callout">${p1.fighterName.toUpperCase()} — ${this.lastMoveCallout}</div>` : ""}
      <div class="pf-hud-row">
        <span class="pf-hud-player pf-hud-player--p1">${this.formatPlayerHudLabel(p1, 0)} · <span class="pf-hud-stat">${p1Stat}</span> · <span class="pf-hud-stocks">${p1.stocks}♥</span> ${renderSuperReadyBadge(p1.aura)}</span>
        <span class="pf-timer">${timerSec}s</span>
        <span class="pf-hud-player pf-hud-player--p2">${this.formatPlayerHudLabel(p2, 1)} · <span class="pf-hud-stat">${p2Stat}</span> · <span class="pf-hud-stocks">${p2.stocks}♥</span> ${renderSuperReadyBadge(p2.aura)}</span>
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
    const moves = getFighterMoveList(fighterId).slice(0, 6);
    const moveListHtml = moves.length
      ? `<div class="pf-training-moves"><strong>Moves:</strong> ${moves.map((m) => m.label).join(" · ")}</div>`
      : "";
    const dummyLabel =
      this.trainingDummyBehavior === "cpu1"
        ? "CPU Lv1"
        : `Dummy: ${this.trainingDummyBehavior}`;
    const beginnerRoute = getComboRoutesForFighter(fighterId).find((r) => r.difficulty === "beginner");
    const clash = getActiveClash(this.gameState);

    const parts = [
      `<div class="pf-training-aura-hint">${dummyLabel} · D reset damage · P reset positions · 1-4 dummy modes</div>`,
      moveListHtml,
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
  const app = new PlatformFighterApp(root, { trainingMode: true, skipSelect: true });
  app.start();
  return app;
}

/** @deprecated Use launchMatch */
export function launchVerticalSlice(root: HTMLElement): PlatformFighterApp {
  return launchMatch(root);
}
