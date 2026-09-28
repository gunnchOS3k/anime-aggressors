import type { DuplicateFighterIdentity } from "./types.js";

const PALETTES = [
  { outline: "#FFE08A", hud: "#F5C542", badge: "A" },
  { outline: "#8AD4FF", hud: "#3BA7F5", badge: "B" },
  { outline: "#FF9AD5", hud: "#F54B9A", badge: "C" },
  { outline: "#A8FF9A", hud: "#3FCF4A", badge: "D" },
  { outline: "#D4A8FF", hud: "#9B5CF5", badge: "E" },
  { outline: "#FFC08A", hud: "#F57A2A", badge: "F" },
  { outline: "#8AFFF0", hud: "#2AD4C0", badge: "G" },
  { outline: "#FF8A8A", hud: "#E63B3B", badge: "H" },
];

/**
 * Duplicate fighter selections are allowed in Party Mode.
 * Clarity comes from palette / outline / badge / HUD / seat label — not unique roster locks.
 */
export function assignDuplicateIdentity(
  fighterId: string,
  seatIndex: number,
  existing: Array<{ fighterId: string | null; seatIndex: number }>,
): DuplicateFighterIdentity {
  const same = existing.filter((e) => e.fighterId === fighterId && e.seatIndex !== seatIndex);
  const paletteIndex = same.length % PALETTES.length;
  const pal = PALETTES[paletteIndex]!;
  const dupOrdinal = same.length + 1;
  return {
    paletteIndex,
    outlineColor: pal.outline,
    badgeLabel: `P${seatIndex + 1}`,
    hudColor: pal.hud,
    nameSuffix: same.length > 0 ? ` #${dupOrdinal}` : "",
  };
}

export function identityPass(identities: DuplicateFighterIdentity[]): boolean {
  if (identities.length < 2) return true;
  const keys = new Set(
    identities.map((i) => `${i.paletteIndex}|${i.outlineColor}|${i.badgeLabel}|${i.hudColor}`),
  );
  return keys.size === identities.length;
}
