import type { CreatedFighter } from "@anime-aggressors/game-core";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { listCreatedFighters } from "../storage/createdFightersStorage.ts";

export function buildSelectableRoster(): CreatedFighter[] {
  const defaults = getAllDefaultCreatedFighters();
  const custom = listCreatedFighters();
  const customIds = new Set(custom.map((f) => f.id));
  return [...custom, ...defaults.filter((d) => !customIds.has(d.id))];
}

export type CharacterSelectState = {
  activePlayer: 0 | 1;
  focusedId: string | null;
  p1: CreatedFighter | null;
  p2: CreatedFighter | null;
};

export function createCharacterSelectState(
  roster: CreatedFighter[],
  initialP1?: CreatedFighter | null,
  initialP2?: CreatedFighter | null,
): CharacterSelectState {
  return {
    activePlayer: 0,
    focusedId: roster[0]?.id ?? null,
    p1: initialP1 ?? roster[0] ?? null,
    p2: initialP2 ?? roster[1] ?? roster[0] ?? null,
  };
}

export function setFocusedFighter(state: CharacterSelectState, fighterId: string): CharacterSelectState {
  return { ...state, focusedId: fighterId };
}

export function selectFighterForActivePlayer(
  state: CharacterSelectState,
  fighter: CreatedFighter,
): CharacterSelectState {
  if (state.activePlayer === 0) {
    const next: CharacterSelectState = { ...state, p1: fighter, focusedId: fighter.id };
    if (!state.p2) next.activePlayer = 1;
    else if (state.p1?.id === fighter.id && state.p2) next.activePlayer = 1;
    else next.activePlayer = 1;
    return next;
  }
  return { ...state, p2: fighter, focusedId: fighter.id, activePlayer: 1 };
}

export function setActivePlayer(state: CharacterSelectState, player: 0 | 1): CharacterSelectState {
  return { ...state, activePlayer: player };
}

export function isCharacterSelectReady(state: CharacterSelectState, mode: "match" | "derby" = "match"): boolean {
  if (mode === "derby") return !!state.p1;
  return !!(state.p1 && state.p2);
}

export function getFocusedFighter(state: CharacterSelectState, roster: CreatedFighter[]): CreatedFighter | null {
  if (!state.focusedId) return roster[0] ?? null;
  return roster.find((f) => f.id === state.focusedId) ?? roster[0] ?? null;
}

export type TileState = "default" | "focus" | "p1" | "p2" | "both";

export function tileStateForFighter(state: CharacterSelectState, fighterId: string): TileState {
  const p1 = state.p1?.id === fighterId;
  const p2 = state.p2?.id === fighterId;
  if (p1 && p2) return "both";
  if (p1) return "p1";
  if (p2) return "p2";
  if (state.focusedId === fighterId) return "focus";
  return "default";
}
