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
const reviewApkPath = path.join(
  repoRoot,
  "builds/android/anime-aggressors-elemental-specials-owner-review.apk",
);
const selectCriticalReviewApkPath = path.join(
  repoRoot,
  "builds/android/anime-aggressors-select-critical-launch-owner-review.apk",
);

function stampBuildIdentity() {
  execFileSync(
    "python3",
    [
      path.join(repoRoot, "tools/art_pipeline/build_identity/generate_build_identity.py"),
      "--repo-root",
      repoRoot,
      "--flavor",
      "owner-review-debug",
    ],
    { stdio: "inherit", cwd: repoRoot },
  );
  const stamped = JSON.parse(
    fs.readFileSync(path.join(godotDir, "data/runtime/build_identity.json"), "utf8"),
  );
  if (!stamped.git_sha || String(stamped.git_sha).toUpperCase() === "UNKNOWN") {
    console.error("Review APK refused: embedded SHA is UNKNOWN.");
    process.exit(1);
  }
  return stamped;
}

function assertApkEmbedsSha(apk, sha) {
  try {
    execFileSync(
      "python3",
      [
        "-c",
        "import sys, zipfile\nsha=sys.argv[1].encode()\nwith zipfile.ZipFile(sys.argv[2]) as z:\n    for name in z.namelist():\n        if sha in z.read(name):\n            sys.exit(0)\nsys.exit(1)\n",
        sha,
        apk,
      ],
      { cwd: repoRoot },
    );
  } catch {
    console.error("Review APK refused: packed APK does not embed", sha);
    process.exit(1);
  }
}

const godotBin = resolveGodotBin();
if (!godotBin) {
  console.error("Godot CLI not found. Set GODOT_BIN or install Godot 4.3+.");
  process.exit(1);
}

const stampedIdentity = stampBuildIdentity();
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
  const androidBuild = path.join(godotDir, "android", "build");
  const exportArgs = ["--headless", "--path", godotDir, "--export-debug", "Android", apkPath];
  if (!fs.existsSync(path.join(androidBuild, "build.gradle"))) {
    exportArgs.splice(3, 0, "--install-android-build-template");
    console.log("Android Gradle template missing; installing from export templates.");
  }
  execFileSync(godotBin, exportArgs, {
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

assertApkEmbedsSha(apkPath, stampedIdentity.git_sha);
const digest = crypto.createHash("sha256").update(fs.readFileSync(apkPath)).digest("hex");
fs.writeFileSync(`${apkPath}.sha256`, `${digest}  ${path.basename(apkPath)}\n`);
fs.copyFileSync(apkPath, reviewApkPath);
fs.writeFileSync(`${reviewApkPath}.sha256`, `${digest}  ${path.basename(reviewApkPath)}\n`);
fs.copyFileSync(apkPath, selectCriticalReviewApkPath);
fs.writeFileSync(
  `${selectCriticalReviewApkPath}.sha256`,
  `${digest}  ${path.basename(selectCriticalReviewApkPath)}\n`,
);
console.log("Exported Android debug APK:", apkPath);
console.log("Owner-review APK:", reviewApkPath);
console.log("Select/critical-launch review APK:", selectCriticalReviewApkPath);
console.log("Embedded SHA:", stampedIdentity.git_sha);
console.log("SHA-256:", digest);
