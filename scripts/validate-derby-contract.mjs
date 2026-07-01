import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");
const errors = [];

const mainSrc = fs.readFileSync(path.join(godotRoot, "scripts/Main.gd"), "utf8");
if (!mainSrc.includes("CHARACTER_SELECT") || !mainSrc.includes("derby_selection_confirmed")) {
  errors.push("Main.gd: Derby must route through character select");
}

const derbySrc = fs.readFileSync(path.join(godotRoot, "scripts/modes/ImpactDummyDerby.gd"), "utf8");
for (const needle of ["fighter_required", "set_selected_fighter", "start_derby", "derby_finished"]) {
  if (!derbySrc.includes(needle)) {
    errors.push(`ImpactDummyDerby.gd: missing ${needle}`);
  }
}

const derbyScene = path.join(godotRoot, "scenes/modes/ImpactDummyDerby.tscn");
if (!fs.existsSync(derbyScene)) {
  errors.push("missing scenes/modes/ImpactDummyDerby.tscn");
}

const kineticBat = path.join(godotRoot, "scripts/modes/KineticBat.gd");
if (!fs.existsSync(kineticBat)) {
  errors.push("missing scripts/modes/KineticBat.gd");
}

const dummy = path.join(godotRoot, "scripts/modes/ImpactDummy.gd");
if (!fs.existsSync(dummy)) {
  errors.push("missing scripts/modes/ImpactDummy.gd");
}

if (errors.length > 0) {
  console.error("Derby contract validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Derby contract OK");
