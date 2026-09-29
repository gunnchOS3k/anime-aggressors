import type { CanonicalFighterId } from "./bodyVariant.js";

/** Power-archetype synthesis directions (principles only — no franchise mashup). */
export type PowerArchetypeSynthesis = {
  fighter_id: CanonicalFighterId;
  codename: string;
  lane: string;
  synthesis: string;
  maleNotes: string;
  femaleNotes: string;
  originalityBoundary: string;
};

export const POWER_ARCHETYPE_SYNTHESIS: Record<CanonicalFighterId, PowerArchetypeSynthesis> = {
  "ember-vale": {
    fighter_id: "ember-vale",
    codename: "living kiln",
    lane: "Flame combat synthesis",
    synthesis:
      "Ignition martial artist with charred structural panels, furnace-heart core, heat seams, ignition gauntlets, forward wedge silhouette, flame crown integrated into body.",
    maleNotes: "Stronger wedge shoulders / tapered waist; broader gauntlet silhouette.",
    femaleNotes: "Equally athletic; narrower shoulder line / stronger leg silhouette; same ignition gauntlets and furnace core. No impractical armor reduction.",
    originalityBoundary: "Principles synthesis only — no copied costume, silhouette, logo, or signature attack from any franchise.",
  },
  "rook-ironside": {
    fighter_id: "rook-ironside",
    codename: "living bastion",
    lane: "Impact / earth / armor synthesis",
    synthesis:
      "Layered geologic + forged plates, massive forearms, low center of gravity, impact seams, load-bearing shoulders, shock-ring joints.",
    maleNotes: "Heavyweight silhouette retained.",
    femaleNotes: "Heavyweight silhouette retained — not a lightweight version.",
    originalityBoundary: "Principles synthesis only — no franchise mashup armor or logos.",
  },
  "juno-spark": {
    fighter_id: "juno-spark",
    codename: "arc courier",
    lane: "Electricity / speed / magnetism synthesis",
    synthesis:
      "Dark conductive substrate, visible current channels, diagonal kinetic panels, magnetic rail fins / arc crown, high-speed leg silhouette, compact charged core.",
    maleNotes: "Identical speed/readability envelope.",
    femaleNotes: "Identical speed/readability envelope.",
    originalityBoundary: "Principles synthesis only — no franchise costume mashup.",
  },
  "kaia-windrow": {
    fighter_id: "kaia-windrow",
    codename: "skyfoil",
    lane: "Air / pressure / flight synthesis",
    synthesis:
      "Airfoil sleeves, split ribbon/scarf control surfaces, crescent armor edges, buoyant torso, long readable limbs, pressure-ring anchors.",
    maleNotes: "Same airfoil and ribbon grammar.",
    femaleNotes: "Same airfoil and ribbon grammar — not a separate costume.",
    originalityBoundary: "Principles synthesis only — no franchise mashup.",
  },
  "nix-calder": {
    fighter_id: "nix-calder",
    codename: "cryolattice",
    lane: "Ice / construct / stage-control synthesis",
    synthesis:
      "Dark cold core, faceted ice armor, geometric forearms/shins, crystal mask/crown, lattice seams that grow with aura.",
    maleNotes: "Precision zoner; not sexualized.",
    femaleNotes: "Precision zoner; not sexualized.",
    originalityBoundary: "Principles synthesis only — no franchise mashup.",
  },
  "orion-vell": {
    fighter_id: "orion-vell",
    codename: "orbital marshal",
    lane: "Gravity / vector / cosmic synthesis",
    synthesis:
      "Deep-space body panels, constellation node network, orbit halo/rings, floating gravity stones/nodes, long gesture arms, compressed/released silhouette language.",
    maleNotes: "Same authoritative personality and hand-led motion.",
    femaleNotes: "Same authoritative personality and hand-led motion.",
    originalityBoundary: "Principles synthesis only — no franchise mashup.",
  },
  "vesper-nyx": {
    fighter_id: "vesper-nyx",
    codename: "phase weaver",
    lane: "Phase / void / shadow / spatial synthesis",
    synthesis:
      "Asymmetric cowl, split tails, broken silhouette edges, controlled transparent/absent regions, void seams, ghost-offset secondary geometry.",
    maleNotes: "Same trickster personality and deceptive animation set.",
    femaleNotes: "Same trickster personality and deceptive animation set.",
    originalityBoundary: "Principles synthesis only — no franchise mashup.",
  },
  yin: {
    fighter_id: "yin",
    codename: "infinite quiet",
    lane: "Reduction / null / control synthesis (TUNING_CANDIDATE)",
    synthesis:
      "Inward-collapsing silhouette, suppressed secondary motion, charcoal void body with a single retained seed-light pulse, quiet mask vocabulary reserved for puppet control of others.",
    maleNotes: "Same reduction grammar and reach envelope.",
    femaleNotes: "Same reduction grammar and reach envelope — presentation only.",
    originalityBoundary: "Original cosmic identity — not a recolor of spectrum fighters.",
  },
  yang: {
    fighter_id: "yang",
    codename: "absolute radiance",
    lane: "Definition / construct / control synthesis (TUNING_CANDIDATE)",
    synthesis:
      "Outward-declared silhouette, exact constructive symmetry language, radiant pale body with a single retained dark imperfection, overwrite flares and construct panels.",
    maleNotes: "Same definition grammar and reach envelope.",
    femaleNotes: "Same definition grammar and reach envelope — presentation only.",
    originalityBoundary: "Original cosmic identity — not a recolor of spectrum fighters.",
  },
};
