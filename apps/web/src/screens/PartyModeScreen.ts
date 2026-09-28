/**
 * Party Mode — Create Room → Lobby / Arena View (Jackbox-like display host).
 * Non-Party Custom Game remains 2P-ship blocked.
 */

import { navigateTo } from "../router.js";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";

export type PartyModeConfig = {
  playerCount: 2 | 3 | 4 | 5 | 6 | 7 | 8;
  teamMode: "FFA" | "2v2" | "3v3" | "4v4" | "2v2v2v2";
  hostName: string;
};

const STORAGE_KEY = "anime-aggressors.partyModeConfig";

export function loadPartyModeConfig(): PartyModeConfig {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw) as PartyModeConfig;
  } catch {
    /* ignore */
  }
  return { playerCount: 8, teamMode: "FFA", hostName: "Host" };
}

export function savePartyModeConfig(cfg: PartyModeConfig): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(cfg));
}

export function mountPartyModeScreen(root: HTMLElement): void {
  let cfg = loadPartyModeConfig();

  const render = () => {
    root.innerHTML = `
      <div class="party-mode setup-hero-panel" data-testid="party-mode-entry">
        <header>
          <p class="arena-hub__kicker">Same-room / LAN</p>
          <h1>Party Mode</h1>
          <p>Shared screen + phone/browser controllers. Public relay is not claimed.</p>
        </header>
        <label>Host display name
          <input id="pm-name" value="${cfg.hostName}" maxlength="24"/>
        </label>
        <fieldset data-testid="party-player-count">
          <legend>Players (2–8)</legend>
          ${([2, 3, 4, 5, 6, 7, 8] as const)
            .map(
              (n) =>
                `<label><input type="radio" name="pm-count" value="${n}" ${cfg.playerCount === n ? "checked" : ""}/> ${n}</label>`,
            )
            .join("")}
        </fieldset>
        <label>Team mode
          <select id="pm-team" data-testid="party-team-mode">
            ${(["FFA", "2v2", "3v3", "4v4", "2v2v2v2"] as const)
              .map(
                (m) =>
                  `<option value="${m}" ${cfg.teamMode === m ? "selected" : ""}>${m}</option>`,
              )
              .join("")}
          </select>
        </label>
        <div class="party-mode__actions">
          <button type="button" id="pm-back" class="${ARENA_CLASSES.secondaryBtn}">Back</button>
          <button type="button" id="pm-create" class="${ARENA_CLASSES.primaryCta}" data-testid="party-create-room">Create Room →</button>
        </div>
        <p class="party-mode__note">Join URL / QR appear on the Lobby / Arena View after create.</p>
      </div>`;

    root.querySelector("#pm-back")?.addEventListener("click", () => navigateTo("home"));
    root.querySelector("#pm-create")?.addEventListener("click", () => {
      const hostName =
        (root.querySelector("#pm-name") as HTMLInputElement).value.trim() || "Host";
      const playerCount = Number(
        (root.querySelector('input[name="pm-count"]:checked') as HTMLInputElement)?.value ?? 8,
      ) as PartyModeConfig["playerCount"];
      const teamMode = (root.querySelector("#pm-team") as HTMLSelectElement)
        .value as PartyModeConfig["teamMode"];
      cfg = { hostName, playerCount, teamMode };
      savePartyModeConfig(cfg);
      navigateTo("party-lobby");
    });
  };

  render();
}
