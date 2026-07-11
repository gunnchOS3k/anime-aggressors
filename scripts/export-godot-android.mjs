#!/usr/bin/env node
/**
 * Exports Android debug APK from game-godot/ (requires Godot CLI + Android SDK).
 */
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import crypto from "node:crypto";
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

const androidSdk = process.env.ANDROID_SDK_ROOT
  ?? process.env.ANDROID_HOME
  ?? path.join(os.homedir(), "Library", "Android", "sdk");
if (!fs.existsSync(path.join(androidSdk, "platform-tools", "adb"))) {
  console.error("Android SDK not found. Set ANDROID_SDK_ROOT or ANDROID_HOME.");
  process.exit(1);
}

let javaHome = process.env.JAVA_HOME;
if (!javaHome && process.platform === "darwin") {
  try {
    javaHome = execFileSync("/usr/libexec/java_home", ["-v", "17"], { encoding: "utf8" }).trim();
  } catch {
    // The explicit error below is clearer than Java's downstream export failure.
  }
}
if (!javaHome || !fs.existsSync(path.join(javaHome, "bin", "java"))) {
  console.error("JDK 17 not found. Set JAVA_HOME to a JDK 17 installation.");
  process.exit(1);
}

const exportEnv = {
  ...process.env,
  ANDROID_HOME: androidSdk,
  ANDROID_SDK_ROOT: androidSdk,
  JAVA_HOME: javaHome,
  GODOT_DISABLE_CRASH_HANDLER: "1",
};

try {
  execFileSync(godotBin, ["--headless", "--path", godotDir, "--editor", "--quit-after", "1"], {
    stdio: "inherit",
    cwd: repoRoot,
    env: exportEnv,
  });
  execFileSync(godotBin, ["--headless", "--path", godotDir, "--export-debug", "Android", apkPath], {
    stdio: "inherit",
    cwd: repoRoot,
    env: exportEnv,
  });
} catch (error) {
  console.error("Android export failed:", error.message ?? error);
  console.error("See docs/playtest/ANDROID_APK_TESTING.md for SDK setup.");
  process.exit(1);
}

if (!fs.existsSync(apkPath)) {
  console.error("APK not written:", apkPath);
  process.exit(1);
}

const digest = crypto.createHash("sha256").update(fs.readFileSync(apkPath)).digest("hex");
fs.writeFileSync(`${apkPath}.sha256`, `${digest}  ${path.basename(apkPath)}\n`);
console.log("Exported Android debug APK:", apkPath);
console.log("SHA-256:", digest);
