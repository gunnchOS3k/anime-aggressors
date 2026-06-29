import path from "node:path";
import { fileURLToPath } from "node:url";
import { validateGodotExportDir } from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const target = process.env.GODOT_EXPORT_DIR ?? path.join(repoRoot, "apps/web/dist/godot");

const result = validateGodotExportDir(target, { label: target });

if (!result.ok) {
  console.error("Godot Web export validation failed:");
  for (const err of result.errors) {
    console.error(`  - ${err}`);
  }
  console.error("\nExport a real Godot Web build:");
  console.error("  npm run godot:export:web");
  console.error("\nRequires Godot 4.3+ CLI. Set GODOT_BIN=/path/to/godot if needed.");
  process.exit(1);
}

console.log("Godot Web export OK:", target);
console.log("  wasm:", result.files.wasm.join(", "));
console.log("  pck:", result.files.pck.join(", "));
console.log("  js:", result.files.js.join(", "));
