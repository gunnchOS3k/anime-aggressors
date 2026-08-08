#!/usr/bin/env node
/**
 * Node-side Anime Beta Content Complete validation.
 * Rebuilds manifests + checks ADR/modes/stages/fighters.
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

const build = spawnSync(process.execPath, ["scripts/build-anime-beta-content-manifest.mjs"], {
  cwd: root,
  encoding: "utf8",
});
if (build.status !== 0) {
  fail(`manifest builder: ${build.stderr || build.stdout}`);
  process.exit(1);
}
ok("manifest builder");

for (const rel of [
  "content/production_manifest.json",
  "content/provenance.json",
  "content/missing_assets.json",
  "playtest-evidence/move_graph_uniqueness.json",
  "docs/decisions/ADR-GAME-AA-001-launch-fighters.md",
  "docs/decisions/ADR-GAME-AA-002-launch-stages.md",
  "docs/decisions/ADR-GAME-AA-003-launch-modes.md",
  "docs/decisions/ADR-GAME-AA-004-online-rc-bar.md",
  "game-godot/scripts/battle/stage_procedural_builder.gd",
  "game-godot/scripts/net/online_matchmaking_architecture.gd",
  "game-godot/scripts/net/tournament_rooms.gd",
  "game-godot/scenes/menus/TeamScene.tscn",
  "game-godot/scenes/menus/ChallengesScene.tscn",
  "game-godot/scenes/menus/OnlineHubScene.tscn",
  "game-godot/scenes/menus/TournamentScene.tscn",
]) {
  if (!fs.existsSync(path.join(root, rel))) fail(`missing ${rel}`);
}
ok("required beta files");

const manifest = JSON.parse(
  fs.readFileSync(path.join(root, "content/production_manifest.json"), "utf8"),
);
if (manifest.token_target !== "ANIME_BETA_CONTENT_COMPLETE_DIGITAL") fail("token_target");
if (manifest.honesty?.final_painted_art_complete !== false) fail("must not claim final art");
if (manifest.honesty?.alpha_tokens_not_repackaged !== true) fail("alpha not repackaged flag");
if ((manifest.fighters ?? []).length !== 7) fail("fighters != 7");
if ((manifest.modes ?? []).length < 13) fail("modes < 13");
ok("production_manifest honesty");

const competitive = [
  "skyline-arena",
  "neon-rooftops",
  "cascade-foundry",
  "void-pier",
  "ember-courtyard",
];
for (const id of competitive) {
  const s = JSON.parse(
    fs.readFileSync(path.join(root, `game-godot/data/stages/${id}.json`), "utf8"),
  );
  if (!String(s.productionStatus || "").startsWith("procedural_final")) {
    fail(`${id} still greybox (${s.productionStatus})`);
  }
  if (s.geometryStatus !== "PROCEDURAL_FINAL") fail(`${id} geometryStatus`);
  if (s.artStatus !== "PROCEDURAL_FINAL") fail(`${id} artStatus must be PROCEDURAL_FINAL`);
  if (s.audioBed?.status !== "PROCEDURAL_FINAL") fail(`${id} audioBed status`);
  if (!fs.existsSync(path.join(root, `game-godot/assets/stages/procedural/${id}.svg`))) {
    fail(`${id} missing procedural stage art`);
  }
  for (const k of ["cameraProfile", "lightingProfile", "performanceTier", "a11y", "audioBed"]) {
    if (!s[k]) fail(`${id} missing ${k}`);
  }
}
ok("launch stages procedural art+geometry");

const missing = JSON.parse(
  fs.readFileSync(path.join(root, "content/missing_assets.json"), "utf8"),
);
const blockers = (missing.items ?? []).filter((i) => i.blocks_token === true);
if (blockers.length !== 0) {
  fail(`token blockers remain: ${blockers.map((b) => b.id).join(",")}`);
}
ok(`missing_assets token-blockers=0 (items=${(missing.items ?? []).length})`);

if (manifest.honesty?.procedural_digital_art_complete !== true) fail("procedural art complete flag");
if (manifest.honesty?.procedural_digital_audio_complete !== true) fail("procedural audio complete flag");
if (manifest.honesty?.token_requires_zero_blocks_token !== true) fail("token integrity flag");

if (failed) {
  console.error(`validate-anime-beta-content: ${failed} failure(s)`);
  process.exit(1);
}
console.log("validate-anime-beta-content: PASS");
console.log("TOKEN_CANDIDATE: ANIME_BETA_CONTENT_COMPLETE_DIGITAL");
