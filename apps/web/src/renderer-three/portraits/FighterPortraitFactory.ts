import { getDefaultFighterAppearance } from "../fighters/defaultFighterAppearances.ts";
import { normalizeDefaultFighterId } from "@anime-aggressors/game-core";

export type FighterPortraitConfig = {
  fighterId: string;
  name: string;
  accentColor: string;
  secondaryColor: string;
  auraColor: string;
  headShape: "angular" | "round" | "heavy" | "compact";
  hairStyle: string;
  shoulderStyle: string;
  elementAccent: string;
  auraRing: boolean;
};

const PORTRAIT_OVERRIDES: Record<string, Partial<FighterPortraitConfig>> = {
  "ember-vale": {
    headShape: "angular",
    hairStyle: "flame-spike",
    shoulderStyle: "flame-gauntlet",
    elementAccent: "ember-glow",
  },
  "rook-ironside": {
    headShape: "heavy",
    hairStyle: "helmet",
    shoulderStyle: "armored-plates",
    elementAccent: "impact-chunks",
  },
  "juno-spark": {
    headShape: "compact",
    hairStyle: "sharp-tuft",
    shoulderStyle: "lightning-scarf",
    elementAccent: "volt-tick",
  },
  "kaia-windrow": {
    headShape: "angular",
    hairStyle: "flow-bangs",
    shoulderStyle: "wind-sash",
    elementAccent: "gale-ribbon",
  },
  "nix-calder": {
    headShape: "heavy",
    hairStyle: "frost-crown",
    shoulderStyle: "ice-mantle",
    elementAccent: "frost-shard",
  },
  "orion-vell": {
    headShape: "angular",
    hairStyle: "swept",
    shoulderStyle: "gravity-coat",
    elementAccent: "orbit-stones",
  },
  "vesper-nyx": {
    headShape: "compact",
    hairStyle: "void-hood",
    shoulderStyle: "phase-cape",
    elementAccent: "void-smear",
  },
};

export function getPortraitConfigForFighter(fighterId: string): FighterPortraitConfig {
  const id = normalizeDefaultFighterId(fighterId);
  const appearance = getDefaultFighterAppearance(id);
  const override = PORTRAIT_OVERRIDES[id] ?? {};
  return {
    fighterId: id,
    name: id,
    accentColor: appearance?.accentColor ?? "#ff6622",
    secondaryColor: appearance?.secondaryColor ?? "#e63946",
    auraColor: appearance?.auraColor ?? "#ff4422",
    headShape: override.headShape ?? "angular",
    hairStyle: override.hairStyle ?? "default",
    shoulderStyle: override.shoulderStyle ?? "default",
    elementAccent: override.elementAccent ?? "aura",
    auraRing: true,
    ...override,
  };
}

export function listDefaultPortraitFighterIds(): string[] {
  return Object.keys(PORTRAIT_OVERRIDES);
}

function headPath(shape: FighterPortraitConfig["headShape"]): string {
  switch (shape) {
    case "heavy":
      return "M20 18 Q32 8 44 18 L44 38 Q32 48 20 38 Z";
    case "compact":
      return "M22 20 Q32 12 42 20 L41 36 Q32 42 23 36 Z";
    case "round":
      return "M22 18 Q32 10 42 18 L42 38 Q32 46 22 38 Z";
    default:
      return "M21 17 Q32 8 43 17 L44 37 Q32 46 20 37 Z";
  }
}

function hairMarkup(cfg: FighterPortraitConfig): string {
  const c = cfg.accentColor;
  switch (cfg.hairStyle) {
    case "flame-spike":
      return `<path d="M18 20 L24 6 L32 16 L38 4 L44 18" fill="none" stroke="${c}" stroke-width="2.5"/>`;
    case "helmet":
      return `<path d="M18 22 Q32 6 46 22 L44 30 Q32 18 20 30 Z" fill="${cfg.secondaryColor}" opacity="0.85"/>`;
    case "sharp-tuft":
      return `<path d="M26 18 L32 8 L38 18" fill="${c}"/>`;
    case "flow-bangs":
      return `<path d="M20 22 Q32 14 44 22 L42 28 Q32 22 22 28 Z" fill="${c}" opacity="0.7"/>`;
    case "frost-crown":
      return `<path d="M20 20 L26 10 L32 18 L38 10 L44 20" fill="none" stroke="#aaeeff" stroke-width="2"/>`;
    case "void-hood":
      return `<path d="M16 24 Q32 6 48 24 L46 40 Q32 28 18 40 Z" fill="#1a1020" stroke="${c}" stroke-width="1.5"/>`;
    case "swept":
      return `<path d="M20 20 Q32 12 44 20 L42 26 Q32 20 22 26 Z" fill="${cfg.secondaryColor}"/>`;
    default:
      return `<ellipse cx="32" cy="16" rx="10" ry="6" fill="${cfg.secondaryColor}" opacity="0.6"/>`;
  }
}

