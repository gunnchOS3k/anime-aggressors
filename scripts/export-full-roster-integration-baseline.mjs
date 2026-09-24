#!/usr/bin/env node
/**
 * Mode A integration baseline APK wrapper.
 * Allowed when human candidates are incomplete. Not a human-art quality review build.
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const debugApk = path.join(repoRoot, "builds/android/anime-aggressors-debug.apk");
const namedApk = path.join(repoRoot, "builds/android/anime-aggressors-full-roster-integration-baseline.apk");
const eligibility = {
  FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE: false,
  Mode_B_eligible: false,
  Mode_A_purpose: "integration baseline — staging route, selection, gameplay, performance",
};

if (!process.env.JAVA_HOME) {
  console.error("Mode A export blocked: JDK 17 / JAVA_HOME is not set.");
  console.error(JSON.stringify(eligibility, null, 2));
  process.exit(2);
}

const exported = spawnSync("npm", ["run", "godot:export:android"], {
  cwd: repoRoot,
  stdio: "inherit",
  env: { ...process.env, HUMAN_ART_STAGING: "0", HUMAN_ART_FULL_ROSTER_REVIEW: "1" },
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
