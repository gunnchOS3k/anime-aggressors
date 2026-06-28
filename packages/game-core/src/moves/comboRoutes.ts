import type { DefaultFighterId } from "../defaultFighters.js";
import { DEFAULT_FIGHTERS } from "../defaultFighters.js";
import type { ComboRoute } from "./universalMoveSchema.js";

const ROUTES: ComboRoute[] = [
  // Ember Vale
  { id: "ember-b1", fighterId: "ember-vale", name: "Flame Chain", difficulty: "beginner", route: ["neutralAttack", "sideAttack", "upAttack"], description: "Basic rushdown confirm.", teachingHint: "Press Attack three times with Side between hits." },
  { id: "ember-b2", fighterId: "ember-vale", name: "Ash Pop", difficulty: "beginner", route: ["downAttack", "upAttack"], description: "Pop-up into rising hit.", teachingHint: "Down + Attack, then Up + Attack." },
  { id: "ember-i1", fighterId: "ember-vale", name: "Dash Pressure", difficulty: "intermediate", route: ["sideSpecial", "neutralAttack", "forwardAir"], description: "Approach and aerial finish.", teachingHint: "Side + Special to close, then air follow-up." },
  { id: "ember-i2", fighterId: "ember-vale", name: "Heat Confirm", difficulty: "intermediate", route: ["neutralSpecial", "sideAttack"], description: "Shot into cross.", teachingHint: "Special, then Side + Attack." },
  { id: "ember-a1", fighterId: "ember-vale", name: "Solar Chase", difficulty: "advanced", route: ["neutralSpecial", "upSpecial", "downAir"], description: "Shot pop into aerial chase.", teachingHint: "Special, Up + Special, then Down + Air Attack." },
  // Rook Ironside
  { id: "rook-b1", fighterId: "rook-ironside", name: "Iron Chain", difficulty: "beginner", route: ["neutralAttack", "sideAttack"], description: "Simple two-hit confirm.", teachingHint: "Attack, then Side + Attack." },
  { id: "rook-b2", fighterId: "rook-ironside", name: "Quake Rise", difficulty: "beginner", route: ["downAttack", "upAttack"], description: "Sweep into uppercut.", teachingHint: "Down + Attack, Up + Attack." },
  { id: "rook-i1", fighterId: "rook-ironside", name: "Anchor Counter", difficulty: "intermediate", route: ["downSpecial", "forwardAir"], description: "Stance punish into fist.", teachingHint: "Down + Special, then Forward Air." },
  { id: "rook-i2", fighterId: "rook-ironside", name: "Iron Lift", difficulty: "intermediate", route: ["upSpecial", "upAir"], description: "Lift into rising plate.", teachingHint: "Up + Special, then Up Air." },
  { id: "rook-a1", fighterId: "rook-ironside", name: "Faultline Finish", difficulty: "advanced", route: ["sideSpecial", "super"], description: "Wall rush into super.", teachingHint: "Side + Special, then Down + Special." },
  // Juno Spark
  { id: "juno-b1", fighterId: "juno-spark", name: "Static Chain", difficulty: "beginner", route: ["neutralAttack", "sideAttack"], description: "Quick two-hit confirm.", teachingHint: "Attack, Side + Attack." },
  { id: "juno-b2", fighterId: "juno-spark", name: "Flash Tap", difficulty: "beginner", route: ["neutralAttack", "forwardAir"], description: "Tap into needle.", teachingHint: "Attack, then Forward Air." },
  { id: "juno-i2", fighterId: "juno-spark", name: "Blink Confirm", difficulty: "intermediate", route: ["sideSpecial", "neutralAttack"], description: "Blink into tap.", teachingHint: "Side + Special, Attack." },
  { id: "juno-i3", fighterId: "juno-spark", name: "Volt Pop", difficulty: "intermediate", route: ["downAttack", "upAttack"], description: "Low into circuit pop.", teachingHint: "Down + Attack, Up + Attack." },
  { id: "juno-a1", fighterId: "juno-spark", name: "Lightning Ladder", difficulty: "advanced", route: ["sideSpecial", "neutralAttack", "upSpecial", "upAir"], description: "Full aerial voltage route.", teachingHint: "Chain specials and Up Air." },
  { id: "juno-a2", fighterId: "juno-spark", name: "Bloom Circuit", difficulty: "advanced", route: ["downSpecial", "forwardAir", "super"], description: "Charge cancel into super.", teachingHint: "Down + Special cancel, Forward Air, Super." },
  // Kaia Windrow
  { id: "kaia-b1", fighterId: "kaia-windrow", name: "Breeze Chain", difficulty: "beginner", route: ["neutralAttack", "sideAttack"], description: "Spacing two-hit.", teachingHint: "Attack, Side + Attack." },
  { id: "kaia-b2", fighterId: "kaia-windrow", name: "Current Sweep", difficulty: "beginner", route: ["downAttack", "sideAttack"], description: "Low into slash.", teachingHint: "Down + Attack, Side + Attack." },
  { id: "kaia-i1", fighterId: "kaia-windrow", name: "Ring Spear", difficulty: "intermediate", route: ["neutralSpecial", "forwardAir"], description: "Ring into spear.", teachingHint: "Special, Forward Air." },
  { id: "kaia-i2", fighterId: "kaia-windrow", name: "Spiral Lift", difficulty: "intermediate", route: ["downAttack", "upAttack", "upAir"], description: "Pop and spiral.", teachingHint: "Down Attack, Up Attack, Up Air." },
  { id: "kaia-a1", fighterId: "kaia-windrow", name: "Tempest Drift", difficulty: "advanced", route: ["sideSpecial", "backAir", "super"], description: "Glide drift into super.", teachingHint: "Side + Special drift, Back Air, Super." },
  // Nix Calder
  { id: "nix-b1", fighterId: "nix-calder", name: "Frost Chain", difficulty: "beginner", route: ["neutralAttack", "sideAttack"], description: "Slow control confirm.", teachingHint: "Attack, Side + Attack." },
  { id: "nix-b2", fighterId: "nix-calder", name: "Cold Rise", difficulty: "beginner", route: ["downAttack", "upAttack"], description: "Snap into shelf.", teachingHint: "Down + Attack, Up + Attack." },
  { id: "nix-i1", fighterId: "nix-calder", name: "Chill Hammer", difficulty: "intermediate", route: ["downSpecial", "forwardAir"], description: "Field slow into hammer.", teachingHint: "Down + Special, Forward Air." },
  { id: "nix-i2", fighterId: "nix-calder", name: "Glacier Chain", difficulty: "intermediate", route: ["neutralSpecial", "sideAttack"], description: "Shard into hook.", teachingHint: "Special, Side + Attack." },
  { id: "nix-a1", fighterId: "nix-calder", name: "Absolute Trap", difficulty: "advanced", route: ["neutralSpecial", "sideSpecial", "super"], description: "Shard trap into slide super.", teachingHint: "Special, Side + Special, Super." },
  // Orion Vell
  { id: "orion-b1", fighterId: "orion-vell", name: "Orbit Chain", difficulty: "beginner", route: ["neutralAttack", "sideAttack"], description: "Pull rhythm starter.", teachingHint: "Attack, Side + Attack." },
  { id: "orion-b2", fighterId: "orion-vell", name: "Sweep Rise", difficulty: "beginner", route: ["downAttack", "upAttack"], description: "Sweep into rising orbit.", teachingHint: "Down + Attack, Up + Attack." },
  { id: "orion-i1", fighterId: "orion-vell", name: "Well Lift", difficulty: "intermediate", route: ["neutralSpecial", "forwardAir"], description: "Well into palm.", teachingHint: "Special, Forward Air." },
  { id: "orion-i2", fighterId: "orion-vell", name: "Star Route", difficulty: "intermediate", route: ["downAttack", "upAttack", "upAir"], description: "Sweep lift star.", teachingHint: "Down Attack, Up Attack, Up Air." },
  { id: "orion-a1", fighterId: "orion-vell", name: "Horizon Collapse", difficulty: "advanced", route: ["downSpecial", "neutralSpecial", "super"], description: "Pulse well super.", teachingHint: "Down + Special, Special, Super." },
  // Vesper Nyx
  { id: "vesper-b1", fighterId: "vesper-nyx", name: "Void Chain", difficulty: "beginner", route: ["neutralAttack", "sideAttack"], description: "Trickster opener.", teachingHint: "Attack, Side + Attack." },
  { id: "vesper-b2", fighterId: "vesper-nyx", name: "Rift Tap", difficulty: "beginner", route: ["neutralAttack", "forwardAir"], description: "Tap into needle.", teachingHint: "Attack, Forward Air." },
  { id: "vesper-i2", fighterId: "vesper-nyx", name: "Seed Cross", difficulty: "intermediate", route: ["neutralSpecial", "sideSpecial", "backAir"], description: "Seed phase cross-up.", teachingHint: "Special, Side + Special, Back Air." },
  { id: "vesper-i3", fighterId: "vesper-nyx", name: "Shadow Pop", difficulty: "intermediate", route: ["downAttack", "upAttack"], description: "Slip into phase upper.", teachingHint: "Down + Attack, Up + Attack." },
  { id: "vesper-a1", fighterId: "vesper-nyx", name: "Midnight Divide", difficulty: "advanced", route: ["downSpecial", "forwardAir", "super"], description: "Trap needle super.", teachingHint: "Down + Special, Forward Air, Super." },
];

