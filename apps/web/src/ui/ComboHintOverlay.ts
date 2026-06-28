export type ComboHintOverlayData = {
  hint: string;
  suggestedInput?: string;
};

export function renderComboHintOverlay({ hint, suggestedInput }: ComboHintOverlayData): string {
  return `
    <div class="training-overlay combo-hint-overlay" aria-live="polite">
      <div class="training-overlay-label">Combo Hint</div>
      <p class="combo-hint-text">${hint}</p>
      ${suggestedInput ? `<div class="combo-hint-input">Try: <strong>${suggestedInput}</strong></div>` : ""}
    </div>`;
}

export function comboHintFromRoute(routeDescription: string, teachingHint: string): ComboHintOverlayData {
  return {
    hint: routeDescription,
    suggestedInput: teachingHint.split(".")[0],
  };
}
