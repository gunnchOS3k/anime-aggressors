import { listStages } from "@anime-aggressors/game-core";

export function mountStageSelectScreen(
  root: HTMLElement,
  currentStageId: string,
  onSelect: (stageId: string) => void,
): void {
  const stages = listStages();
  root.innerHTML = `
    <div class="screen stage-select">
      <h3>Stage</h3>
      ${stages
        .map(
          (s) =>
            `<button type="button" class="stage-pick ${s.id === currentStageId ? "selected" : ""}" data-id="${s.id}">${s.name}${s.placeholder ? " (placeholder)" : ""}</button>`,
        )
        .join("")}
    </div>
  `;
  root.querySelectorAll(".stage-pick").forEach((btn) => {
    btn.addEventListener("click", () => onSelect((btn as HTMLButtonElement).dataset.id!));
  });
}
