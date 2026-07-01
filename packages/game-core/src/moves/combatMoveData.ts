import type { MoveFrameData } from "../frameData.js";
import { getMoveData, type MoveId } from "../moves.js";
import { getFrameDataForMoveId } from "./moveDefinitions.js";
import { getCatalogMove, type CombatMoveData } from "./defaultMoveCatalog.js";

export type { CombatMoveData };

/** Unified move data lookup: catalog → fighter definition → legacy frame data. */
export function getCombatMoveData(moveId: string): CombatMoveData | null {
  if (!moveId || moveId === "none") return null;

  const catalog = getCatalogMove(moveId);
  if (catalog) return catalog;

  const fighterData = getFrameDataForMoveId(moveId);
  if (fighterData) {
    return catalogFromFrameData(moveId, fighterData);
  }

  const legacy = getMoveData(moveId as MoveId);
  if (legacy) return catalogFromFrameData(moveId, legacy);

  return null;
}

function catalogFromFrameData(id: string, data: MoveFrameData): CombatMoveData {
  const isSpecial = id.includes("special");
  return {
    ...data,
    id,
    label: id,
    category: isSpecial ? "neutralSpecial" : "jab",
    angleDeg: isSpecial ? 25 : 45,
    shieldDamage: Math.max(1, Math.floor(data.damage * 0.7)),
    shieldStunFrames: Math.max(4, Math.floor(data.hitstop + 2)),
    hitboxWidth: isSpecial ? 56 : 40,
    hitboxHeight: isSpecial ? 40 : 32,
    hitboxOffsetX: isSpecial ? 40 : 32,
    hitboxOffsetY: 44,
  };
}

export function combatMoveToFrameData(data: CombatMoveData): MoveFrameData {
  return {
    move: data.move,
    startup: data.startup,
    active: data.active,
    recovery: data.recovery,
    damage: data.damage,
    baseKnockback: data.baseKnockback,
    knockbackGrowth: data.knockbackGrowth,
    hitstop: data.hitstop,
    cancelWindows: data.cancelWindows,
    multiHit: data.multiHit,
  };
}
