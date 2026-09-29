import type { DuplicateFighterIdentity, FighterBodyVariant } from "./types.js";

/**
 * Seat/team accent markers for duplicate fighters (trim / UI / aura-ring).
 * Do NOT full-palette-swap the entire character mesh.
 */
const SEAT_ACCENTS = [
  { outline: "#FFE08A", hud: "#F5C542", ring: "#FFE08A" },
  { outline: "#8AD4FF", hud: "#3BA7F5", ring: "#8AD4FF" },
  { outline: "#FF9AD5", hud: "#F54B9A", ring: "#FF9AD5" },
  { outline: "#A8FF9A", hud: "#3FCF4A", ring: "#A8FF9A" },
  { outline: "#D4A8FF", hud: "#9B5CF5", ring: "#D4A8FF" },
  { outline: "#FFC08A", hud: "#F57A2A", ring: "#FFC08A" },
  { outline: "#8AFFF0", hud: "#2AD4C0", ring: "#8AFFF0" },
  { outline: "#FF8A8A", hud: "#E63B3B", ring: "#FF8A8A" },
];

export type DuplicateSeatRef = {
  fighterId: string | null;
  seatIndex: number;
  bodyVariant?: FighterBodyVariant | null;
};

function opposite(variant: FighterBodyVariant): FighterBodyVariant {
  return variant === "male" ? "female" : "male";
}

/**
 * Prefer different body presentations first for the same fighter_id.
 * When both variants are taken (>2 same fighter), cycle male/female and rely on
 * seat/team accent markers only — never a full character palette swap.
 */
export function allocatePreferredBodyVariant(
  fighterId: string,
  seatIndex: number,
  existing: DuplicateSeatRef[],
  preferred?: FighterBodyVariant | null,
): FighterBodyVariant {
  const same = existing.filter((e) => e.fighterId === fighterId && e.seatIndex !== seatIndex);
  if (preferred === "male" || preferred === "female") {
    const taken = same.some((e) => e.bodyVariant === preferred);
    if (!taken) return preferred;
    return opposite(preferred);
  }
  const usedMale = same.some((e) => e.bodyVariant === "male");
  const usedFemale = same.some((e) => e.bodyVariant === "female");
  if (!usedMale) return "male";
  if (!usedFemale) return "female";
  return same.length % 2 === 0 ? "male" : "female";
}

/**
 * Duplicate fighter selections are allowed in Party Mode (2/4/6/8 safe).
 * Identity clarity:
 * 1) different body_variant when available
 * 2) seat/team accent markers on trim/UI/aura-ring when >2 share a fighter
 */
export function assignDuplicateIdentity(
  fighterId: string,
  seatIndex: number,
  existing: DuplicateSeatRef[],
  preferredBodyVariant?: FighterBodyVariant | null,
): DuplicateFighterIdentity {
  const same = existing.filter((e) => e.fighterId === fighterId && e.seatIndex !== seatIndex);
  const bodyVariant = allocatePreferredBodyVariant(fighterId, seatIndex, existing, preferredBodyVariant);
  const dupOrdinal = same.length + 1;
  // Accent markers always seat-indexed so duplicates stay readable without mesh recolor.
  const accent = SEAT_ACCENTS[seatIndex % SEAT_ACCENTS.length]!;
  const needsAccent = same.length >= 1;
  return {
    bodyVariant,
    paletteIndex: seatIndex % SEAT_ACCENTS.length,
    outlineColor: needsAccent ? accent.outline : accent.outline,
    badgeLabel: `P${seatIndex + 1}`,
    hudColor: accent.hud,
    auraRingColor: accent.ring,
    accentOnly: same.length >= 2,
    nameSuffix: same.length > 0 ? ` #${dupOrdinal}` : "",
  };
}

export function identityPass(identities: DuplicateFighterIdentity[]): boolean {
  if (identities.length < 2) return true;
  const keys = new Set(
    identities.map(
      (i) => `${i.bodyVariant}|${i.paletteIndex}|${i.outlineColor}|${i.badgeLabel}|${i.hudColor}`,
    ),
  );
  return keys.size === identities.length;
}

/** Validate PartyLink seat counts remain 2/4/6/8 safe for duplicate allocation. */
export function partyDuplicateAllocationSafe(playerCount: number): boolean {
  return playerCount === 2 || playerCount === 4 || playerCount === 6 || playerCount === 8;
}
