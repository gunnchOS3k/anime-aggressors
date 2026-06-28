import type { DefaultFighterId } from "../defaultFighters.js";
import { DEFAULT_FIGHTERS } from "../defaultFighters.js";
import {
  BEAM_SUPER_FIGHTERS,
  FIGHTER_MOVE_NAMES,
  FIGHTER_SKILL_PROFILE,
  SUPER_ENERGY_KIND,
} from "./fighterMoveNames.js";
import type { MoveFrameData } from "../frameData.js";
import type { MoveCategory, MoveDefinition, MoveSlot, SkillCeiling, SkillFloor } from "./universalMoveSchema.js";
import { ALL_MOVE_SLOTS } from "./universalMoveSchema.js";

const SLOT_CATEGORY: Record<MoveSlot, MoveCategory> = {
  neutralAttack: "jab",
  sideAttack: "tilt",
  upAttack: "tilt",
  downAttack: "tilt",
  neutralAir: "aerial",
  forwardAir: "aerial",
  backAir: "aerial",
  upAir: "aerial",
  downAir: "aerial",
  neutralSpecial: "special",
  sideSpecial: "special",
  upSpecial: "special",
  downSpecial: "special",
  grab: "throw",
  throwForward: "throw",
  throwBack: "throw",
  throwUp: "throw",
  throwDown: "throw",
  super: "super",
};

function categoryFrames(category: MoveCategory): {
  startup: number;
  active: number;
  recovery: number;
  damage: number;
  kb: number;
  growth: number;
  angle: number;
} {
  switch (category) {
    case "jab":
      return { startup: 3, active: 2, recovery: 8, damage: 3, kb: 4, growth: 1.05, angle: 45 };
    case "tilt":
      return { startup: 5, active: 3, recovery: 12, damage: 7, kb: 8, growth: 1.2, angle: 30 };
    case "aerial":
      return { startup: 4, active: 4, recovery: 14, damage: 6, kb: 7, growth: 1.15, angle: 60 };
    case "special":
      return { startup: 8, active: 6, recovery: 18, damage: 10, kb: 9, growth: 1.25, angle: 25 };
    case "throw":
      return { startup: 6, active: 2, recovery: 20, damage: 8, kb: 10, growth: 1.1, angle: 45 };
    case "super":
      return { startup: 12, active: 20, recovery: 30, damage: 18, kb: 14, growth: 1.4, angle: 20 };
    default:
      return { startup: 5, active: 3, recovery: 10, damage: 5, kb: 6, growth: 1.1, angle: 45 };
  }
}

function sizeDamageMult(size: "small" | "medium" | "large"): number {
  if (size === "small") return 0.92;
  if (size === "large") return 1.12;
  return 1;
}

function buildMove(fighterId: DefaultFighterId, slot: MoveSlot): MoveDefinition {
  const names = FIGHTER_MOVE_NAMES[fighterId];
  const profile = FIGHTER_SKILL_PROFILE[fighterId];
  const fighter = DEFAULT_FIGHTERS.find((f) => f.id === fighterId)!;
  const category = SLOT_CATEGORY[slot];
  const frames = categoryFrames(category);
  const dmgMult = sizeDamageMult(fighter.size);
  const isSuper = slot === "super";
  const energyKind = SUPER_ENERGY_KIND[fighterId];

  return {
    id: `${fighterId}:${slot}`,
    fighterId,
    slot,
    displayName: names[slot],
    category,
    startupFrames: frames.startup,
    activeFrames: frames.active,
    recoveryFrames: frames.recovery,
    damage: Math.round(frames.damage * dmgMult),
    baseKnockback: frames.kb,
    knockbackGrowth: frames.growth,
    launchAngleDeg: frames.angle,
    hitboxShape: isSuper ? (energyKind === "orb" ? "orb" : energyKind === "shockwave" ? "arc" : "beam") : "capsule",
    hitboxWidth: isSuper ? 120 : 48,
    hitboxHeight: isSuper ? 40 : 32,
    comboStarter: slot === "neutralAttack" || slot === "downAttack" || slot === "sideSpecial",
    comboExtender: category === "tilt" || category === "aerial" || slot === "sideSpecial",
    comboFinisher: slot === "upAttack" || slot === "downAir" || isSuper,
    cancelInto: slot === "neutralAttack" ? ["sideAttack", "sideSpecial"] : slot === "downAttack" ? ["upAttack"] : undefined,
    skillFloor: profile.floor,
    skillCeiling: profile.ceiling as SkillCeiling,
    tags: [fighter.elementName.toLowerCase(), category],
    vfxStyle: fighter.visualStyleId,
    animationKey: `${fighter.visualStyleId}-${slot}`,
    clashable: isSuper && BEAM_SUPER_FIGHTERS.includes(fighterId),
    energyKind: isSuper ? energyKind : undefined,
    energyPower: isSuper ? (fighter.size === "large" ? 95 : fighter.size === "small" ? 75 : 85) : undefined,
  };
}

