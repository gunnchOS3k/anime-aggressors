import type { CreatedFighter } from "@anime-aggressors/game-core";
import type { CharacterSelectState } from "../characterSelect/characterSelectState.js";
import { tileStateForFighter } from "../characterSelect/characterSelectState.js";
import { renderCharacterTile } from "./CharacterTile.js";
import { ARENA_CLASSES } from "./theme/arenaClasses.ts";

export type CharacterGridOptions = {
  roster: CreatedFighter[];
  state: CharacterSelectState;
};

export function renderCharacterGrid({ roster, state }: CharacterGridOptions): string {
  return `
    <div class="${ARENA_CLASSES.portraitGrid} cs-grid character-portrait-grid" role="listbox" aria-label="Fighter roster">
      ${roster
        .map((fighter) =>
          renderCharacterTile({
            fighter,
            state: tileStateForFighter(state, fighter.id),
            tabIndex: state.focusedId === fighter.id ? 0 : -1,
          }),
        )
        .join("")}
    </div>`;
}

export function gridFighterIndex(roster: CreatedFighter[], fighterId: string): number {
  return roster.findIndex((f) => f.id === fighterId);
}

export function navigateGrid(roster: CreatedFighter[], currentId: string, dx: number, dy: number): string {
  const cols = 4;
  const idx = Math.max(0, gridFighterIndex(roster, currentId));
  const row = Math.floor(idx / cols);
  const col = idx % cols;
  const newRow = Math.max(0, Math.min(Math.ceil(roster.length / cols) - 1, row + dy));
  const newCol = Math.max(0, Math.min(cols - 1, col + dx));
  const newIdx = Math.min(roster.length - 1, newRow * cols + newCol);
  return roster[newIdx]?.id ?? currentId;
}
