/**
 * Dual-form body presentation (V4 / V1.3).
 *
 * Canonical gameplay identity remains fighter_id (9 playable: 7 spectrum + yin/yang).
 * body_variant is presentation-only: male | female meshes/portraits bind to the
 * same animation set, move data, frames, knockback, aura, weight, and collision.
 */

export type FighterBodyVariant = "male" | "female";

export const FIGHTER_BODY_VARIANTS: readonly FighterBodyVariant[] = ["male", "female"] as const;

export const CANONICAL_FIGHTER_IDS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
  "yin",
  "yang",
] as const;

export const SPECTRUM_CANONICAL_FIGHTER_IDS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
] as const;

export type CanonicalFighterId = (typeof CANONICAL_FIGHTER_IDS)[number];

/** 9 fighters × 2 presentations = 18 authored body presentations. */
export const BODY_PRESENTATION_COUNT = CANONICAL_FIGHTER_IDS.length * FIGHTER_BODY_VARIANTS.length;

/** Legacy spectrum-only count (7 × 2). */
export const SPECTRUM_BODY_PRESENTATION_COUNT =
  SPECTRUM_CANONICAL_FIGHTER_IDS.length * FIGHTER_BODY_VARIANTS.length;

export type FighterPresentationSelection = {
  fighter_id: string;
  body_variant: FighterBodyVariant;
  seat_id: number;
  team_id?: number | string | null;
};

export function isFighterBodyVariant(value: unknown): value is FighterBodyVariant {
  return value === "male" || value === "female";
}

export function normalizeBodyVariant(value: unknown, fallback: FighterBodyVariant = "male"): FighterBodyVariant {
  return isFighterBodyVariant(value) ? value : fallback;
}

export function oppositeBodyVariant(variant: FighterBodyVariant): FighterBodyVariant {
  return variant === "male" ? "female" : "male";
}

/**
 * Prefer unused body presentation for the same fighter_id.
 * When both variants are already taken, cycle male/female by seat ordinal.
 * Combat / ranking / network authority must ignore the result.
 */
export function allocateBodyVariantForDuplicate(
  fighterId: string,
  seatId: number,
  existing: Array<{ fighter_id: string | null; body_variant?: FighterBodyVariant | null; seat_id: number }>,
  preferred?: FighterBodyVariant | null,
): FighterBodyVariant {
  const same = existing.filter((e) => e.fighter_id === fighterId && e.seat_id !== seatId);
  if (preferred && isFighterBodyVariant(preferred)) {
    const preferredTaken = same.some((e) => e.body_variant === preferred);
    if (!preferredTaken) return preferred;
    return oppositeBodyVariant(preferred);
  }
  const used = new Set(same.map((e) => e.body_variant).filter(isFighterBodyVariant));
  if (!used.has("male")) return "male";
  if (!used.has("female")) return "female";
  // >2 same fighter: cycle presentations; seat/team accents handle identity.
  return same.length % 2 === 0 ? "male" : "female";
}

/** Presentation asset key — never a gameplay ID. */
export function presentationAssetKey(fighterId: string, variant: FighterBodyVariant): string {
  return `${fighterId}:${variant}`;
}

export function listAuthoredPresentations(): FighterPresentationSelection[] {
  const out: FighterPresentationSelection[] = [];
  for (const fighter_id of CANONICAL_FIGHTER_IDS) {
    for (const body_variant of FIGHTER_BODY_VARIANTS) {
      out.push({ fighter_id, body_variant, seat_id: -1 });
    }
  }
  return out;
}
