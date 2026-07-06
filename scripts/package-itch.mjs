#!/usr/bin/env node
/**
 * Packages the latest Godot web export for itch.io HTML upload.
 * Output: dist/anime-aggressors-itch-web.zip (index.html at ZIP root)
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import {
  readGodotBuildManifest,
  resolveRuntimeDirFromRoot,
  validateGodotRuntimeDir,
} from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotPublicRoot = path.join(repoRoot, "apps/web/public/godot");
const distDir = path.join(repoRoot, "dist");
const zipPath = path.join(distDir, "anime-aggressors-itch-web.zip");
const stagingDir = path.join(distDir, "itch-web-staging");

function rmrf(p) {
  fs.rmSync(p, { recursive: true, force: true });
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const ent of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, ent.name);
    const to = path.join(dest, ent.name);
    if (ent.isDirectory()) copyDir(from, to);
    else fs.copyFileSync(from, to);
  }
}

const manifest = readGodotBuildManifest(godotPublicRoot);
if (!manifest) {
  console.error("Missing apps/web/public/godot/build-manifest.json — run npm run godot:export:web first");
  process.exit(1);
}

const runtimeDir = resolveRuntimeDirFromRoot(godotPublicRoot);
const check = validateGodotRuntimeDir(runtimeDir, { label: runtimeDir });
if (!check.ok) {
  console.error("Godot runtime export is invalid:");
  for (const err of check.errors) console.error(`  - ${err}`);
  process.exit(1);
}

rmrf(stagingDir);
fs.mkdirSync(distDir, { recursive: true });
copyDir(runtimeDir, stagingDir);

if (!fs.existsSync(path.join(stagingDir, "index.html"))) {
  console.error("Staging missing index.html at root");
  process.exit(1);
}

rmrf(zipPath);
try {
  execSync(`cd "${stagingDir}" && zip -r "${zipPath}" .`, { stdio: "inherit" });
} catch (error) {
  console.error("zip failed:", error.message ?? error);
  process.exit(1);
}

rmrf(stagingDir);
console.log(`Wrote itch.io web package: ${zipPath}`);
console.log(`  buildId: ${manifest.buildId}`);
console.log(`  files: ${check.files.all.join(", ")}`);
