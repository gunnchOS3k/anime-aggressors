import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  readGodotBuildManifest,
  resolveRuntimeDirFromRoot,
  validateGodotPagesExportRoot,
} from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const distGodot = path.join(repoRoot, "apps/web/dist/godot");
const publicGodot = path.join(repoRoot, "apps/web/public/godot");
const root = fs.existsSync(distGodot) ? distGodot : publicGodot;

const errors = [];

const pages = validateGodotPagesExportRoot(root, { label: root });
errors.push(...pages.errors);

const manifest = readGodotBuildManifest(root);
if (!manifest) {
  errors.push("build-manifest.json missing");
} else {
  if (!manifest.buildId) errors.push("manifest missing buildId");
  if (!manifest.bootPath && !fs.existsSync(path.join(root, "index.html"))) {
    errors.push("manifest missing bootPath");
  }
  if (!manifest.runtimePath?.includes(manifest.buildId)) {
    errors.push("runtimePath is not versioned by buildId");
  }
}

const bootHtmlPath = path.join(root, "index.html");
if (!fs.existsSync(bootHtmlPath)) {
  errors.push("boot shell index.html missing");
} else {
  const bootHtml = fs.readFileSync(bootHtmlPath, "utf8");
  if (!bootHtml.includes("?v=")) errors.push("boot shell missing ?v= cache bust");
  if (manifest?.buildId && !bootHtml.includes(manifest.buildId)) {
    errors.push("boot shell missing buildId reference");
  }
  if (!bootHtml.includes("rescue-runtime.js")) {
    errors.push("boot shell missing rescue-runtime.js");
  }
}

if (!fs.existsSync(path.join(root, "rescue-runtime.js"))) {
  errors.push("rescue-runtime.js missing");
}

const runtimeDir = resolveRuntimeDirFromRoot(root);
const runtimeIndex = path.join(runtimeDir, "index.html");
if (!fs.existsSync(runtimeIndex)) {
  errors.push(`versioned runtime index missing at ${runtimeIndex}`);
} else {
  const runtimeHtml = fs.readFileSync(runtimeIndex, "utf8");
  if (!runtimeHtml.includes("?v=") && manifest?.buildId && !runtimeHtml.includes(manifest.buildId)) {
    errors.push("runtime index missing versioned asset paths");
  }
}

for (const ext of [".wasm", ".pck", ".js"]) {
  const matches = fs.readdirSync(runtimeDir).filter((f) => f.endsWith(ext));
  if (matches.length === 0) {
    errors.push(`runtime missing *${ext}`);
  }
}

const screenSrc = fs.readFileSync(
  path.join(repoRoot, "apps/web/src/screens/GodotRuntimeScreen.ts"),
  "utf8",
);
if (!screenSrc.includes("fetchGodotBuildManifest")) {
  errors.push("Godot route does not reference manifest");
}
if (!screenSrc.includes("Godot Build:")) {
  errors.push("Godot route missing build ID badge");
}

if (errors.length > 0) {
  console.error("Public Godot build verification failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Public Godot build verification OK");
console.log("  root:", root);
console.log("  buildId:", manifest?.buildId);