function shoulderMarkup(cfg: FighterPortraitConfig): string {
  const c = cfg.secondaryColor;
  switch (cfg.shoulderStyle) {
    case "flame-gauntlet":
      return `<path d="M8 52 L18 40 L26 50 L32 38 L38 50 L46 40 L56 52" fill="${c}" opacity="0.75"/><rect x="10" y="48" width="8" height="10" rx="2" fill="${cfg.accentColor}"/>`;
    case "armored-plates":
      return `<path d="M6 54 L16 42 L32 46 L48 42 L58 54" fill="${c}"/><rect x="8" y="46" width="14" height="12" rx="3" fill="#2a2520" stroke="${cfg.accentColor}"/>`;
    case "lightning-scarf":
      return `<path d="M10 50 Q32 44 54 50" fill="none" stroke="${cfg.accentColor}" stroke-width="3"/><path d="M8 54 L20 48 L32 54 L44 48 L56 54" fill="${c}" opacity="0.5"/>`;
    case "wind-sash":
      return `<path d="M8 52 L20 44 L32 50 L44 44 L56 52" fill="${c}" opacity="0.6"/><path d="M14 48 Q32 40 50 48" fill="none" stroke="${cfg.accentColor}" stroke-width="2"/>`;
    case "ice-mantle":
      return `<path d="M6 54 L18 42 L32 48 L46 42 L58 54" fill="#1a2530" stroke="#aaeeff" stroke-width="1.5"/>`;
    case "gravity-coat":
      return `<path d="M8 54 L16 42 L32 46 L48 42 L56 54" fill="${c}" opacity="0.55"/><circle cx="14" cy="36" r="3" fill="${cfg.accentColor}"/><circle cx="50" cy="34" r="2.5" fill="${cfg.accentColor}"/>`;
    case "phase-cape":
      return `<path d="M10 54 L18 40 L32 44 L46 40 L54 54" fill="#1a1020" stroke="${cfg.accentColor}" stroke-width="1.2" opacity="0.9"/>`;
    default:
      return `<path d="M10 52 L20 44 L44 44 L54 52" fill="${c}" opacity="0.5"/>`;
  }
}

export function renderFighterPortraitSvg(fighterId: string, size = 72): string {
  const cfg = getPortraitConfigForFighter(fighterId);
  const svg = `<svg class="fighter-portrait-svg" viewBox="0 0 64 80" width="${size}" height="${Math.round(size * 1.25)}" aria-hidden="true" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="aura-${cfg.fighterId}" cx="50%" cy="40%" r="60%">
        <stop offset="0%" stop-color="${cfg.auraColor}" stop-opacity="0.35"/>
        <stop offset="100%" stop-color="${cfg.auraColor}" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <rect width="64" height="80" fill="#0a0a18" rx="6"/>
    <circle cx="32" cy="38" r="28" fill="url(#aura-${cfg.fighterId})"/>
    ${cfg.auraRing ? `<ellipse cx="32" cy="58" rx="22" ry="6" fill="none" stroke="${cfg.auraColor}" stroke-width="1.5" opacity="0.6"/>` : ""}
    ${shoulderMarkup(cfg)}
    <path d="${headPath(cfg.headShape)}" fill="#2a2a3a" stroke="${cfg.accentColor}" stroke-width="1.2"/>
    ${hairMarkup(cfg)}
    <ellipse cx="26" cy="28" rx="2" ry="2.5" fill="#f5f7ff"/>
    <ellipse cx="38" cy="28" rx="2" ry="2.5" fill="#f5f7ff"/>
  </svg>`;
  return svg;
}

export function renderFighterPortraitHtml(fighterId: string, size = 72): string {
  return `<div class="fighter-portrait" data-fighter-id="${normalizeDefaultFighterId(fighterId)}">${renderFighterPortraitSvg(fighterId, size)}</div>`;
}
