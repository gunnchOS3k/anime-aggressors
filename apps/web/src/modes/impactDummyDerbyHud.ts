import type { ImpactDummyDerbyState } from "@anime-aggressors/game-core";
import { fpToDisplay, distanceDisplayUnits } from "@anime-aggressors/game-core";

export function derbyHudHtml(state: ImpactDummyDerbyState): string {
  const timerSec =
    state.phase === "damage"
      ? Math.ceil(state.timerFramesRemaining / 60)
      : state.phase === "finalLaunch"
        ? Math.ceil(state.finalLaunchFramesRemaining / 60)
        : 0;

  const prompt =
    state.phase === "finalLaunch" && state.kineticBat.equipped
      ? state.kineticBat.swingState === "active" && state.kineticBat.sweetSpotActive
        ? "Sweet spot!"
        : "Swing now!"
      : state.phase === "damage"
        ? "Damage the dummy!"
        : state.phase === "flight"
          ? "Launched!"
          : "";

  return `
    <div class="derby-hud-row">
      <span class="derby-prompt">${prompt}</span>
      <span>Dummy: ${state.dummy.damage}%</span>
      <span>Combo: ${state.comboCount} (best ${state.bestCombo})</span>
      <span>${state.kineticBat.equipped ? "Kinetic Bat equipped" : state.phase === "damage" ? "Build damage" : ""}</span>
      <span>Timer: ${timerSec}s</span>
    </div>
    ${
      state.phase === "flight"
        ? `<div class="derby-hud-row"><span>Distance: ${distanceDisplayUnits(state.flightDistance)}</span><span>Speed: ${fpToDisplay(state.finalLaunchSpeed)}</span></div>`
        : ""
    }
  `;
}
