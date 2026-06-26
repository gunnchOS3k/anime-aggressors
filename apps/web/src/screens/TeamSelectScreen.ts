import type { CreatedFighter, TeamSlot, FlaglineConfig } from "@anime-aggressors/game-core";
import {
  createDefaultTeamSlots,
  FLAGLINE_DEFAULTS,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";
import { listCreatedFighters } from "../storage/createdFightersStorage.js";
import { navigateTo } from "../router.js";

export type TeamSelectResult = {
  teamSlots: TeamSlot[];
  config: FlaglineConfig;
};

let pendingResult: TeamSelectResult | null = null;

export function getPendingTeamSelect(): TeamSelectResult | null {
  return pendingResult;
}

export function clearPendingTeamSelect(): void {
  pendingResult = null;
}

export function mountTeamSelectScreen(
  root: HTMLElement,
  onStart: (result: TeamSelectResult) => void,
): void {
  const roster = listCreatedFighters();
  const defaults = [0, 1, 2, 3].map((i) => getDefaultCreatedFighter(i));
  const fighters = roster.length >= 2 ? roster : defaults;

  let slots = createDefaultTeamSlots(fighters);
  let config: FlaglineConfig = { ...FLAGLINE_DEFAULTS };

  const render = () => {
    root.innerHTML = `
      <div class="screen team-select">
        <h2>Flagline Clash — Team Select</h2>
        <p class="hint">Solar vs Lunar · 2v2 · Empty slots use bots</p>
        <div class="team-columns">
          <div class="team-col solar-col">
            <h3>Solar Team</h3>
            ${slots
              .filter((s) => s.teamId === "solar")
              .map(
                (s) => `
              <label>P${s.playerId + 1} ${s.isBot ? "(Bot)" : ""}
                <select data-slot="${s.playerId}" class="fighter-pick-select">
                  ${fighters.map((f) => `<option value="${f.id}" ${s.fighter?.id === f.id ? "selected" : ""}>${f.name}</option>`).join("")}
                </select>
                <label><input type="checkbox" data-bot="${s.playerId}" ${s.isBot ? "checked" : ""}/> Bot</label>
              </label>`,
              )
              .join("")}
          </div>
          <div class="team-col lunar-col">
            <h3>Lunar Team</h3>
            ${slots
              .filter((s) => s.teamId === "lunar")
              .map(
                (s) => `
              <label>P${s.playerId + 1} ${s.isBot ? "(Bot)" : ""}
                <select data-slot="${s.playerId}" class="fighter-pick-select">
                  ${fighters.map((f) => `<option value="${f.id}" ${s.fighter?.id === f.id ? "selected" : ""}>${f.name}</option>`).join("")}
                </select>
                <label><input type="checkbox" data-bot="${s.playerId}" ${s.isBot ? "checked" : ""}/> Bot</label>
              </label>`,
              )
              .join("")}
          </div>
        </div>
        <label>Bots enabled <input type="checkbox" id="ts-bots" ${config.botsEnabled ? "checked" : ""}/></label>
        <div class="create-actions">
          <button type="button" id="ts-back" class="btn-secondary">Back</button>
          <button type="button" id="ts-start" class="btn-primary">Start Flagline Clash</button>
        </div>
      </div>
    `;

    root.querySelector("#ts-back")?.addEventListener("click", () => navigateTo("flagline-setup"));
    root.querySelectorAll("[data-slot]").forEach((el) => {
      el.addEventListener("change", () => {
        const id = Number((el as HTMLSelectElement).dataset.slot);
        const fighter = fighters.find((f) => f.id === (el as HTMLSelectElement).value)!;
        slots = slots.map((s) => (s.playerId === id ? { ...s, fighter, fighterId: fighter.id } : s));
      });
    });
    root.querySelectorAll("[data-bot]").forEach((el) => {
      el.addEventListener("change", () => {
        const id = Number((el as HTMLInputElement).dataset.bot);
        const isBot = (el as HTMLInputElement).checked;
        if (id <= 1 && isBot) return;
        slots = slots.map((s) => (s.playerId === id ? { ...s, isBot } : s));
        if (id <= 1) slots = slots.map((s) => (s.playerId === id ? { ...s, isBot: false } : s));
        render();
      });
    });
    root.querySelector("#ts-bots")?.addEventListener("change", (e) => {
      config.botsEnabled = (e.target as HTMLInputElement).checked;
      if (!config.botsEnabled) {
        slots = slots.map((s) => ({ ...s, isBot: s.playerId > 1 ? false : s.isBot }));
      }
    });
    root.querySelector("#ts-start")?.addEventListener("click", () => {
      if (!config.botsEnabled) {
        slots = slots.map((s) => ({ ...s, isBot: false }));
      }
      const result = { teamSlots: slots, config };
      pendingResult = result;
      onStart(result);
    });
  };

  render();
}
