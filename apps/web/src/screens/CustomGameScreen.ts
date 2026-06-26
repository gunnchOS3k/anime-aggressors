import type { GameRuleset, MatchType, ElementMode, ItemFrequency, TeamMode } from "@anime-aggressors/game-core";
import { listStages } from "@anime-aggressors/game-core";
import {
  getActiveRuleset,
  saveRuleset,
  setActiveRulesetId,
} from "../storage/rulesetStorage.js";
import { navigateTo } from "../router.js";
import { setMatchRuleset, setCustomFlow } from "../match/matchSession.js";

const STOCK_OPTIONS = [1, 2, 3, 4, 5];
const TIMER_OPTIONS: { label: string; seconds: number | null }[] = [
  { label: "1:00", seconds: 60 },
  { label: "2:00", seconds: 120 },
  { label: "3:00", seconds: 180 },
  { label: "5:00", seconds: 300 },
  { label: "8:00", seconds: 480 },
  { label: "Off", seconds: null },
];
const STAMINA_OPTIONS = [50, 100, 150, 200, 300];
const RATIO_OPTIONS = [0.5, 0.75, 1, 1.25, 1.5, 2];
const ITEM_OPTIONS: ItemFrequency[] = ["off", "low", "medium", "high"];

function ratioLabel(v: number): string {
  return `${v}x`;
}

