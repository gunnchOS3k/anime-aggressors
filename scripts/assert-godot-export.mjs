import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { validateGodotExportDir } from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const root = process.env.GODOT_EXPORT_ROOT ?? path.join(repoRoot, "apps/web/dist/godot");
const target = process.env.GODOT_EXPORT_DIR ?? path.join(root, "runtime");

const bootShell = path.join(root, "index.html");
const rescueRuntime = path.join(root, "rescue-runtime.js");
const result = validateGodotExportDir(target, { label: target });

if (!fs.existsSync(bootShell)) {
  result.errors.push(`${root}: missing Godot boot shell index.html`);
}
if (!fs.existsSync(rescueRuntime)) {
  result.errors.push(`${root}: missing rescue-runtime.js fallback`);
}

if (!result.ok || result.errors.length > 0) {
  console.error("Godot Web export validation failed:");
  for (const err of result.errors) {
    console.error(`  - ${err}`);
  }
  console.error("\nExport a real Godot Web build:");
  console.error("  npm run godot:export:web");
  console.error("\nRequires Godot 4.3+ CLI. Set GODOT_BIN=/path/to/godot if needed.");
  process.exit(1);
}

const bootHtml = fs.readFileSync(bootShell, "utf8");
if (!bootHtml.includes("runtime/index.html") || !bootHtml.includes("AARescueRuntime")) {
  console.error("Godot boot shell does not reference runtime/index.html and rescue runtime.");
  process.exit(1);
}

console.log("Godot Web export OK:", target);
console.log("  boot shell:", bootShell);
console.log("  rescue runtime:", rescueRuntime);
console.log("  wasm:", result.files.wasm.join(", "));
console.log("  pck:", result.files.pck.join(", "));
console.log("  js:", result.files.js.join(", "));
