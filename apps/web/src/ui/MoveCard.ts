import type { MoveDefinition } from "@anime-aggressors/game-core";
import { MOVE_SLOT_INPUT_HINT } from "@anime-aggressors/game-core";

export type MoveCardOptions = {
  move: MoveDefinition;
  followUps?: string[];
};

function purposeForMove(move: MoveDefinition): string {
  if (move.comboStarter) return "combo starter / approach";
  if (move.comboFinisher) return "finisher / kill confirm";
  if (move.comboExtender) return "combo extender";
  if (move.category === "special") return "special tool";
  if (move.category === "throw") return "grab / throw";
  if (move.slot === "super") return "super / beam clash";
  return "neutral option";
}

export function renderMoveCard({ move, followUps = [] }: MoveCardOptions): string {
  const input = MOVE_SLOT_INPUT_HINT[move.slot] ?? move.slot;
  const cancels = move.cancelInto?.length
    ? move.cancelInto.map((s) => MOVE_SLOT_INPUT_HINT[s] ?? s).join(", ")
    : "—";
  const followUpText = followUps.length ? followUps.join(", ") : cancels !== "—" ? cancels : "—";

  return `
    <article class="move-card" data-move-id="${move.id}">
      <header class="move-card-header">
        <span class="move-input">${input}</span>
        <h4 class="move-name">${move.displayName}</h4>
      </header>
      <dl class="move-card-details">
        <div><dt>Purpose</dt><dd>${purposeForMove(move)}</dd></div>
        <div><dt>Difficulty</dt><dd class="skill-${move.skillFloor}">${move.skillFloor}</dd></div>
        <div><dt>Cancel into</dt><dd>${cancels}</dd></div>
        <div><dt>Follow-ups</dt><dd>${followUpText}</dd></div>
        <div><dt>Frame data</dt><dd>${move.startupFrames} / ${move.activeFrames} / ${move.recoveryFrames}</dd></div>
      </dl>
      <p class="move-visual-hint">${move.tags.join(" · ")} · ${move.animationKey}</p>
    </article>`;
}
