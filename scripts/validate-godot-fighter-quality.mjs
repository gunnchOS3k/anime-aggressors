import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");

const REQUIRED_PARTS = [
  "head",
  "torso",
  "hips",
  "left_upper_arm",
  "left_forearm",
  "left_hand",
  "right_upper_arm",
  "right_forearm",
  "right_hand",
  "left_thigh",
  "left_shin",
  "left_foot",
  "right_thigh",
  "right_shin",
  "right_foot",
  "element_accent",
  "aura_socket",
];

const REQUIRED_FILES = [
  "scripts/fighter/FighterRig3D.gd",
  "scripts/fighter/FighterRigFactory.gd",
  "scripts/fighter/FighterAnimationTreeDriver.gd",
  "scripts/fighter/FighterAnimationStates.gd",
  "scripts/fighter/FighterMoveChoreography.gd",
  "scripts/combat/MoveChoreography.gd",
  "scripts/combat/MoveFrameData.gd",
  "scripts/combat/HitboxSocket.gd",
  "scripts/vfx/VfxSocket.gd",
  "scripts/vfx/ElementalVfxFactory.gd",
  "scenes/fighters/FighterRig3D.tscn",
  "scenes/fighters/FighterAnimationTree.tscn",
];

const FIGHTERS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];

const errors = [];

for (const rel of REQUIRED_FILES) {
  if (!fs.existsSync(path.join(godotRoot, rel))) {
    errors.push(`missing ${rel}`);
  }
}

const factorySrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterRigFactory.gd"), "utf8");
for (const part of REQUIRED_PARTS) {
  if (!factorySrc.includes(`"${part}"`)) {
    errors.push(`FighterRigFactory missing part ${part}`);
  }
}
for (const fighter of FIGHTERS) {
  if (!factorySrc.includes(`"${fighter}"`)) {
    errors.push(`FighterRigFactory missing fighter profile ${fighter}`);
  }
}

const rigSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterRig3D.gd"), "utf8");
if (rigSrc.includes("stick") || rigSrc.includes("line2d")) {
  errors.push("FighterRig3D appears to use stick/line primitives");
}
if (!rigSrc.includes("MeshInstance3D") && !factorySrc.includes("MeshInstance3D")) {
  errors.push("fighter rig pipeline missing MeshInstance3D parts");
}

const statesSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterAnimationStates.gd"), "utf8");
for (const state of ["neutral_attack_active", "aura_charge", "launch_tumble", "victory"]) {
  if (!statesSrc.includes(`"${state}"`)) {
    errors.push(`animation states missing ${state}`);
  }
}

const choreographySrc = fs.readFileSync(path.join(godotRoot, "scripts/combat/MoveChoreography.gd"), "utf8");
if (!choreographySrc.includes("hit_socket")) {
  errors.push("MoveChoreography missing hit_socket definitions");
}

const fighterScene = fs.readFileSync(path.join(godotRoot, "scenes/Fighter.tscn"), "utf8");
if (!fighterScene.includes("FighterRig3D.tscn")) {
  errors.push("Fighter.tscn does not instance FighterRig3D");
}

if (errors.length > 0) {
  console.error("Godot fighter quality validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot fighter quality OK");
console.log(`  fighters: ${FIGHTERS.length}`);
console.log(`  rig parts: ${REQUIRED_PARTS.length}`);
