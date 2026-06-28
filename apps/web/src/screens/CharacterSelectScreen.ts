import type { CreatedFighter } from "@anime-aggressors/game-core";
import { SIZE_STATS, getDefaultFighterProfile, normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import { loadMatchSetup, saveMatchSetup } from "../match/matchSetupSession.js";
import {
  buildSelectableRoster,
  createCharacterSelectState,
  getFocusedFighter,
  isCharacterSelectReady,
  selectFighterForActivePlayer,
  setActivePlayer,
  setFocusedFighter,
} from "../characterSelect/characterSelectState.js";
import { renderCharacterGrid, navigateGrid } from "../ui/CharacterGrid.js";
import { renderPlayerSelectionPanel } from "../ui/PlayerSelectionPanel.js";
import { renderFighterPreviewPanel } from "../ui/FighterPreviewPanel.js";
import { renderSetupFlowShell } from "../ui/setup/SetupFlowShell.ts";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";
import { CharacterPreviewRenderer } from "../renderer-three/preview/CharacterPreviewRenderer.ts";

export type CharacterSelectResult = {
  p1: CreatedFighter;
  p2: CreatedFighter;
};

export type CharacterSelectOptions = {
  setupSummary?: string;
  onContinue: (result: CharacterSelectResult) => void;
  onBack?: () => void;
};

let previewRenderer: CharacterPreviewRenderer | null = null;

import { globalAudio } from "../audio/AudioManager.js";

function playMenuBlip(kind: "hover" | "select" | "confirm" | "cancel"): void {
  try {
    if (kind === "confirm") globalAudio.play("menu_select");
    else if (kind === "select") globalAudio.play("hit_confirm");
    else if (kind === "hover") globalAudio.play("dodge");
    else globalAudio.play("attack_whiff");
  } catch {
    /* audio optional */
  }
}

function syncPreview(canvas: HTMLCanvasElement | null, fighter: CreatedFighter | null, phase: "hover" | "select" = "hover"): void {
  if (!canvas || !fighter) return;
  if (!previewRenderer || previewRenderer.getCanvas() !== canvas) {
    previewRenderer?.dispose();
    previewRenderer = new CharacterPreviewRenderer(canvas);
    previewRenderer.start();
  }
  const rect = canvas.getBoundingClientRect();
  previewRenderer.resize(rect.width || 480, rect.height || 320);
  previewRenderer.setFighter(fighter, phase);
  previewRenderer.renderFrame(performance.now());
}

function disposePreview(): void {
  previewRenderer?.dispose();
  previewRenderer = null;
}

export function mountCharacterSelectScreen(root: HTMLElement, options: CharacterSelectOptions): void {
  const setup = loadMatchSetup();
  const roster = buildSelectableRoster();
  const initialP1 = setup.fighters.find((f) => f.playerId === 0)?.fighter ?? null;
  const initialP2 = setup.fighters.find((f) => f.playerId === 1)?.fighter ?? null;
  let state = createCharacterSelectState(roster, initialP1, initialP2);

  const summary =
    options.setupSummary ??
    `${setup.ruleset?.name ?? "Rules"} · ${setup.stageName ?? setup.stageId ?? "Stage"}`;

  const render = () => {
    const focused = getFocusedFighter(state, roster);
    root.innerHTML = renderSetupFlowShell({
      step: "fighters",
      title: "Select Fighters",
      summary,
      body: `
        <div class="${ARENA_CLASSES.characterSelectLayout} cs-layout character-select-layout">
          <aside class="cs-side cs-side--left">
            ${renderPlayerSelectionPanel(0, state.p1, state.activePlayer === 0)}
          </aside>
          <main class="cs-main">
            ${renderFighterPreviewPanel(focused)}
            ${renderCharacterGrid({ roster, state })}
          </main>
          <aside class="cs-side cs-side--right">
            ${renderPlayerSelectionPanel(1, state.p2, state.activePlayer === 1)}
          </aside>
        </div>
      `,
      footer: {
        backId: "cs-back",
        backLabel: "Back to Map Select",
        continueId: "cs-continue",
        continueLabel: "Continue to Controls Check",
        continueDisabled: !isCharacterSelectReady(state),
        extraHtml: `<button type="button" id="cs-create" class="${ARENA_CLASSES.secondaryBtn}">Create Fighter</button>`,
      },
    });

    const canvas = root.querySelector("#cs-preview-canvas") as HTMLCanvasElement | null;
    syncPreview(canvas, focused, "hover");

    root.querySelectorAll(".cs-tile").forEach((tile) => {
      const id = (tile as HTMLElement).dataset.fighterId!;
      const fighter = roster.find((f) => f.id === id)!;

      tile.addEventListener("mouseenter", () => {
        state = setFocusedFighter(state, id);
        playMenuBlip("hover");
        const liveCanvas = root.querySelector("#cs-preview-canvas") as HTMLCanvasElement | null;
        syncPreview(liveCanvas, fighter, "hover");
        root.querySelectorAll(".cs-tile").forEach((t) => t.classList.remove("cs-tile--focus"));
        tile.classList.add("cs-tile--focus");
        updatePreviewInfo(root, fighter);
      });

      tile.addEventListener("focus", () => {
        state = setFocusedFighter(state, id);
        const liveCanvas = root.querySelector("#cs-preview-canvas") as HTMLCanvasElement | null;
        syncPreview(liveCanvas, fighter, "hover");
        updatePreviewInfo(root, fighter);
      });

      tile.addEventListener("click", () => {
        state = selectFighterForActivePlayer(state, fighter);
        playMenuBlip("select");
        const liveCanvas = root.querySelector("#cs-preview-canvas") as HTMLCanvasElement | null;
        syncPreview(liveCanvas, fighter, "select");
        render();
      });
    });

    root.querySelectorAll("[data-player-slot]").forEach((el) => {
      el.addEventListener("click", () => {
        const player = Number((el as HTMLElement).dataset.playerSlot) as 0 | 1;
        state = setActivePlayer(state, player);
        render();
      });
    });

    root.addEventListener("keydown", onKeyDown);

    root.querySelector("#cs-create")?.addEventListener("click", () => {
      playMenuBlip("confirm");
      disposePreview();
      navigateToHash(APP_ROUTES.createFighter);
    });

    root.querySelector("#cs-back")?.addEventListener("click", () => {
      playMenuBlip("cancel");
      disposePreview();
      if (options.onBack) options.onBack();
      else navigateToHash(APP_ROUTES.matchSetupStage);
    });

    root.querySelector("#cs-continue")?.addEventListener("click", () => {
      if (!isCharacterSelectReady(state) || !state.p1 || !state.p2) return;
      playMenuBlip("confirm");
      saveMatchSetup({
        ...setup,
        fighters: [
          { playerId: 0, fighterId: state.p1.id, fighter: state.p1 },
          { playerId: 1, fighterId: state.p2.id, fighter: state.p2 },
        ],
      });
      disposePreview();
      options.onContinue({ p1: state.p1, p2: state.p2 });
    });
  };

  function onKeyDown(e: KeyboardEvent) {
    const focusedId = state.focusedId ?? roster[0]?.id;
    if (!focusedId) return;
    let nextId = focusedId;
    if (e.key === "ArrowRight" || e.key === "d") nextId = navigateGrid(roster, focusedId, 1, 0);
    else if (e.key === "ArrowLeft" || e.key === "a") nextId = navigateGrid(roster, focusedId, -1, 0);
    else if (e.key === "ArrowDown" || e.key === "s") nextId = navigateGrid(roster, focusedId, 0, 1);
    else if (e.key === "ArrowUp" || e.key === "w") nextId = navigateGrid(roster, focusedId, 0, -1);
    else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      const fighter = roster.find((f) => f.id === focusedId);
      if (fighter) {
        state = selectFighterForActivePlayer(state, fighter);
        playMenuBlip("select");
        render();
      }
      return;
    } else if (e.key === "Escape") {
      root.querySelector<HTMLButtonElement>("#cs-back")?.click();
      return;
    } else if (e.key === "Tab") {
      state = setActivePlayer(state, state.activePlayer === 0 ? 1 : 0);
      render();
      e.preventDefault();
      return;
    } else return;

    e.preventDefault();
    state = setFocusedFighter(state, nextId);
    const fighter = roster.find((f) => f.id === nextId)!;
    const canvas = root.querySelector("#cs-preview-canvas") as HTMLCanvasElement | null;
    syncPreview(canvas, fighter, "hover");
    updatePreviewInfo(root, fighter);
    root.querySelectorAll(".cs-tile").forEach((t) => {
      t.classList.toggle("cs-tile--focus", (t as HTMLElement).dataset.fighterId === nextId);
    });
  }

  render();
}

