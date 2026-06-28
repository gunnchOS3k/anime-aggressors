import type { PlayerState } from "@anime-aggressors/game-core";
import { getMoveById, MOVE_SLOT_INPUT_HINT } from "@anime-aggressors/game-core";

export type TrainingMoveOverlayData = {
  player: PlayerState;
  comboCount?: number;
};

export function renderTrainingMoveOverlay({ player, comboCount = 0 }: TrainingMoveOverlayData): string {
  const move = getMoveById(player.currentMoveId);
  const moveName = move?.displayName ?? (player.currentMoveId === "none" ? "—" : player.currentMoveId);
  const input = move ? (MOVE_SLOT_INPUT_HINT[move.slot] ?? move.slot) : "—";
  const followUps = move?.cancelInto?.length
    ? move.cancelInto.map((s) => MOVE_SLOT_INPUT_HINT[s] ?? s).join(" → ")
    : "";

  return `
    <div class="training-overlay training-move-overlay" aria-live="polite">
      <div class="training-overlay-label">Current Move</div>
      <div class="training-move-name">${moveName}</div>
      <div class="training-move-input">${input}</div>
      ${followUps ? `<div class="training-follow-up">Try: ${followUps}</div>` : ""}
      ${comboCount > 0 ? `<div class="training-combo-count">Combo ×${comboCount}</div>` : ""}
    </div>`;
}
