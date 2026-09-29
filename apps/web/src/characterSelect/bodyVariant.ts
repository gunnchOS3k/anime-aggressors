/** V4 dual-form body presentation helpers (web parity with Godot). */
export type FighterBodyVariant = "male" | "female";

export function normalizeBodyVariant(value: unknown): FighterBodyVariant {
  return value === "female" ? "female" : "male";
}

export function alternateBodyVariant(v: FighterBodyVariant): FighterBodyVariant {
  return v === "male" ? "female" : "male";
}

export type SeatPick = {
  seatId: number;
  fighterId: string;
  teamId?: number;
  bodyVariant?: FighterBodyVariant;
};

export function allocatePartyLinkVariants(picks: SeatPick[]): Array<SeatPick & { seatAccent: boolean }> {
  const assigned: Array<SeatPick & { seatAccent: boolean; bodyVariant: FighterBodyVariant }> = [];
  for (const pick of picks) {
    const same = assigned.filter((e) => e.fighterId === pick.fighterId);
    const males = same.filter((e) => e.bodyVariant === "male").length;
    const females = same.filter((e) => e.bodyVariant === "female").length;
    let bodyVariant: FighterBodyVariant = "male";
    if (males === 0) bodyVariant = "male";
    else if (females === 0) bodyVariant = "female";
    else bodyVariant = (males + females) % 2 === 0 ? "male" : "female";
    const seatAccent = same.some((e) => e.bodyVariant === bodyVariant);
    assigned.push({
      ...pick,
      bodyVariant,
      seatAccent,
    });
  }
  return assigned;
}
