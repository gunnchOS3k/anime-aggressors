import type { StageDef } from "@anime-aggressors/game-core";

export type StageGridOptions = {
  stages: StageDef[];
  selectedId: string;
};

export function renderStageGrid({ stages, selectedId }: StageGridOptions): string {
  return `
    <div class="stage-select-grid" role="listbox" aria-label="Stage selection">
      ${stages
        .map(
          (s) => `
        <button
          type="button"
          class="stage-select-card ${s.id === selectedId ? "selected" : ""}"
          data-id="${s.id}"
          role="option"
          aria-selected="${s.id === selectedId}"
        >
          <strong>${s.name}</strong>
          ${s.hazardsEnabled ? "<small class=\"stage-tag\">hazards</small>" : ""}
        </button>`,
        )
        .join("")}
    </div>`;
}

export function bindStageGrid(root: HTMLElement, onSelect: (stageId: string) => void): void {
  root.querySelectorAll(".stage-select-card").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = (btn as HTMLButtonElement).dataset.id;
      if (id) onSelect(id);
    });
  });
}
