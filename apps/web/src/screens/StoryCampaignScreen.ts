import {
  SPECTRUM_STORY_FIGHTER_IDS,
  completeGrayRoute,
  essenceTierName,
  isCosmicPlayable,
  presentationModifiers,
  setCosmicDevOverride,
  setEssenceCount,
  setPuppetForm,
  type StoryProgressState,
  type StoryPuppetForm,
  type StoryRouteId,
} from "@anime-aggressors/game-core";
import { APP_ROUTES } from "../routes.ts";
import { loadStoryProgress, resetStoryProgress, saveStoryProgress } from "../storage/storyProgressStorage.ts";

function render(state: StoryProgressState): string {
  const mods = presentationModifiers(state);
  const routes = SPECTRUM_STORY_FIGHTER_IDS.map((id) => {
    const route = state.routes[id];
    return `<li class="story-route ${route.completed ? "story-route--done" : ""}" data-route="${id}">
      <strong>${route.draftTitle}</strong>
      <p>${route.draftSummary}</p>
      <button type="button" data-complete-route="${id}">Complete Gray Route (QA)</button>
      ${route.isRoot ? '<span class="story-root-badge">ROOT</span>' : ""}
      ${route.completed ? '<span class="story-done-badge">GRAY COMPLETE</span>' : ""}
    </li>`;
  }).join("");

  return `
    <section class="screen story-campaign-screen" data-testid="story-campaign">
      <header class="screen-header">
        <a href="${APP_ROUTES.home}">← Home</a>
        <h1>Story Campaign</h1>
        <p class="lede">Kaia / Green root → seven Gray routes → unlock Yin + Yang. Narrative copy marked DRAFT where temporary.</p>
      </header>
      <div class="story-status">
        <p>Essence: <strong>${state.essenceCount}</strong> (${essenceTierName(state.essenceCount)})</p>
        <p>Puppet form: <strong>${mods.puppetForm}</strong> — ${mods.motionNote}</p>
        <p>Gray routes: <strong>${state.grayRoutesCompleted.length}/7</strong></p>
        <p>Yin unlocked: <strong>${isCosmicPlayable(state, "yin") ? "YES" : "NO"}</strong>
           · Yang unlocked: <strong>${isCosmicPlayable(state, "yang") ? "YES" : "NO"}</strong>
           ${state.cosmicDevOverride ? " (dev override)" : ""}</p>
      </div>
      <div class="story-controls">
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
          Dev unlock Yin/Yang (QA — does not corrupt story completion flags when cleared)
        </label>
        <button type="button" id="story-reset">Reset story progress</button>
        <a class="btn" href="${APP_ROUTES.fighterSelect}">Open Fighter Select</a>
        <a class="btn" href="${APP_ROUTES.matchSetupFighters}">Match Setup Fighters</a>
      </div>
      <ol class="story-routes">${routes}</ol>
    </section>
  `;
}

export function mountStoryCampaignScreen(root: HTMLElement): void {
  let state = loadStoryProgress();

  const paint = () => {
    root.innerHTML = render(state);
    root.querySelector("#story-essence")?.addEventListener("change", (e) => {
      const v = Number((e.target as HTMLSelectElement).value);
      state = setEssenceCount(state, v);
      saveStoryProgress(state);
      paint();
    });
    root.querySelector("#story-puppet")?.addEventListener("change", (e) => {
      const v = (e.target as HTMLSelectElement).value as StoryPuppetForm;
      state = setPuppetForm(state, v);
      saveStoryProgress(state);
      paint();
    });
    root.querySelector("#story-cosmic-override")?.addEventListener("change", (e) => {
      state = setCosmicDevOverride(state, (e.target as HTMLInputElement).checked);
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
        state = completeGrayRoute(state, id);
        saveStoryProgress(state);
        paint();
      });
    });
  };

  paint();
}
