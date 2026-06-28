export type MoveCategory =
  | "jab"
  | "tilt"
  | "smash"
  | "aerial"
  | "special"
  | "throw"
  | "super"
  | "movement"
  | "defense";

export type MoveSlot =
  | "neutralAttack"
  | "sideAttack"
  | "upAttack"
  | "downAttack"
  | "neutralAir"
  | "forwardAir"
  | "backAir"
  | "upAir"
  | "downAir"
  | "neutralSpecial"
  | "sideSpecial"
  | "upSpecial"
  | "downSpecial"
  | "grab"
  | "throwForward"
  | "throwBack"
  | "throwUp"
  | "throwDown"
  | "super";

export type SkillFloor = "beginner" | "intermediate" | "advanced";
export type SkillCeiling = "low" | "medium" | "high";

export type HitboxShape = "circle" | "capsule" | "arc" | "beam" | "orb";

export type MoveDefinition = {
  id: string;
  fighterId: string;
  slot: MoveSlot;
  displayName: string;
  category: MoveCategory;
  startupFrames: number;
  activeFrames: number;
  recoveryFrames: number;
  damage: number;
  baseKnockback: number;
  knockbackGrowth: number;
  launchAngleDeg: number;
  hitboxShape: HitboxShape;
  hitboxWidth: number;
  hitboxHeight: number;
  cancelInto?: MoveSlot[];
  comboStarter?: boolean;
  comboExtender?: boolean;
  comboFinisher?: boolean;
  skillFloor: SkillFloor;
  skillCeiling: SkillCeiling;
  tags: string[];
  vfxStyle: string;
  animationKey: string;
  clashable?: boolean;
  energyKind?: "beam" | "orb" | "wave" | "shockwave";
  energyPower?: number;
};

export type ComboRoute = {
  id: string;
  fighterId: string;
  name: string;
  difficulty: SkillFloor;
  route: MoveSlot[];
  description: string;
  teachingHint: string;
};

export const ALL_MOVE_SLOTS: MoveSlot[] = [
  "neutralAttack",
  "sideAttack",
  "upAttack",
  "downAttack",
  "neutralAir",
  "forwardAir",
  "backAir",
  "upAir",
  "downAir",
  "neutralSpecial",
  "sideSpecial",
  "upSpecial",
  "downSpecial",
  "grab",
  "throwForward",
  "throwBack",
  "throwUp",
  "throwDown",
  "super",
];

export const MOVE_SLOT_INPUT_HINT: Partial<Record<MoveSlot, string>> = {
  neutralAttack: "Attack",
  sideAttack: "Side + Attack",
  upAttack: "Up + Attack",
  downAttack: "Down + Attack",
  neutralAir: "Air + Attack",
  forwardAir: "Air + Side + Attack",
  backAir: "Air + Back + Attack",
  upAir: "Air + Up + Attack",
  downAir: "Air + Down + Attack",
  neutralSpecial: "Special",
  sideSpecial: "Side + Special",
  upSpecial: "Up + Special",
  downSpecial: "Down + Special",
  super: "Down + Special",
  grab: "Grab",
};
