import type { FlaglineClashState } from "@anime-aggressors/game-core";
import { mountFlaglineMapView, formatFlaglineAnnouncement, getRoomName } from "./FlaglineMapView.js";

export function renderFlaglineHUD(root: HTMLElement, state: FlaglineClashState): void {
  const f = state.flagline;
  const roomName = getRoomName(f.currentRoomIndex);
  const solarPct = Math.round((f.capture.solar / state.config.captureToWin) * 100);
  const lunarPct = Math.round((f.capture.lunar / state.config.captureToWin) * 100);

  root.innerHTML = `
    <div class="flagline-hud">
      <div class="flagline-hud-top">
        <strong>${roomName}</strong>
        <span class="flagline-phase">${f.phase}</span>
      </div>
      <div id="flagline-map-host"></div>
      <div class="capture-meters">
        <div class="capture solar"><span>Solar</span><div class="bar"><div class="fill" style="width:${solarPct}%"></div></div></div>
        <div class="capture lunar"><span>Lunar</span><div class="bar"><div class="fill" style="width:${lunarPct}%"></div></div></div>
      </div>
      ${f.capture.contested ? `<p class="contested">Contested — capture paused</p>` : ""}
      <p class="flagline-announce">${formatFlaglineAnnouncement(state)}</p>
      <div class="team-status">
        ${state.teamSlots
          .map((s) => {
            const p = state.game.players[s.playerId];
            const tag = s.isBot ? "Bot" : `P${s.playerId + 1}`;
            return `<span class="team-${s.teamId}">${tag}: ${p.fighterName} · ${p.damage}% · ${p.stocks}♥</span>`;
          })
          .join("")}
      </div>
    </div>
  `;
  const mapHost = root.querySelector("#flagline-map-host") as HTMLElement;
  if (mapHost) mountFlaglineMapView(mapHost, f.currentRoomIndex);
}
