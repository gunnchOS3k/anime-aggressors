import type { CreatedFighter, FighterBodyVariant } from "@anime-aggressors/game-core";
import { normalizeBodyVariant, oppositeBodyVariant } from "@anime-aggressors/game-core";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { listCreatedFighters } from "../storage/createdFightersStorage.ts";

export function buildSelectableRoster(): CreatedFighter[] {
  const defaults = getAllDefaultCreatedFighters();
  const custom = listCreatedFighters();
  const customIds = new Set(custom.map((f) => f.id));
  return [...custom, ...defaults.filter((d) => !customIds.has(d.id))];
}

export type SeatSelection = {
  fighter: CreatedFighter | null;
  bodyVariant: FighterBodyVariant;
  locked: boolean;
};

export type CharacterSelectState = {
  activePlayer: 0 | 1;
  focusedId: string | null;
  /** Pending body variant while choosing presentation after fighter tile. */
  pendingBodyVariant: FighterBodyVariant;
  p1: SeatSelection;
  p2: SeatSelection;
};

export function createCharacterSelectState(
  roster: CreatedFighter[],
  initialP1?: CreatedFighter | null,
  initialP2?: CreatedFighter | null,
  initialP1Variant: FighterBodyVariant = "male",
  initialP2Variant: FighterBodyVariant = "female",
): CharacterSelectState {
  return {
    activePlayer: 0,
    focusedId: roster[0]?.id ?? null,
    pendingBodyVariant: "male",
    p1: {
      fighter: initialP1 ?? roster[0] ?? null,
      bodyVariant: normalizeBodyVariant(initialP1Variant),
      locked: false,
    },
    p2: {
      fighter: initialP2 ?? roster[1] ?? roster[0] ?? null,
      bodyVariant: normalizeBodyVariant(initialP2Variant),
      locked: false,
    },
  };
}

export function setFocusedFighter(state: CharacterSelectState, fighterId: string): CharacterSelectState {
  return { ...state, focusedId: fighterId };
}

export function setPendingBodyVariant(
  state: CharacterSelectState,
  bodyVariant: FighterBodyVariant,
): CharacterSelectState {
  return { ...state, pendingBodyVariant: normalizeBodyVariant(bodyVariant) };
}

/**
 * Choose fighter for active seat, applying preferred body variant.
 * When the other seat already locked the same fighter, prefer the opposite presentation.
 */
export function selectFighterForActivePlayer(
  state: CharacterSelectState,
  fighter: CreatedFighter,
  bodyVariant?: FighterBodyVariant,
): CharacterSelectState {
  const other = state.activePlayer === 0 ? state.p2 : state.p1;
  let variant = normalizeBodyVariant(bodyVariant ?? state.pendingBodyVariant);
  if (other.fighter?.id === fighter.id && other.locked && other.bodyVariant === variant) {
    variant = oppositeBodyVariant(variant);
  }
  const seat: SeatSelection = { fighter, bodyVariant: variant, locked: true };
  if (state.activePlayer === 0) {
    const next: CharacterSelectState = {
      ...state,
      p1: seat,
      focusedId: fighter.id,
      pendingBodyVariant: variant,
      activePlayer: 1,
    };
    return next;
  }
  return {
    ...state,
    p2: seat,
    focusedId: fighter.id,
    pendingBodyVariant: variant,
    activePlayer: 1,
  };
}

export function setActivePlayer(state: CharacterSelectState, player: 0 | 1): CharacterSelectState {
  return { ...state, activePlayer: player };
}

export function isCharacterSelectReady(state: CharacterSelectState, mode: "match" | "derby" = "match"): boolean {
  if (mode === "derby") return !!(state.p1.fighter && state.p1.locked);
  return !!(state.p1.fighter && state.p1.locked && state.p2.fighter && state.p2.locked);
}

export function getFocusedFighter(state: CharacterSelectState, roster: CreatedFighter[]): CreatedFighter | null {
  if (!state.focusedId) return roster[0] ?? null;
  return roster.find((f) => f.id === state.focusedId) ?? roster[0] ?? null;
}

export type TileState = "default" | "focus" | "p1" | "p2" | "both";

export function tileStateForFighter(state: CharacterSelectState, fighterId: string): TileState {
  const p1 = state.p1.fighter?.id === fighterId;
  const p2 = state.p2.fighter?.id === fighterId;
  if (p1 && p2) return "both";
  if (p1) return "p1";
  if (p2) return "p2";
  if (state.focusedId === fighterId) return "focus";
  return "default";
}

/** Payload shape for match setup / PartyLink: fighter_id + body_variant + seat_id. */
export function seatPayload(
  seatId: number,
  selection: SeatSelection,
  teamId?: number | string | null,
): {
  fighter_id: string | null;
  body_variant: FighterBodyVariant;
  seat_id: number;
  team_id?: number | string | null;
} {
  return {
    fighter_id: selection.fighter?.id ?? null,
    body_variant: selection.bodyVariant,
    seat_id: seatId,
    team_id: teamId ?? null,
  };
}
