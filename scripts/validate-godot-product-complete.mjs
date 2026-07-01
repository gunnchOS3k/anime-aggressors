import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { FIGHTERS, REQUIRED_SOCKETS } from "./godot-product-validation-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");
const errors = [];

const validators = [
  "validate-fighter-movesets.mjs",
  "validate-fighter-combos.mjs",
  "validate-fighter-animation-contract.mjs",
  "validate-stage-contract.mjs",
  "validate-derby-contract.mjs",
];

for (const script of validators) {
  try {
    execSync(`node scripts/${script}`, { cwd: repoRoot, stdio: "pipe" });
  } catch (e) {
    errors.push(`${script} failed`);
    if (e.stdout) errors.push(String(e.stdout));
    if (e.stderr) errors.push(String(e.stderr));
  }
}

for (const rel of [
  "scripts/combat/MoveCatalog.gd",
  "scripts/combat/ComboCatalog.gd",
  "data/moves/move_catalog.json",
  "data/combos/combo_catalog.json",
]) {
  if (!fs.existsSync(path.join(godotRoot, rel))) {
    errors.push(`missing game/godot/${rel}`);
  }
}

const socketSrc = fs.readFileSync(path.join(godotRoot, "scripts/fighter/FighterSocketMap.gd"), "utf8");
for (const socket of REQUIRED_SOCKETS) {
  if (!socketSrc.includes(`"${socket}"`)) {
    errors.push(`FighterSocketMap.gd: missing canonical socket ${socket}`);
  }
}

for (const fighterId of FIGHTERS) {
  const docDir = path.join(repoRoot, "docs/fighters", fighterId);
  for (const file of ["FIGHTER_SPEC.md", "MOVESET.md", "COMBOS.md", "ANIMATION_LIST.md", "VFX_LIST.md", "AUDIO_LIST.md"]) {
    if (!fs.existsSync(path.join(docDir, file))) {
      errors.push(`docs/fighters/${fighterId}/${file} missing`);
    }
  }
}

const readme = fs.readFileSync(path.join(repoRoot, "README.md"), "utf8");
if (!readme.includes("product-completion mode")) {
  errors.push("README.md missing product-completion mode statement");
}
if (readme.toLowerCase().includes("debug/proxy assets are final")) {
  errors.push("README.md still claims debug/proxy assets are final");
}

if (!fs.existsSync(path.join(repoRoot, "tools/blender/export_all_fighters.py"))) {
  errors.push("missing tools/blender/export_all_fighters.py");
}

	if (errors.length > 0) {
  console.error("Godot product completion validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot product completion OK");
console.log(`  fighters: ${FIGHTERS.length}`);
console.log(`  validators: ${validators.length}`);
