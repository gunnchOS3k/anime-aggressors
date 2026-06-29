import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { validateGodotExportDir, resolveGodotBin } from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotProject = path.join(repoRoot, "game/godot/project.godot");
const publicExport = path.join(repoRoot, "apps/web/public/godot");

if (!fs.existsSync(godotProject)) {
  console.error("Missing Godot project at game/godot/project.godot");
  process.exit(1);
}

console.log("Godot project found:", godotProject);

const godotBin = resolveGodotBin();
if (godotBin) {
  console.log("Godot CLI:", godotBin);
} else {
  console.warn("Godot CLI not installed — run npm run godot:export:web after installing Godot 4.3+");
}

const result = validateGodotExportDir(publicExport, { label: publicExport });
if (result.ok) {
  console.log("Godot web artifact present:", publicExport);
  console.log("  wasm:", result.files.wasm.join(", "));
} else {
  console.warn("Godot export missing or placeholder:", result.errors.join("; "));
}

console.log("godot:check complete");
