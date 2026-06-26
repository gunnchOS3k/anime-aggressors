import * as THREE from "three";

export const SOLAR_TEAM_COLOR = 0xffb347;
export const LUNAR_TEAM_COLOR = 0x6b9dff;

export function solarMaterial(): THREE.MeshToonMaterial {
  return new THREE.MeshToonMaterial({ color: SOLAR_TEAM_COLOR });
}

export function lunarMaterial(): THREE.MeshToonMaterial {
  return new THREE.MeshToonMaterial({ color: LUNAR_TEAM_COLOR });
}

export function teamMaterial(teamId: "solar" | "lunar"): THREE.MeshToonMaterial {
  return teamId === "solar" ? solarMaterial() : lunarMaterial();
}
