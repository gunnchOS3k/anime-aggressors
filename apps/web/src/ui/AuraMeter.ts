import type { AuraChargeState } from "@anime-aggressors/game-core";
import { isSuperReady } from "@anime-aggressors/game-core";
import type { FighterColor } from "@anime-aggressors/game-core";
import { renderElementIcon } from "./ElementIcon.ts";

export function renderAuraMeter(aura: AuraChargeState, color: FighterColor, side: "left" | "right"): string {
  const pct = Math.round((aura.current / aura.max) * 100);
  const levelLabel = aura.level > 0 ? `L${aura.level}` : "";
  const charging = aura.charging ? " charging" : "";
  const ready = isSuperReady(aura) ? " super-ready" : "";
  return `
    <div class="pf-aura-meter pf-aura-meter--${side}${charging}${ready}" aria-label="Aura ${pct}%">
      ${renderElementIcon(color)}
      <div class="pf-aura-track">
        <div class="pf-aura-fill pf-aura-fill--level-${aura.level}" style="width:${pct}%"></div>
      </div>
      <span class="pf-aura-label">${levelLabel || "Aura"}</span>
    </div>`;
}
