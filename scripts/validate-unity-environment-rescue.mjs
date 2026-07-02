#!/usr/bin/env node
/**
 * Unity environment rescue validation — verifies the rescue tooling and docs
 * exist and that no doc overclaims a Play Mode pass.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

let exitCode = 0;
const fail = (m) => { console.error(`FAIL: ${m}`); exitCode = 1; };
const ok = (m) => console.log(`OK: ${m}`);

const REQUIRED_FILES = [
  "scripts/check-unity-filesystem.mjs",
  "scripts/check-unity-editor-integrity.mjs",
  "docs/UNITY_MAC_ENVIRONMENT_RESCUE.md",
  "docs/UNITY_LOCAL_RUNBOOK.md",
];
for (const f of REQUIRED_FILES) {
  if (fs.existsSync(path.join(root, f))) ok(f);
  else fail(`missing ${f}`);
}

const runbookPath = path.join(root, "docs/UNITY_LOCAL_RUNBOOK.md");
if (fs.existsSync(runbookPath)) {
  const runbook = fs.readFileSync(runbookPath, "utf8");
  if (/case-insensitive filesystem/i.test(runbook)) ok("runbook mentions case-insensitive filesystem");
  else fail("UNITY_LOCAL_RUNBOOK.md must mention case-insensitive filesystem");
  if (runbook.includes("UnityPackageManager")) ok("runbook mentions UnityPackageManager");
  else fail("UNITY_LOCAL_RUNBOOK.md must mention UnityPackageManager");
}

// No doc may claim the Play Mode proof passed.
const docsDir = path.join(root, "docs");
const overclaim = /(play\s*mode\s*(proof|test)?\s*(passed|complete)|combat\s*proof\s*passed)/i;
let overclaims = 0;
for (const f of fs.readdirSync(docsDir).filter((f) => f.endsWith(".md"))) {
  const text = fs.readFileSync(path.join(docsDir, f), "utf8");
  for (const line of text.split("\n")) {
    if (!overclaim.test(line)) continue;
    // Allow lines that explicitly negate or gate the claim.
    if (/not|no |only when|requires|until|before|gate|checklist|claim/i.test(line)) continue;
    fail(`docs/${f} appears to claim Play Mode passed: "${line.trim()}"`);
    overclaims++;
  }
}
if (overclaims === 0) ok("no docs claim Play Mode passed");

if (exitCode) process.exit(exitCode);
console.log("validate-unity-environment-rescue: all checks passed");
