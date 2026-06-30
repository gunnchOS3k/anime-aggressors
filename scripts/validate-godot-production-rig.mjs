import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");

const REQUIRED_PARTS = [
  "hips", "spine", "chest", "neck", "head", "hair_or_helmet",
  "left_upper_arm", "left_forearm", "left_hand",
  "right_upper_arm", "right_forearm", "right_hand",
  "left_upper_leg", "left_lower_leg", "left_foot",
  "right_upper_leg", "right_lower_leg", "right_foot",
  "back_accessory", "element_accessory", "aura_socket",
  "left_hand_socket", "right_hand_socket", "left_foot_socket",
  "right_foot_socket", "weapon_socket", "hit_center_socket",
];

const REQUIRED_FILES = [
  "scripts/fighter/ProductionFighterRig.gd",
  "scripts/fighter/ProductionFighterFactory.gd",
  "scripts/fighter/FighterSilhouetteProfile.gd",
  "scripts/fighter/FighterMaterialLibrary.gd",
  "scenes/fighter/ProductionFighterRig.tscn",
];

const VERTICAL_SLICE = ["ember-vale", "juno-spark"];
const errors = [];

for (const rel of REQUIRED_FILES) {
  if (!fs.existsSync(path.join(godotRoot, rel))) {
    errors.push(`missing ${rel}`);
  }
}

const factorySrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/ProductionFighterFactory.gd"), "utf8");
for (const part of REQUIRED_PARTS) {
  if (!factorySrc.includes(`"${part}"`)) {
    errors.push(`ProductionFighterFactory missing part ${part}`);
  }
}

const profileSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterSilhouetteProfile.gd"), "utf8");
for (const fighter of VERTICAL_SLICE) {
  if (!profileSrc.includes(`"${fighter}"`)) {
    errors.push(`FighterSilhouetteProfile missing ${fighter}`);
  }
}

const rigSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/ProductionFighterRig.gd"), "utf8");
if (!rigSrc.includes("MeshInstance3D") && !factorySrc.includes("MeshInstance3D")) {
  errors.push("production rig missing MeshInstance3D volumetric parts");
}
if (rigSrc.includes("Line2D") || factorySrc.includes("Line2D")) {
  errors.push("production rig still uses Line2D stick primitives");
}

const fighterScene = fs.readFileSync(path.join(godotRoot, "scenes/Fighter.tscn"), "utf8");
if (!fighterScene.includes("ProductionFighterRig.tscn")) {
  errors.push("Fighter.tscn does not instance ProductionFighterRig");
}

if (errors.length > 0) {
  console.error("Godot production rig validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot production rig OK");
console.log(`  vertical slice fighters: ${VERTICAL_SLICE.join(", ")}`);
