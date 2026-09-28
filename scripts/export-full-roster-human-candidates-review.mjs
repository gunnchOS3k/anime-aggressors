#!/usr/bin/env node
/**
 * Mode B HUMAN_CANDIDATE review APK. Blocked unless roster validation is honestly complete.
 */
import fs from "node:fs";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const debugApk = path.join(repoRoot, "builds/android/anime-aggressors-debug.apk");
const namedApk = path.join(
  repoRoot,
  "builds/android/anime-aggressors-full-roster-human-candidates-review.apk",
);
const packedModeB = path.join(repoRoot, "game-godot/content/review/mode_b_human_candidates_review.json");
const validatorPath = path.join(repoRoot, "artifacts/art_pipeline/FULL_ROSTER_VALIDATOR.json");

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

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

const validator = fs.existsSync(validatorPath) ? readJson(validatorPath) : {};
const packed = fs.existsSync(packedModeB) ? readJson(packedModeB) : {};
const eligibility = {
  FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE: Boolean(validator.FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE),
  CANDIDATE_RIGHTS_READY: Boolean(validator.CANDIDATE_RIGHTS_READY || validator.HUMAN_CANDIDATE_RIGHTS_READY),
  HUMAN_APPROVED: false,
  MODE_B_HUMAN_ART_QUALITY_REVIEW: false,
  Mode_B_eligible: Boolean(
    validator.FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE && (validator.CANDIDATE_RIGHTS_READY || validator.HUMAN_CANDIDATE_RIGHTS_READY),
  ),
  label: "FULL_ROSTER_HUMAN_CANDIDATES_REVIEW",
};

if (!eligibility.Mode_B_eligible) {
  console.error("Mode B export blocked: roster is not honestly complete.");
  console.error(JSON.stringify({ eligibility, validatorCounts: validator.counts || null }, null, 2));
  process.exit(2);
}

const javaHome = resolveJdk17Home();
if (!javaHome || !fs.existsSync(path.join(javaHome, "bin", "java")) || javaMajor(javaHome) !== 17) {
  console.error("Mode B export blocked: JDK 17 / JAVA_HOME is not set.");
  process.exit(2);
}

if (!fs.existsSync(packedModeB) || packed.MODE_B_HUMAN_ART_QUALITY_REVIEW === true) {
  console.error("Mode B packed review marker missing or illegally claims quality review.");
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
    MODE_A_INTEGRATION_BASELINE: "0",
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
fs.mkdirSync(path.dirname(namedApk), { recursive: true });
fs.copyFileSync(debugApk, namedApk);
const digest = execFileSync("shasum", ["-a", "256", namedApk], { encoding: "utf8" });
fs.writeFileSync(`${namedApk}.sha256`, digest);
console.log("Mode B candidate review:", namedApk);
console.log(JSON.stringify(eligibility, null, 2));
