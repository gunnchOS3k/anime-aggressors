import {
  FLAGLINE_ROOM_ORDER,
  getRoomLabel,
  type FlaglineClashState,
  type FlaglineRoomIndex,
} from "@anime-aggressors/game-core";

export function renderFlaglineMapStrip(current: FlaglineRoomIndex): string {
  return FLAGLINE_ROOM_ORDER.map((idx) => {
    const marker = idx === current ? "▲" : "·";
    const short =
      idx === -2
        ? "L.Base"
        : idx === -1
          ? "L.Out"
          : idx === 0
            ? "Center"
            : idx === 1
              ? "S.Out"
              : "S.Base";
    return `<span class="map-node ${idx === current ? "current" : ""}">${short}${marker}</span>`;
  }).join("");
}

export function mountFlaglineMapView(container: HTMLElement, current: FlaglineRoomIndex): void {
  container.innerHTML = `
    <div class="flagline-map-strip" aria-label="Frontline map">
      <span class="map-label lunar">Lunar Base</span>
      ${renderFlaglineMapStrip(current)}
      <span class="map-label solar">Solar Base</span>
    </div>
  `;
}

export function getMapStripOrder(): FlaglineRoomIndex[] {
  return [...FLAGLINE_ROOM_ORDER];
}

export function getRoomName(index: FlaglineRoomIndex): string {
  return getRoomLabel(index);
}

export function formatFlaglineAnnouncement(state: FlaglineClashState): string {
  const f = state.flagline;
  if (f.phase === "gameWon" && f.winningTeam) {
    const team = f.winningTeam === "solar" ? "Solar Team" : "Lunar Team";
    const base = f.winningTeam === "solar" ? "Lunar Base" : "Solar Base";
    return `${team} captured ${base}! ${team} wins Flagline Clash!`;
  }
  if (f.roomWinner) {
    const team = f.roomWinner === "solar" ? "Solar" : "Lunar";
    const next = getRoomLabel(f.currentRoomIndex);
    return `${team} captured the Flag Core! Frontline: ${next}`;
  }
  if (f.capture.contested) return "Contested!";
  return getRoomLabel(f.currentRoomIndex);
}