const MOVE_CACHE = new Map<string, MoveDefinition>();

function cacheKey(fighterId: string, slot: MoveSlot): string {
  return `${fighterId}:${slot}`;
}

export function getFighterMove(fighterId: string, slot: MoveSlot): MoveDefinition | undefined {
  const key = cacheKey(fighterId, slot);
  if (MOVE_CACHE.has(key)) return MOVE_CACHE.get(key);
  if (!(fighterId in FIGHTER_MOVE_NAMES)) return undefined;
  const move = buildMove(fighterId as DefaultFighterId, slot);
  MOVE_CACHE.set(key, move);
  return move;
}

export function getFighterMoveset(fighterId: string): MoveDefinition[] {
  if (!(fighterId in FIGHTER_MOVE_NAMES)) return [];
  return ALL_MOVE_SLOTS.map((slot) => getFighterMove(fighterId, slot)!);
}

export function getAllFighterMovesets(): MoveDefinition[] {
  return DEFAULT_FIGHTERS.flatMap((f) => getFighterMoveset(f.id));
}

export function getMoveById(moveId: string): MoveDefinition | undefined {
  const [fighterId, slot] = moveId.split(":") as [string, MoveSlot];
  return getFighterMove(fighterId, slot);
}

export function slotFromLegacyMoveId(legacy: string, input: {
  onGround: boolean;
  up?: boolean;
  down?: boolean;
  left?: boolean;
  right?: boolean;
}): MoveSlot {
  if (legacy === "super") return "super";
  if (legacy === "side_special") return "sideSpecial";
  if (legacy === "special_attack") return "neutralSpecial";
  if (legacy === "aerial_attack") {
    if (input.up) return "upAir";
    if (input.down) return "downAir";
    if (input.left || input.right) return "forwardAir";
    return "neutralAir";
  }
  if (legacy === "forward_attack") return "sideAttack";
  if (legacy === "up_attack") return "upAttack";
  if (legacy === "down_attack") return "downAttack";
  return "neutralAttack";
}

export function fighterSkillFloor(fighterId: string): SkillFloor {
  return FIGHTER_SKILL_PROFILE[fighterId as DefaultFighterId]?.floor ?? "beginner";
}

export function fighterSkillCeiling(fighterId: string): SkillCeiling {
  return FIGHTER_SKILL_PROFILE[fighterId as DefaultFighterId]?.ceiling ?? "medium";
}

export function moveDefinitionToFrameData(m: MoveDefinition): MoveFrameData {
  return {
    move: m.id,
    startup: m.startupFrames,
    active: m.activeFrames,
    recovery: m.recoveryFrames,
    damage: m.damage,
    baseKnockback: m.baseKnockback,
    knockbackGrowth: m.knockbackGrowth,
    hitstop: m.category === "super" ? 10 : 5,
    cancelWindows: m.cancelInto?.length ? [m.startupFrames + m.activeFrames] : [],
  };
}

export function getFrameDataForMoveId(moveId: string): MoveFrameData | null {
  const def = getMoveById(moveId);
  return def ? moveDefinitionToFrameData(def) : null;
}

export function fighterIdFromCharacterId(characterId: string): string {
  return characterId.replace(/^created:/, "");
}

export function resolveMoveSlotFromInput(
  player: { onGround: boolean },
  input: { up?: boolean; down?: boolean; left?: boolean; right?: boolean; attack?: boolean; special?: boolean },
): MoveSlot | null {
  if (input.special && input.down) return "super";
  if (input.special) {
    if (input.up) return "upSpecial";
    if (input.down) return "downSpecial";
    if (input.left || input.right) return "sideSpecial";
    return "neutralSpecial";
  }
  if (input.attack) {
    if (!player.onGround) {
      if (input.up) return "upAir";
      if (input.down) return "downAir";
      if (input.left || input.right) return "forwardAir";
      return "neutralAir";
    }
    if (input.up) return "upAttack";
    if (input.down) return "downAttack";
    if (input.left || input.right) return "sideAttack";
    return "neutralAttack";
  }
  return null;
}