function updatePreviewInfo(root: HTMLElement, fighter: CreatedFighter): void {
  const info = root.querySelector(".cs-preview-info");
  if (!info) return;
  const profile = getDefaultFighterProfile(normalizeDefaultFighterId(fighter.id));
  const sizeLabel = SIZE_STATS[fighter.size].label;
  info.classList.remove("cs-preview-info--empty");
  info.innerHTML = `
    <h3 class="cs-preview-name">${fighter.name.toUpperCase()}</h3>
    <p class="cs-preview-element">${profile ? `${profile.elementName} / ${sizeLabel}` : `${fighter.color} / ${sizeLabel}`}</p>
    <p class="cs-preview-archetype">${profile?.archetype ?? "Custom Fighter"}</p>
    <p class="cs-preview-signature">Signature: ${profile?.signatureMoveName ?? "Custom Combo"}</p>
    <p class="cs-preview-tagline">"${profile?.shortTagline ?? "Ready for battle."}"</p>`;
}

export function mountMatchSetupCharacterSelect(root: HTMLElement): void {
  mountCharacterSelectScreen(root, {
    onContinue: () => navigateToHash(APP_ROUTES.matchSetupControls),
  });
}

/** @deprecated use mountCharacterSelectScreen */
export const mountFighterSelectScreen = (
  root: HTMLElement,
  onStart: (result: CharacterSelectResult) => void,
) => mountCharacterSelectScreen(root, { onContinue: onStart });

export type FighterSelectResult = CharacterSelectResult;
export const showCharacterSelect = mountFighterSelectScreen;
export type CharacterSelectResultLegacy = CharacterSelectResult;
