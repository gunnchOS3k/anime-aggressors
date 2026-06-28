import type { FighterColor } from "@anime-aggressors/game-core";
import { ELEMENTS } from "@anime-aggressors/game-core";

const ICON_CLASS: Record<FighterColor, string> = {
  red: "pf-el-flame",
  orange: "pf-el-impact",
  yellow: "pf-el-volt",
  green: "pf-el-gale",
  blue: "pf-el-frost",
  indigo: "pf-el-gravity",
  violet: "pf-el-void",
};

export function renderElementIcon(color: FighterColor): string {
  const name = ELEMENTS[color]?.name ?? color;
  return `<span class="pf-element-icon ${ICON_CLASS[color] ?? ""}" title="${name}">${name.slice(0, 1)}</span>`;
}
