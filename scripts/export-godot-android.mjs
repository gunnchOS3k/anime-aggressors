#!/usr/bin/env node
/**
 * Exports Android debug APK from game-godot/ (requires Godot CLI + Android SDK).
 */
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import fs from "node:fs";
import { resolveGodotBin } from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotDir = path.join(repoRoot, "game-godot");
const apkPath = path.join(repoRoot, "builds/android/anime-aggressors-debug.apk");

const godotBin = resolveGodotBin();
if (!godotBin) {
  console.error("Godot CLI not found. Set GODOT_BIN or install Godot 4.3+.");
  process.exit(1);
}

fs.mkdirSync(path.dirname(apkPath), { recursive: true });

try {
  execSync(
    `"${godotBin}" --headless --path "${godotDir}" --export-debug "Android" "${apkPath}"`,
    { stdio: "inherit", cwd: repoRoot },
  );
} catch (error) {
  console.error("Android export failed:", error.message ?? error);
  console.error("See docs/playtest/ANDROID_APK_TESTING.md for SDK setup.");
  process.exit(1);
}

if (!fs.existsSync(apkPath)) {
  console.error("APK not written:", apkPath);
  process.exit(1);
}

console.log("Exported Android debug APK:", apkPath);