export function mountCustomGameScreen(root: HTMLElement): void {
  let ruleset: GameRuleset = { ...getActiveRuleset() };
  const stages = listStages();

  const render = () => {
    const staminaVisible = ruleset.matchType === "stamina";
    const flaglineVisible = ruleset.matchType === "flaglineClash";
    root.innerHTML = `
      <div class="screen custom-game">
        <div class="screen-toolbar">
          <button type="button" id="cg-back" class="btn-secondary">← Home</button>
          <h2>Custom Game</h2>
          <button type="button" id="cg-rulesets" class="btn-secondary">Saved Rules</button>
        </div>
        <p class="hint">Set match rules, then pick fighters and controls.</p>

        <div class="cg-grid">
          <label>Ruleset Name<input id="cg-name" value="${ruleset.name}" /></label>

          <fieldset>
            <legend>Match Type</legend>
            ${(["stock", "time", "stamina", "flaglineClash"] as MatchType[])
              .map(
                (t) =>
                  `<label><input type="radio" name="matchType" value="${t}" ${ruleset.matchType === t ? "checked" : ""}/> ${t}</label>`,
              )
              .join("")}
          </fieldset>

          <fieldset>
            <legend>Players</legend>
            ${([2, 3, 4] as const)
              .map((n) => {
                const blocked = n > 2;
                return `<label><input type="radio" name="playerCount" value="${n}" ${ruleset.playerCount === n ? "checked" : ""} ${blocked ? "disabled" : ""}/> ${n}${blocked ? " <small>(SHIP BLOCKED)</small>" : ""}</label>`;
              })
              .join("")}
          </fieldset>

          <label class="${flaglineVisible ? "" : "hidden"}">Team size
            <select id="cg-flagline-teams"><option value="2v2" selected>2v2</option></select>
          </label>
          <label class="${flaglineVisible ? "" : "hidden"}">Bots
            <select id="cg-flagline-bots"><option value="on" ${ruleset.flagline?.botsEnabled !== false ? "selected" : ""}>On</option><option value="off" ${ruleset.flagline?.botsEnabled === false ? "selected" : ""}>Off</option></select>
          </label>
          <label class="${flaglineVisible ? "" : "hidden"}">Capture speed
            <select id="cg-flagline-capture">${[8, 12, 16].map((v) => `<option value="${v}" ${(ruleset.flagline?.captureRatePerSecond ?? 12) === v ? "selected" : ""}>${v}/s</option>`).join("")}</select>
          </label>
          <label class="${flaglineVisible ? "" : "hidden"}">Team wipe wins room
            <select id="cg-flagline-wipe"><option value="off" ${!ruleset.flagline?.teamWipeWinsRoom ? "selected" : ""}>Off</option><option value="on" ${ruleset.flagline?.teamWipeWinsRoom ? "selected" : ""}>On</option></select>
          </label>
          <label class="${flaglineVisible ? "" : "hidden"}">Overtime
            <select id="cg-flagline-ot"><option value="on" ${ruleset.flagline?.overtimeEnabled !== false ? "selected" : ""}>On</option><option value="off" ${ruleset.flagline?.overtimeEnabled === false ? "selected" : ""}>Off</option></select>
          </label>
          <label class="${flaglineVisible ? "" : "hidden"}">Starting room
            <select id="cg-flagline-start"><option value="0" selected>Center Clash</option></select>
          </label>

          <label>Stocks
            <select id="cg-stocks">${STOCK_OPTIONS.map((s) => `<option value="${s}" ${ruleset.stocks === s ? "selected" : ""}>${s}</option>`).join("")}</select>
          </label>

          <label>Timer
            <select id="cg-timer">${TIMER_OPTIONS.map((t) => `<option value="${t.seconds ?? "off"}" ${ruleset.timerSeconds === t.seconds ? "selected" : ""}>${t.label}</option>`).join("")}</select>
          </label>

          <label class="${staminaVisible ? "" : "hidden"}">Stamina HP
            <select id="cg-stamina">${STAMINA_OPTIONS.map((h) => `<option value="${h}" ${ruleset.staminaHp === h ? "selected" : ""}>${h} HP</option>`).join("")}</select>
          </label>

          <label>Stage
            <select id="cg-stage">${stages.map((s) => `<option value="${s.id}" ${ruleset.stageId === s.id ? "selected" : ""}>${s.name}${s.placeholder ? " (placeholder)" : ""}</option>`).join("")}</select>
          </label>

          <label>Hazards
            <select id="cg-hazards"><option value="off" ${!ruleset.hazardsEnabled ? "selected" : ""}>Off</option><option value="on" ${ruleset.hazardsEnabled ? "selected" : ""}>On</option></select>
          </label>

          <label>Items
            <select id="cg-items">${ITEM_OPTIONS.map((i) => `<option value="${i}" ${ruleset.itemFrequency === i ? "selected" : ""}>${i}</option>`).join("")}</select>
          </label>

          <label>Damage Ratio
            <select id="cg-damage">${RATIO_OPTIONS.map((r) => `<option value="${r}" ${ruleset.damageRatio === r ? "selected" : ""}>${ratioLabel(r)}</option>`).join("")}</select>
          </label>

          <label>Launch Ratio
            <select id="cg-launch">${RATIO_OPTIONS.map((r) => `<option value="${r}" ${ruleset.launchRatio === r ? "selected" : ""}>${ratioLabel(r)}</option>`).join("")}</select>
          </label>

          <label>Element Effects
            <select id="cg-elements">${(["on", "visualOnly", "off"] as ElementMode[]).map((m) => `<option value="${m}" ${ruleset.elementMode === m ? "selected" : ""}>${m === "visualOnly" ? "Visual Only" : m === "on" ? "On" : "Off"}</option>`).join("")}</select>
          </label>

          <label>Teams
            <select id="cg-teams">
              <option value="off" ${ruleset.teamMode === "off" ? "selected" : ""}>Off</option>
              <option value="2v2" disabled ${ruleset.teamMode === "2v2" ? "selected" : ""}>2v2 (SHIP BLOCKED)</option>
            </select>
          </label>

          <label>Created Fighters
            <select id="cg-created">${(["allowed", "defaultsOnly"] as const).map((v) => `<option value="${v}" ${ruleset.createdFighters === v ? "selected" : ""}>${v === "allowed" ? "Allowed" : "Defaults Only"}</option>`).join("")}</select>
          </label>
        </div>

        <div class="create-actions">
          <button type="button" id="cg-save" class="btn-secondary">Save Rules</button>
          <button type="button" id="cg-continue" class="btn-primary">Choose Fighters →</button>
        </div>
      </div>
    `;

    bind();
  };

  const readForm = () => {
    const name = (root.querySelector("#cg-name") as HTMLInputElement).value.trim() || "Custom Rules";
    const matchType = (root.querySelector('input[name="matchType"]:checked') as HTMLInputElement)?.value as MatchType;
    const playerCount = Number((root.querySelector('input[name="playerCount"]:checked') as HTMLInputElement)?.value) as 2 | 3 | 4;
    const timerRaw = (root.querySelector("#cg-timer") as HTMLSelectElement).value;
    ruleset = {
      ...ruleset,
      name,
      matchType,
      playerCount: playerCount > 2 ? 2 : playerCount,
      stocks: Number((root.querySelector("#cg-stocks") as HTMLSelectElement).value),
      timerSeconds: timerRaw === "off" ? null : Number(timerRaw),
      staminaHp: Number((root.querySelector("#cg-stamina") as HTMLSelectElement)?.value ?? ruleset.staminaHp),
      stageId: (root.querySelector("#cg-stage") as HTMLSelectElement).value,
      hazardsEnabled: (root.querySelector("#cg-hazards") as HTMLSelectElement).value === "on",
      itemFrequency: (root.querySelector("#cg-items") as HTMLSelectElement).value as ItemFrequency,
      damageRatio: Number((root.querySelector("#cg-damage") as HTMLSelectElement).value),
      launchRatio: Number((root.querySelector("#cg-launch") as HTMLSelectElement).value),
      elementMode: (root.querySelector("#cg-elements") as HTMLSelectElement).value as ElementMode,
      teamMode: (root.querySelector("#cg-teams") as HTMLSelectElement).value as TeamMode,
      createdFighters: (root.querySelector("#cg-created") as HTMLSelectElement).value as GameRuleset["createdFighters"],
    };
    if (ruleset.matchType === "flaglineClash") {
      ruleset.flagline = {
        enabled: true,
        captureToWin: 100,
        captureRatePerSecond: Number((root.querySelector("#cg-flagline-capture") as HTMLSelectElement)?.value ?? 12),
        decayRatePerSecond: 4,
        overtimeEnabled: (root.querySelector("#cg-flagline-ot") as HTMLSelectElement)?.value !== "off",
        teamWipeWinsRoom: (root.querySelector("#cg-flagline-wipe") as HTMLSelectElement)?.value === "on",
        botsEnabled: (root.querySelector("#cg-flagline-bots") as HTMLSelectElement)?.value !== "off",
      };
      ruleset.teamMode = "2v2";
      ruleset.playerCount = 4;
      ruleset.stageId = "flagline-center-clash";
    }
  };

  const bind = () => {
    root.querySelector("#cg-back")?.addEventListener("click", () => navigateTo("home"));
    root.querySelector("#cg-rulesets")?.addEventListener("click", () => navigateTo("rulesets"));
    root.querySelectorAll('input[name="matchType"]').forEach((el) =>
      el.addEventListener("change", () => {
        readForm();
        render();
      }),
    );
    root.querySelector("#cg-save")?.addEventListener("click", () => {
      readForm();
      const saved = saveRuleset(ruleset);
      setActiveRulesetId(saved.id);
      ruleset = saved;
      alert("Rules saved.");
    });
    root.querySelector("#cg-continue")?.addEventListener("click", () => {
      readForm();
      const saved = saveRuleset(ruleset);
      setActiveRulesetId(saved.id);
      setMatchRuleset(saved);
      setCustomFlow(true);
      if (saved.matchType === "flaglineClash") {
        navigateTo("flagline-teams");
      } else {
        navigateTo("fighter-select");
      }
    });
  };

  render();
}
