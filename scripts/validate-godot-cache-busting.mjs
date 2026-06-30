import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  readGodotBuildManifest,
  resolveRuntimeDirFromRoot,
  validateGodotPagesExportRoot,
} from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const root = process.env.GODOT_EXPORT_ROOT ?? path.join(repoRoot, "apps/web/public/godot");

const errors = [];

const pages = validateGodotPagesExportRoot(root, { label: root });
errors.push(...pages.errors);

const manifest = readGodotBuildManifest(root);
if (!manifest) {
  errors.push("missing build-manifest.json");
} else {
  if (!manifest.buildId) errors.push("build-manifest missing buildId");
  if (!manifest.runtimePath) errors.push("build-manifest missing runtimePath");
  if (!manifest.generatedAt) errors.push("build-manifest missing generatedAt");
}

const bootHtml = fs.readFileSync(path.join(root, "index.html"), "utf8");
if (!bootHtml.includes("?v=")) {
  errors.push("boot shell missing ?v= cache-bust query on assets");
}
if (!bootHtml.includes("rescue-runtime.js?v=") && !bootHtml.includes(`rescue-runtime.js?v=${manifest?.buildId ?? ""}`)) {
  if (!bootHtml.includes("rescue-runtime.js?v=")) {
    errors.push("boot shell missing versioned rescue-runtime.js");
  }
}
if (manifest?.runtimePath && !bootHtml.includes(manifest.runtimePath)) {
  errors.push(`boot shell missing runtime path ${manifest.runtimePath}`);
}

const runtimeDir = resolveRuntimeDirFromRoot(root);
const runtimeHtml = fs.readFileSync(path.join(runtimeDir, "index.html"), "utf8");
if (!runtimeHtml.includes("?v=") && !runtimeHtml.includes(manifest?.buildId ?? "__none__")) {
  errors.push("runtime index.html missing cache-bust query on js/wasm/pck");
}

if (errors.length > 0) {
  console.error("Godot cache busting validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Godot cache busting OK");
console.log("  buildId:", manifest?.buildId);
console.log("  runtimePath:", manifest?.runtimePath);
