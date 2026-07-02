#!/usr/bin/env node
/**
 * Unity development environment detector (requirements §23).
 *
 * Reports honestly on: git state, Unity project files, Unity Hub,
 * installed Unity editors, and whether a batchmode import can be attempted.
 * Never claims Unity is ready without detecting it.
 */
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const unityProject = path.join(root, "unity/AnimeAggressorsUnity");

const report = { checks: [], blockers: [] };
const ok = (label, detail) => { report.checks.push({ label, status: "ok", detail }); console.log(`OK    ${label}: ${detail}`); };
const warn = (label, detail) => { report.checks.push({ label, status: "warn", detail }); console.log(`WARN  ${label}: ${detail}`); };
const block = (label, detail) => { report.blockers.push({ label, detail }); console.log(`BLOCK ${label}: ${detail}`); };

function sh(cmd, args, cwd = root) {
  try {
    return execFileSync(cmd, args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
  } catch {
    return null;
  }
}

// --- Git state ---
const branch = sh("git", ["rev-parse", "--abbrev-ref", "HEAD"]);
const commit = sh("git", ["log", "-1", "--format=%h %s"]);
if (branch && commit) ok("git", `branch ${branch} @ ${commit}`);
else warn("git", "not a git checkout or git unavailable");

// --- Unity project files ---
if (fs.existsSync(unityProject)) {
  ok("unity project", unityProject);
  const versionFile = path.join(unityProject, "ProjectSettings/ProjectVersion.txt");
  if (fs.existsSync(versionFile)) {
    const m = fs.readFileSync(versionFile, "utf8").match(/m_EditorVersion: (.+)/);
    ok("required editor version", m ? m[1].trim() : "unparseable");
  } else {
    block("ProjectVersion.txt", "missing — Unity Hub cannot resolve the editor version");
  }
} else {
  block("unity project", `${unityProject} missing`);
}

// --- Unity Hub ---
const platform = os.platform();
const hubPaths = {
  darwin: "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub",
  win32: "C:\\Program Files\\Unity Hub\\Unity Hub.exe",
  linux: "/usr/bin/unityhub",
};
const hubBin = hubPaths[platform];
const hubInstalled = hubBin && fs.existsSync(hubBin);
if (hubInstalled) {
  ok("unity hub", hubBin);
} else if (platform === "darwin" && sh("which", ["brew"])) {
  block("unity hub", "not installed — run: brew install --cask unity-hub");
} else {
  block("unity hub", "not installed — download from https://unity.com/download");
}

// --- Installed editors ---
const editorRootCandidates = {
  darwin: ["/Applications/Unity/Hub/Editor", "/Applications/Unity"],
  win32: ["C:\\Program Files\\Unity\\Hub\\Editor"],
  linux: [path.join(os.homedir(), "Unity/Hub/Editor")],
}[platform] ?? [];

function editorBinary(rootDir, version) {
  return platform === "darwin"
    ? path.join(rootDir, version, "Unity.app/Contents/MacOS/Unity")
    : path.join(rootDir, version, platform === "win32" ? "Editor/Unity.exe" : "Editor/Unity");
}

const editors = [];
for (const rootDir of editorRootCandidates) {
  if (!fs.existsSync(rootDir)) continue;
  for (const d of fs.readdirSync(rootDir).filter((d) => /^\d+\./.test(d))) {
    if (!editors.some((e) => e.version === d)) editors.push({ version: d, root: rootDir });
  }
}
let readyEditor = null;
if (editors.length > 0) {
  ok("unity editors", editors.map((e) => e.version).join(", "));
  for (const e of editors) {
    const bin = editorBinary(e.root, e.version);
    if (fs.existsSync(bin)) { ok(`editor binary ${e.version}`, bin); readyEditor ??= { ...e, bin }; }
    else warn(`editor binary ${e.version}`, "folder exists but binary missing (install may be in progress)");
  }
  if (!readyEditor) block("unity editors", "editor folder(s) found but no usable binary yet");
} else {
  block("unity editors", "none installed — open Unity Hub and install 6000.0.23f1 (see docs/UNITY_LOCAL_RUNBOOK.md)");
}

// --- License ---
const licenseDirs = {
  darwin: "/Library/Application Support/Unity",
  win32: "C:\\ProgramData\\Unity",
  linux: path.join(os.homedir(), ".local/share/unity3d/Unity"),
};
const licenseDir = licenseDirs[platform];
const hasLicense = licenseDir && fs.existsSync(licenseDir) &&
  fs.readdirSync(licenseDir).some((f) => f.endsWith(".ulf") || f === "licenses");
if (hasLicense) ok("unity license", "license files present");
else block("unity license", "no license detected — sign in through Unity Hub once (human step; do not bypass licensing)");

// --- Batchmode readiness ---
if (readyEditor && hasLicense && fs.existsSync(unityProject)) {
  ok("batchmode", `possible — try: "${readyEditor.bin}" -batchmode -nographics -quit -projectPath "${unityProject}" -logFile -`);
} else {
  warn("batchmode", "not possible yet — resolve blockers above first");
}

console.log("");
if (report.blockers.length === 0) {
  console.log("detect-unity-setup: environment looks ready for a Play Mode proof attempt.");
} else {
  console.log(`detect-unity-setup: ${report.blockers.length} blocker(s) — human action needed before Play Mode proof.`);
  process.exitCode = 2;
}
