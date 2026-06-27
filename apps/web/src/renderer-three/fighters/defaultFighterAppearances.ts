import type { DefaultFighterId, PreviewAnimationId } from "@anime-aggressors/game-core";

export type TrailStyleKind =
  | "flame"
  | "impact"
  | "volt"
  | "gale"
  | "frost"
  | "gravity"
  | "void";

export type BodyShape = "compact" | "athletic" | "broad";

export type DefaultFighterAppearance = {
  fighterId: DefaultFighterId;
  bodyShape: BodyShape;
  primaryColor: string;
  secondaryColor: string;
  accentColor: string;
  auraColor: string;
  trailStyle: TrailStyleKind;
  silhouetteParts: {
    hair?: string;
    jacket?: string;
    scarf?: string;
    cape?: string;
    shoulderArmor?: string;
    gauntlets?: string;
    floatingBits?: string;
    wingSleeves?: string;
    mantle?: string;
    heavyBoots?: string;
    hood?: string;
  };
  previewAnimation: PreviewAnimationId;
};

export const DEFAULT_FIGHTER_APPEARANCES: DefaultFighterAppearance[] = [
  {
    fighterId: "ember-vale",
    bodyShape: "athletic",
    primaryColor: "#1a1a1a",
    secondaryColor: "#e63946",
    accentColor: "#ff6622",
    auraColor: "#ff4422",
    trailStyle: "flame",
    silhouetteParts: { hair: "angular", jacket: "short", gauntlets: "flame" },
    previewAnimation: "flame-gauntlet-ignite",
  },
  {
    fighterId: "rook-ironside",
    bodyShape: "broad",
    primaryColor: "#2a2520",
    secondaryColor: "#f77f00",
    accentColor: "#ff9933",
    auraColor: "#ff7700",
    trailStyle: "impact",
    silhouetteParts: { shoulderArmor: "block", heavyBoots: "heavy", gauntlets: "block" },
    previewAnimation: "impact-stomp",
  },
  {
    fighterId: "juno-spark",
    bodyShape: "compact",
    primaryColor: "#1a1a2e",
    secondaryColor: "#ffd60a",
    accentColor: "#ffee44",
    auraColor: "#ffdd22",
    trailStyle: "volt",
    silhouetteParts: { hair: "tufts", scarf: "lightning" },
    previewAnimation: "volt-afterimage",
  },
  {
    fighterId: "kaia-windrow",
    bodyShape: "athletic",
    primaryColor: "#1a2820",
    secondaryColor: "#2dc653",
    accentColor: "#66ff88",
    auraColor: "#44dd66",
    trailStyle: "gale",
    silhouetteParts: { wingSleeves: "flow", scarf: "sash" },
    previewAnimation: "gale-hover",
  },
  {
    fighterId: "nix-calder",
    bodyShape: "broad",
    primaryColor: "#1a2530",
    secondaryColor: "#4cc9f0",
    accentColor: "#aaeeff",
    auraColor: "#4499ff",
    trailStyle: "frost",
    silhouetteParts: { mantle: "ice", gauntlets: "heavy", hair: "angular" },
    previewAnimation: "frost-mantle",
  },
  {
    fighterId: "orion-vell",
    bodyShape: "athletic",
    primaryColor: "#1a1a28",
    secondaryColor: "#5a189a",
    accentColor: "#9966ff",
    auraColor: "#7744cc",
    trailStyle: "gravity",
    silhouetteParts: { jacket: "long-coat", floatingBits: "stones" },
    previewAnimation: "gravity-orbit",
  },
  {
    fighterId: "vesper-nyx",
    bodyShape: "compact",
    primaryColor: "#1a1020",
    secondaryColor: "#9d4edd",
    accentColor: "#cc66ff",
    auraColor: "#9933cc",
    trailStyle: "void",
    silhouetteParts: { hood: "collar", cape: "asymmetric" },
    previewAnimation: "void-afterimage",
  },
];

export function getDefaultFighterAppearance(fighterId: string): DefaultFighterAppearance | undefined {
  return DEFAULT_FIGHTER_APPEARANCES.find((a) => a.fighterId === fighterId);
}

export function appearanceForVisualStyleId(visualStyleId: string): DefaultFighterAppearance | undefined {
  return DEFAULT_FIGHTER_APPEARANCES.find((a) => a.fighterId.startsWith(visualStyleId) || a.fighterId.includes(visualStyleId));
}
