#!/usr/bin/env node
/**
 * Digital RC validation gates (node side).
 * Godot headless suites are invoked separately when GODOT_BIN is available.
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
let failed = 0;
const fail = (m) => {
  console.error(`FAIL: ${m}`);
  failed += 1;
};
const ok = (m) => console.log(`OK: ${m}`);

const beta = spawnSync(process.execPath, ["scripts/validate-anime-beta-content.mjs"], {
  cwd: root,
  encoding: "utf8",
});
if (beta.status !== 0) {
  fail("beta content prerequisite failed");
  console.error(beta.stdout || beta.stderr);
} else ok("beta content prerequisite");

const pkg = spawnSync(process.execPath, ["scripts/package-anime-standalone.mjs"], {
  cwd: root,
  encoding: "utf8",
});
if (pkg.status !== 0) {
  fail(`standalone package: ${pkg.stderr || pkg.stdout}`);
} else ok("standalone package");

for (const rel of [
  "builds/digital-rc/CLEAN_INSTALL.md",
  "builds/digital-rc/package-manifest.json",
  "game-godot/tests/rc_validation_runner.gd",
  "game-godot/tests/smoke_anime_digital_rc.gd",
  "docs/ANIME_DIGITAL_RC_STATUS.md",
]) {
  if (!fs.existsSync(path.join(root, rel))) fail(`missing ${rel}`);
}
ok("rc artifacts present");

const pkgManifest = JSON.parse(
  fs.readFileSync(path.join(root, "builds/digital-rc/package-manifest.json"), "utf8"),
);
if (pkgManifest.public_deploy !== false) fail("must not claim public deploy");
if (!pkgManifest.clean_install_steps?.length) fail("clean install steps missing");
ok("package manifest honesty");

// Performance threshold document (evidence filled by Godot runner when available)
const perfPath = path.join(root, "playtest-evidence/digital_rc_performance.json");
if (!fs.existsSync(perfPath)) {
  fs.writeFileSync(
    perfPath,
    JSON.stringify(
      {
        budget_ms_per_frame: 8.0,
        note: "Filled/confirmed by Godot rc_validation_runner when GODOT_BIN present",
        status: "pending_godot_runner",
      },
      null,
      2,
    ) + "\n",
  );
}
ok("performance evidence scaffold");

if (failed) {
  console.error(`validate-anime-digital-rc: ${failed} failure(s)`);
  process.exit(1);
}
console.log("validate-anime-digital-rc: PASS (node gates)");
console.log("TOKEN_CANDIDATE: ANIME_DIGITAL_RC_READY (requires Godot rc_validation_runner evidence)");
