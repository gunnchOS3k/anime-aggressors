#!/usr/bin/env node
/**
 * Recursive project verification — npm gates + Godot CLI detection + smoke tests.
 * Writes tmp/aa-verify-project-report.json and docs/PR48_VERIFICATION_REPORT.md
 */
import fs from "node:fs";
import path from "node:path";
import { execSync, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(root, "game-godot");
const tmpDir = path.join(root, "tmp");
const reportJsonPath = path.join(tmpDir, "aa-verify-project-report.json");
const reportMdPath = path.join(root, "docs/PR48_VERIFICATION_REPORT.md");

const report = {
  generated_at: new Date().toISOString(),
  commit_sha: "",
  npm: {},
  godot: {
    binary: null,
    binary_detected: false,
    version: null,
    import_headless: null,
    smoke_runner: null,
    cli_missing_message: null,
  },
  manual_signoff_required: true,
  remaining_blockers: [],
  verification_tiers: {
    automated_npm: "unknown",
    godot_cli: "unknown",
    godot_editor_playtest: "manual_signoff_required",
    proxy_functional: "partial",
    final_art: "blocked",
  },
};

function gitSha() {
  try {
    return execSync("git rev-parse HEAD", { cwd: root, encoding: "utf8" }).trim();
  } catch {
    return "unknown";
  }
}

function runStep(name, cmd, opts = {}) {
  const started = Date.now();
  try {
    const out = execSync(cmd, {
      cwd: root,
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
      ...opts,
    });
    report.npm[name] = { status: "pass", duration_ms: Date.now() - started, output_tail: out.slice(-500) };
    console.log(`OK: ${name}`);
    return true;
  } catch (err) {
    const stderr = err.stderr?.toString() ?? "";
    const stdout = err.stdout?.toString() ?? "";
    report.npm[name] = {
      status: "fail",
      duration_ms: Date.now() - started,
      output_tail: (stdout + stderr).slice(-1200),
      exit_code: err.status ?? 1,
    };
    console.error(`FAIL: ${name}`);
    console.error((stdout + stderr).slice(-800));
    return false;
  }
}

function detectGodotBin() {
  const candidates = [
    process.env.GODOT_BIN,
    "godot4",
    "godot",
    "/Applications/Godot.app/Contents/MacOS/Godot",
    "/Applications/Godot_v4.2.app/Contents/MacOS/Godot",
  ].filter(Boolean);

  for (const bin of candidates) {
    if (bin.includes("/") && !fs.existsSync(bin)) continue;
    const r = spawnSync(bin, ["--version"], { encoding: "utf8", timeout: 15000 });
    if (r.status === 0) {
      return { bin, version: (r.stdout || r.stderr || "").trim() };
    }
  }
  return null;
}

function runGodot(bin, args) {
  const r = spawnSync(bin, args, {
    cwd: root,
    encoding: "utf8",
    timeout: 120000,
    env: { ...process.env, GODOT_DISABLE_CRASH_HANDLER: "1" },
  });
  return {
    status: r.status ?? 1,
    stdout: r.stdout ?? "",
    stderr: r.stderr ?? "",
  };
}

report.commit_sha = gitSha();

console.log("aa-verify-project: starting");
console.log("commit:", report.commit_sha);

const npmOk =
  runStep("validate_full_scope", "npm run validate:full-scope-production") &&
  runStep("typecheck", "npm run typecheck") &&
  runStep("test_workspaces", "npm run test:workspaces") &&
  runStep("build", "npm run build");

report.verification_tiers.automated_npm = npmOk ? "verified" : "failed";

const detected = detectGodotBin();
if (detected) {
  report.godot.binary_detected = true;
  report.godot.binary = detected.bin;
  report.godot.version = detected.version;
  console.log("Godot CLI:", detected.bin, detected.version);

  const importRun = runGodot(detected.bin, ["--path", godotRoot, "--headless", "--quit-after", "1"]);
  report.godot.import_headless = {
    status: importRun.status === 0 ? "pass" : "fail",
    exit_code: importRun.status,
    output_tail: (importRun.stdout + importRun.stderr).slice(-800),
  };
  console.log(importRun.status === 0 ? "OK: godot headless import" : "FAIL: godot headless import");

  const smokeRun = runGodot(detected.bin, ["--path", godotRoot, "--headless", "-s", "res://tests/smoke_runner.gd"]);
  report.godot.smoke_runner = {
    status: smokeRun.status === 0 ? "pass" : "fail",
    exit_code: smokeRun.status,
    output_tail: (smokeRun.stdout + smokeRun.stderr).slice(-1200),
  };
  console.log(smokeRun.status === 0 ? "OK: godot smoke_runner" : "FAIL: godot smoke_runner");

  const cliOk = report.godot.import_headless.status === "pass" && report.godot.smoke_runner.status === "pass";
  report.verification_tiers.godot_cli = cliOk ? "verified" : "failed";
} else {
  report.godot.binary_detected = false;
  report.godot.cli_missing_message = "GODOT_CLI_MISSING — manual editor signoff required";
  report.verification_tiers.godot_cli = "manual_blocker_cli_missing";
  console.warn("GODOT_CLI_MISSING — manual editor signoff required");
}

report.manual_signoff_required = true;
report.remaining_blockers = [
  "P1: Signed Godot editor playtest (docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md)",
  "P1: Final authored .glb fighter art",
  "P1: Final authored animation clips",
  "P2: Final SFX/VFX polish",
  "P2: CPU balance/tuning",
  "P2: Export hardening",
  "P3: Full ledge grab, rollback/netplay",
];

const signedDir = path.join(root, "docs/manual-playtests");
const hasSigned = fs.existsSync(signedDir) &&
  fs.readdirSync(signedDir).some((f) => f.endsWith(".md") && !f.startsWith("."));

if (hasSigned) {
  report.verification_tiers.godot_editor_playtest = "signed_file_present";
  report.manual_signoff_required = false;
} else {
  report.verification_tiers.godot_editor_playtest = "manual_signoff_required";
}

fs.mkdirSync(tmpDir, { recursive: true });
fs.writeFileSync(reportJsonPath, JSON.stringify(report, null, 2));

const md = `# PR #48 Verification Report

**Generated:** ${report.generated_at}  
**Commit:** \`${report.commit_sha}\`

## Verification tiers

| Tier | Status |
|------|--------|
| Automated npm | ${report.verification_tiers.automated_npm} |
| Godot CLI | ${report.verification_tiers.godot_cli} |
| Godot editor playtest | ${report.verification_tiers.godot_editor_playtest} |
| Proxy functional | ${report.verification_tiers.proxy_functional} |
| Final art | ${report.verification_tiers.final_art} |

## NPM gates

| Step | Status |
|------|--------|
| validate:full-scope-production | ${report.npm.validate_full_scope?.status ?? "not run"} |
| typecheck | ${report.npm.typecheck?.status ?? "not run"} |
| test:workspaces | ${report.npm.test_workspaces?.status ?? "not run"} |
| build | ${report.npm.build?.status ?? "not run"} |

## Godot CLI

| Field | Value |
|-------|-------|
| Detected | ${report.godot.binary_detected} |
| Binary | ${report.godot.binary ?? "—"} |
| Version | ${report.godot.version ?? "—"} |
| Headless import | ${report.godot.import_headless?.status ?? "skipped"} |
| Smoke runner | ${report.godot.smoke_runner?.status ?? "skipped"} |

${report.godot.cli_missing_message ? `\n> **${report.godot.cli_missing_message}**\n` : ""}

## Manual signoff required

**${report.manual_signoff_required ? "Yes" : "No"}** — complete \`docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md\` and save a filled copy under \`docs/manual-playtests/\`.

## Remaining blockers

${report.remaining_blockers.map((b) => `- ${b}`).join("\n")}

## JSON report

\`tmp/aa-verify-project-report.json\`

## No full-completion claim

Ship-ready status requires signed editor playtest evidence and final authored assets.
`;

fs.writeFileSync(reportMdPath, md);
console.log("Wrote", reportJsonPath);
console.log("Wrote", reportMdPath);

const allAutomatedPass = npmOk;
const exitCode = allAutomatedPass ? 0 : 1;
if (!allAutomatedPass) {
  console.error("aa-verify-project: npm gates failed");
  process.exit(exitCode);
}
console.log("aa-verify-project: complete");
process.exit(exitCode);
