import type { EnergyClashState } from "@anime-aggressors/game-core";

export type EnergyClashPromptData = {
  clash: EnergyClashState;
  localPlayerId?: number;
};

export function renderEnergyClashPrompt({ clash }: EnergyClashPromptData): string {
  const intensity = Math.min(100, Math.round(clash.intensity));
  const balancePct = Math.max(0, Math.min(100, 50 + clash.balance / 2));

  return `
    <div class="training-overlay energy-clash-prompt" role="alert">
      <div class="energy-clash-title">ENERGY CLASH!</div>
      <div class="energy-clash-instructions">
        <span>Hold Special to push!</span>
        <span>Time Attack presses for surge!</span>
      </div>
      <div class="energy-clash-meter" aria-valuenow="${balancePct}" aria-valuemin="0" aria-valuemax="100">
        <div class="energy-clash-meter-fill" style="width: ${balancePct}%"></div>
      </div>
      <div class="energy-clash-intensity">Intensity ${intensity}%</div>
    </div>`;
}

export function isClashActive(clash: EnergyClashState | undefined): boolean {
  return clash?.phase === "starting" || clash?.phase === "struggling";
}
