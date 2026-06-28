import type { AuraChargeState } from "@anime-aggressors/game-core";
import { isSuperReady } from "@anime-aggressors/game-core";

export function renderSuperReadyBadge(aura: AuraChargeState): string {
  if (!isSuperReady(aura)) return "";
  return `<span class="pf-super-ready-badge" aria-label="Super Ready">SUPER READY</span>`;
}