export const COMBO_ROUTES: ComboRoute[] = ROUTES;

export function getComboRoutesForFighter(fighterId: string): ComboRoute[] {
  return ROUTES.filter((r) => r.fighterId === fighterId);
}

export function getComboRoutesByDifficulty(
  fighterId: string,
  difficulty: ComboRoute["difficulty"],
): ComboRoute[] {
  return ROUTES.filter((r) => r.fighterId === fighterId && r.difficulty === difficulty);
}

export function getAllComboRoutes(): ComboRoute[] {
  return ROUTES;
}

export function validateComboRouteCoverage(): { ok: boolean; missing: string[] } {
  const missing: string[] = [];
  for (const f of DEFAULT_FIGHTERS) {
    const id = f.id as DefaultFighterId;
    const beginner = getComboRoutesByDifficulty(id, "beginner").length;
    const intermediate = getComboRoutesByDifficulty(id, "intermediate").length;
    const advanced = getComboRoutesByDifficulty(id, "advanced").length;
    if (beginner < 2) missing.push(`${id}: beginner (${beginner})`);
    if (intermediate < 2) missing.push(`${id}: intermediate (${intermediate})`);
    if (advanced < 1) missing.push(`${id}: advanced (${advanced})`);
  }
  return { ok: missing.length === 0, missing };
}
