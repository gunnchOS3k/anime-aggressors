import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  FIGHTERS,
  REQUIRED_MOVE_FIELDS,
  REQUIRED_MOVE_INPUTS,
  formatMissing,
  getFighterMoves,
  loadMoveCatalog,
} from "./godot-product-validation-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");
const errors = [];

const REQUIRED_FILES = [
  "scripts/fighter/ProductionFighterRig.gd",
  "scripts/fighter/ProductionFighterFactory.gd",
  "scripts/fighter/FighterMoveChoreography.gd",
  "scripts/combat/MoveChoreography.gd",
  "scripts/combat/MoveCatalog.gd",
  "scripts/combat/MoveFrameData.gd",
  "scenes/fighter/ProductionFighterRig.tscn",
];

for (const rel of REQUIRED_FILES) {
  if (!fs.existsSync(path.join(godotRoot, rel))) {
    errors.push(`missing ${rel}`);
  }
}

const catalog = loadMoveCatalog();
if (!catalog) {
  errors.push("missing game/godot/data/moves/move_catalog.json");
} else {
  for (const fighterId of FIGHTERS) {
    const moves = getFighterMoves(catalog, fighterId);
    for (const input of REQUIRED_MOVE_INPUTS) {
      const move = moves[input];
      if (!move) {
        errors.push(formatMissing(fighterId, input, "move_definition", "game/godot/data/moves/move_catalog.json"));
        continue;
      }
      if (!move.hit_socket) {
        errors.push(formatMissing(fighterId, move.move_id ?? input, "hit_socket", "game/godot/data/moves/move_catalog.json"));
      }
      if (!move.vfx_socket) {
        errors.push(formatMissing(fighterId, move.move_id ?? input, "vfx_socket", "game/godot/data/moves/move_catalog.json"));
      }
      for (const field of ["hurtbox_profile", "startup_frames", "active_frames", "recovery_frames"]) {
        if (move[field] === undefined || move[field] === null) {
          errors.push(formatMissing(fighterId, move.move_id ?? input, field, "game/godot/data/moves/move_catalog.json"));
        }
      }
    }
  }
}

const factorySrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/ProductionFighterFactory.gd"), "utf8");
for (const fighter of FIGHTERS) {
  if (!fs.existsSync(path.join(repoRoot, "docs/fighters", fighter, "FIGHTER_SPEC.md"))) {
    errors.push(`docs/fighters/${fighter}/FIGHTER_SPEC.md missing`);
  }
}

if (!factorySrc.includes("MeshInstance3D")) {
  errors.push("ProductionFighterFactory missing MeshInstance3D volumetric parts");
}

const fighterScene = fs.readFileSync(path.join(godotRoot, "scenes/Fighter.tscn"), "utf8");
if (!fighterScene.includes("ProductionFighterRig.tscn")) {
  errors.push("Fighter.tscn does not instance ProductionFighterRig");
}

if (errors.length > 0) {
  console.error("Godot fighter quality validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot fighter quality OK");
console.log(`  fighters: ${FIGHTERS.length}`);
