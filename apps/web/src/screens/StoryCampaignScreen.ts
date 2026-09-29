import {
  SPECTRUM_STORY_FIGHTER_IDS,
  advanceAfterWin,
  encounterConfig,
  essenceTierName,
  getActiveNode,
  isCosmicPlayable,
  presentationModifiers,
  recordLoss,
  startRoute,
  type StoryDirectorState,
  type StoryRouteId,
} from "@anime-aggressors/game-core";
import { APP_ROUTES } from "../routes.ts";
import {
  isStoryDevMode,
  loadStoryProgress,
  resetStoryProgress,
  saveStoryProgress,
} from "../storage/storyProgressStorage.ts";
import {
  completeGrayRoute,
  setCosmicDevOverride,
  setEssenceCount,
  setPuppetForm,
  type StoryPuppetForm,
} from "@anime-aggressors/game-core";

function render(state: StoryDirectorState, dev: boolean): string {
  const mods = presentationModifiers(state);
  const node = getActiveNode(state);
  const enc = encounterConfig(state);

  const routeCards = SPECTRUM_STORY_FIGHTER_IDS.map((id) => {
    const route = state.routes[id];
    return `<li class="story-route ${route.completed ? "story-route--done" : ""}" data-testid="story-route-${id}">
      <strong>${route.draftTitle}</strong>
      <p>${route.draftSummary}</p>
      <button type="button" class="btn" data-start-route="${id}" data-testid="start-route-${id}">Enter Route</button>
      ${route.isRoot ? '<span class="story-root-badge">ROOT</span>' : ""}
      ${route.completed ? '<span class="story-done-badge">GRAY COMPLETE</span>' : ""}
      ${dev ? `<button type="button" data-complete-route="${id}">Complete Gray Route (QA)</button>` : ""}
    </li>`;
  }).join("");

  const nodePanel = node
    ? `<section class="story-node" data-testid="story-active-node" data-node-kind="${node.kind}">
        <h2>${node.title}</h2>
        <p>${node.body}</p>
        ${
          enc
            ? `<a class="btn" data-testid="story-launch-encounter" href="${APP_ROUTES.matchSetupFighters}">Launch Encounter</a>
               <button type="button" class="btn" data-testid="story-sim-win" id="story-sim-win">Record Win (advance)</button>
               <button type="button" class="btn" data-testid="story-sim-loss" id="story-sim-loss">Record Loss (retry)</button>`
            : `<button type="button" class="btn" data-testid="story-advance" id="story-advance">Continue</button>`
        }
        ${state.pendingRetryNodeId ? `<p class="story-retry">Retry ready — prior progress preserved.</p>` : ""}
      </section>`
    : `<p class="lede">Select a route to begin. Kaia is the green root.</p>`;

  const qa = dev
    ? `<div class="story-controls story-controls--qa" data-testid="story-qa-drawer">
        <p><em>QA drawer (?dev=1)</em></p>
        <label>Essence tier
          <select id="story-essence">
            ${[0, 1, 2, 4, 6].map((n) => `<option value="${n}" ${state.essenceCount === n ? "selected" : ""}>${n}</option>`).join("")}
          </select>
        </label>
        <label>Puppet form
          <select id="story-puppet">
            ${(["NORMAL", "BLACK_PUPPET", "WHITE_PUPPET"] as StoryPuppetForm[])
              .map((f) => `<option value="${f}" ${state.puppetForm === f ? "selected" : ""}>${f}</option>`)
              .join("")}
          </select>
        </label>
        <label class="story-dev-override">
          <input type="checkbox" id="story-cosmic-override" ${state.cosmicDevOverride ? "checked" : ""} />
          Dev unlock Yin/Yang
        </label>
        <button type="button" id="story-reset">Reset story progress</button>
      </div>`
    : "";

  return `
    <section class="screen story-campaign-screen" data-testid="story-campaign">
      <header class="screen-header">
        <a href="${APP_ROUTES.home}">← Home</a>
        <h1>Story Campaign</h1>
        <p class="lede">Seven routes. Real encounters. Gray unlocks Yin + Yang. Narrative: DRAFT_NARRATIVE_COPY.</p>
      </header>
      <div class="story-status" data-testid="story-status">
        <p>Essence: <strong>${state.essenceCount}</strong> (${essenceTierName(state.essenceCount)})</p>
        <p>Puppet form: <strong>${mods.puppetForm}</strong> — ${mods.motionNote}</p>
        <p>Gray routes: <strong>${state.grayRoutesCompleted.length}/7</strong></p>
        <p>Yin: <strong>${isCosmicPlayable(state, "yin") ? "UNLOCKED" : "LOCKED"}</strong>
           · Yang: <strong>${isCosmicPlayable(state, "yang") ? "UNLOCKED" : "LOCKED"}</strong></p>
      </div>
      ${nodePanel}
      ${qa}
      <p><a class="btn" href="${APP_ROUTES.fighterSelect}">Fighter Select</a></p>
      <ol class="story-routes" data-testid="story-route-list">${routeCards}</ol>
    </section>
  `;
}

export function mountStoryCampaignScreen(root: HTMLElement): void {
  let state = loadStoryProgress();
  const dev = isStoryDevMode();

  const paint = () => {
    root.innerHTML = render(state, dev);
    root.querySelectorAll<HTMLButtonElement>("[data-start-route]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state = startRoute(state, btn.dataset.startRoute as StoryRouteId);
        saveStoryProgress(state);
        paint();
      });
    });
    root.querySelector("#story-advance")?.addEventListener("click", () => {
      state = advanceAfterWin(state);
      saveStoryProgress(state);
      paint();
    });
    root.querySelector("#story-sim-win")?.addEventListener("click", () => {
      state = advanceAfterWin(state);
      saveStoryProgress(state);
      paint();
    });
    root.querySelector("#story-sim-loss")?.addEventListener("click", () => {
      state = recordLoss(state);
      saveStoryProgress(state);
      paint();
    });
    if (dev) {
      root.querySelector("#story-essence")?.addEventListener("change", (e) => {
        state = { ...setEssenceCount(state, Number((e.target as HTMLSelectElement).value)), ...pickDirector(state) };
        saveStoryProgress(state);
        paint();
      });
      root.querySelector("#story-puppet")?.addEventListener("change", (e) => {
        state = { ...setPuppetForm(state, (e.target as HTMLSelectElement).value as StoryPuppetForm), ...pickDirector(state) };
        saveStoryProgress(state);
        paint();
      });
      root.querySelector("#story-cosmic-override")?.addEventListener("change", (e) => {
        state = { ...setCosmicDevOverride(state, (e.target as HTMLInputElement).checked), ...pickDirector(state) };
        saveStoryProgress(state);
        paint();
      });
      root.querySelector("#story-reset")?.addEventListener("click", () => {
        state = resetStoryProgress();
        paint();
      });
      root.querySelectorAll<HTMLButtonElement>("[data-complete-route]").forEach((btn) => {
        btn.addEventListener("click", () => {
          const id = btn.dataset.completeRoute as StoryRouteId;
          const next = completeGrayRoute(state, id);
          state = { ...next, ...pickDirector(state) } as StoryDirectorState;
          saveStoryProgress(state);
          paint();
        });
      });
    }
  };

  paint();
}

function pickDirector(state: StoryDirectorState): Pick<StoryDirectorState, "activeNodeId" | "completedNodeIds" | "pendingRetryNodeId" | "schema"> {
  return {
    schema: "story_progress_v1_5",
    activeNodeId: state.activeNodeId,
    completedNodeIds: state.completedNodeIds,
    pendingRetryNodeId: state.pendingRetryNodeId,
  };
}
