#!/usr/bin/env node
/**
 * Mode A integration baseline APK wrapper.
 * Allowed when human candidates are incomplete. Not a human-art quality review build.
 */
import fs from "node:fs";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const debugApk = path.join(repoRoot, "builds/android/anime-aggressors-debug.apk");
const namedApk = path.join(repoRoot, "builds/android/anime-aggressors-full-roster-integration-baseline.apk");
const packedModeA = path.join(repoRoot, "game-godot/content/review/mode_a_integration_baseline.json");
const eligibility = {
  FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE: false,
  Mode_B_eligible: false,
  Mode_A_purpose: "integration baseline — staging route, selection, gameplay, performance",
  label: "FULL_ROSTER_INTEGRATION_BASELINE",
};

function resolveJdk17Home() {
  if (process.env.JAVA_HOME) {
    return process.env.JAVA_HOME;
  }
  if (process.platform === "darwin" && fs.existsSync("/usr/libexec/java_home")) {
    try {
      return execFileSync("/usr/libexec/java_home", ["-v", "17"], { encoding: "utf8" }).trim();
    } catch {
      return "";
    }
  }
  return "";
}

function javaMajor(javaHome) {
  const probe = spawnSync(path.join(javaHome, "bin", "java"), ["-version"], {
    encoding: "utf8",
  });
  const text = `${probe.stderr ?? ""}\n${probe.stdout ?? ""}`;
  const match = text.match(/version "(\d+)/);
  return match ? Number(match[1]) : 0;
}

const javaHome = resolveJdk17Home();
if (!javaHome || !fs.existsSync(path.join(javaHome, "bin", "java")) || javaMajor(javaHome) !== 17) {
  console.error("Mode A export blocked: JDK 17 / JAVA_HOME is not set.");
  console.error("Set JAVA_HOME to a JDK 17 install, or on macOS: export JAVA_HOME=\"$(/usr/libexec/java_home -v 17)\"");
  console.error(JSON.stringify(eligibility, null, 2));
  process.exit(2);
}

if (!fs.existsSync(packedModeA)) {
  console.error("Mode A packed review marker missing:", packedModeA);
  process.exit(1);
}

const exported = spawnSync("npm", ["run", "godot:export:android"], {
  cwd: repoRoot,
  stdio: "inherit",
  env: {
    ...process.env,
    JAVA_HOME: javaHome,
    PATH: `${path.join(javaHome, "bin")}${path.delimiter}${process.env.PATH ?? ""}`,
    HUMAN_ART_STAGING: "1",
    HUMAN_ART_FULL_ROSTER_REVIEW: "1",
    MODE_A_INTEGRATION_BASELINE: "1",
    MODE_B_HUMAN_ART_QUALITY_REVIEW: "0",
  },
});
if (exported.status !== 0) {
  process.exit(exported.status ?? 1);
}
if (!fs.existsSync(debugApk)) {
  console.error("Debug APK missing after export:", debugApk);
  process.exit(1);
}
fs.copyFileSync(debugApk, namedApk);
if (fs.existsSync(`${debugApk}.sha256`)) {
  const digest = fs.readFileSync(`${debugApk}.sha256`, "utf8").replace(path.basename(debugApk), path.basename(namedApk));
  fs.writeFileSync(`${namedApk}.sha256`, digest);
}
console.log("Mode A baseline:", namedApk);
console.log(JSON.stringify(eligibility, null, 2));
